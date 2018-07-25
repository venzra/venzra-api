import * as parser from 'body-parser';
import { createHash, pbkdf2Sync } from 'crypto';
import { encode } from 'jwt-simple';
import { v4 } from 'uuid';

import { Response, NextFunction, Router } from 'express';

import { AuthenticationError, ValidationError, VenzraRequest } from '../../models';
import { CustomerModel } from '../../schemas';

import { config } from '../../config';

export class IdentityController  {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/login', this.authorise.bind(this), this.tokenise.bind(this));
        this.router.post('/logout', this.logout.bind(this));
    }

    authorise(req: VenzraRequest, res: Response, next: NextFunction) {
        const errors = [];

        if (!req.body.identity) {
            errors.push({ path: 'identity', kind: 'required' });
        }

        if (!req.body.password) {
            errors.push({ path: 'password', kind: 'required' });
        }

        if (errors.length) {
            return next(new ValidationError(errors));
        }

        const subscription = req.venzra.subscription._id;
        const identity = (req.body.identity).toLowerCase();

        CustomerModel.findOne({ subscription, identity })
            .then((customer) => {
                if (!customer) {
                    const salt = createHash('sha1').update(v4()).digest('hex');

                    const password = req.body.password ? {
                        salt: salt,
                        secure: pbkdf2Sync(req.body.password, salt, 10000, 256, 'sha512').toString('base64'),
                        created: new Date()
                    } : null;

                    customer = new CustomerModel({ subscription, identity, password });
                    return customer.save();
                }
                return customer;
            })
            .then((customer) => {

                switch (customer.status) {
                    case 'ACTIVE':
                    case 'RECOVERY':
                        break;
                    case 'LOCKED':
                        // TODO: Allow for timeout on customer lock for new attempts
                        throw new AuthenticationError(`Account "${customer.identity}" locked`);
                    default:
                        throw new AuthenticationError(`Account "${customer.identity}" state is ${customer.status}`);
                }

                const password = pbkdf2Sync(req.body.password, customer.password.salt, 10000, 256, 'sha512').toString('base64');

                if (customer.password.secure === password) {
                    const token = {
                        key: createHash('sha256').update(v4()).digest('hex').toString(),
                        ip: req.ip,
                        created: new Date()
                    };

                    customer.set({
                            access: token,
                            lock: { failures: 0 },
                            status: 'ACTIVE'
                        });

                    return customer
                        .save()
                        .then((customer) => Object.assign(req.venzra, { customer }));
                } else {
                    const changes = {
                        $unset: { access: 1 },
                        $set: {
                            'lock.ip': req.ip,
                            'lock.attempted': new Date()
                        },
                        $inc: { 'lock.failures': 1 },
                        status: (customer.lock.failures >= 4 ? 'LOCKED' : customer.status)
                    };

                    return customer
                        .update(changes)
                        .exec()
                        .then(() => {
                            throw new AuthenticationError(`Password for "${customer.identity}" incorrect`);
                        });
                }
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    tokenise(req: VenzraRequest, res: Response, next: NextFunction) {
        const customer = {
            _id: req.venzra.customer.id,
            key: req.venzra.customer.access.key,
            ip: req.venzra.customer.access.ip
        };
        const encoded = encode(customer, config.secret, 'HS512');

        res.cookie('jwt', encoded, { httpOnly: true, secure: config.secure });
        res.status(202).send();
    }

    logout(req: VenzraRequest, res: Response, next: NextFunction) {
        if (req.venzra.customer) {
            req.venzra.customer
                .update({ $unset: { access: 1 } })
                .then(() => {
                    res.clearCookie('jwt');
                    res.status(202).send();
                });
        } else {
            res.status(202).send();
        }
    }

}

export default new IdentityController().router;
