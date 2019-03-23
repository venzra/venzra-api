import * as parser from 'body-parser';
import { createHash, pbkdf2Sync } from 'crypto';
import { encode } from 'jwt-simple';
import { v4 } from 'uuid';

import { Response, NextFunction, Router } from 'express';

import { AuthenticationError, ValidationError, VenzraRequest } from '../../models';
import { CustomerModel } from '../../schemas';

import { config } from '../../config';

export class IdentityController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/login', this.authorise.bind(this), this.tokenise.bind(this));
        this.router.post('/logout', this.logout.bind(this));
    }

    public async authorise(req: VenzraRequest, res: Response, next: NextFunction) {
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

        let customer = await CustomerModel.findOne({ subscription, identity });

        if (!customer) {
            const salt = createHash('sha1').update(v4()).digest('hex');

            const password = req.body.password ? {
                salt: salt,
                secure: pbkdf2Sync(req.body.password, salt, 10000, 256, 'sha512').toString('base64'),
                created: new Date(),
            } : null;

            customer = new CustomerModel({ subscription, identity, password });
            try {
                await customer.save();
            } catch (error) {
                return next(error);
            }
        }

        switch (customer.status) {
            case 'ACTIVE':
            case 'RECOVERY':
                break;
            case 'LOCKED':
                // TODO: Allow for timeout on customer lock for new attempts
                return next(new AuthenticationError(`Account "${customer.identity}" locked`));
            default:
                return next(new AuthenticationError(`Account "${customer.identity}" state is ${customer.status}`));
        }

        const password = pbkdf2Sync(req.body.password, customer.password.salt, 10000, 256, 'sha512').toString('base64');

        if (customer.password.secure !== password) {
            const changes = {
                $unset: { access: 1 },
                $set: {
                    'lock.ip': req.ip,
                    'lock.attempted': new Date(),
                },
                $inc: { 'lock.failures': 1 },
                status: (customer.lock.failures >= 4 ? 'LOCKED' : customer.status),
            };

            try {
                await customer.update(changes).exec();
            } catch (error) {
                return next(error);
            }
            return next(new AuthenticationError(`Password for "${customer.identity}" incorrect`));
        }

        const token = {
            key: createHash('sha256').update(v4()).digest('hex').toString(),
            ip: req.ip,
            created: new Date(),
        };

        customer.set({
            access: token,
            lock: { failures: 0 },
            status: 'ACTIVE',
        });

        try {
            await customer.save();
            Object.assign(req.venzra, { customer });
            return next();
        } catch (error) {
            return next(error);
        }
    }

    public async tokenise(req: VenzraRequest, res: Response, next: NextFunction) {
        const customer = {
            _id: req.venzra.customer.id,
            key: req.venzra.customer.access.key,
            ip: req.venzra.customer.access.ip,
        };
        const encoded = encode(customer, config.secret, 'HS512');

        res.cookie('jwt', encoded, { httpOnly: true, secure: config.secure });
        res.status(202).send();
    }

    public async logout(req: VenzraRequest, res: Response, next: NextFunction) {
        if (req.venzra.customer) {
            await req.venzra.customer.update({ $unset: { access: 1 } });
            res.clearCookie('jwt');
            res.status(202).send();
        } else {
            res.status(202).send();
        }
    }

}

export default new IdentityController().router;
