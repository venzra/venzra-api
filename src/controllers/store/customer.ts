import * as parser from 'body-parser';
import { createHash, pbkdf2Sync } from 'crypto';
import { v4 } from 'uuid';
import * as zxcvbn from 'zxcvbn';

import { Response, Router, NextFunction } from 'express';
import { CustomerModel } from '../../schemas';

import { Address, Customer, NotFoundError, ValidationError, VenzraRequest } from '../../models';
import { IdentityService } from '../../services';

export class CustomerController {

    public router: Router;

    private identityService: IdentityService;

    constructor() {
        this.router = Router();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateCustomer.bind(this), this.getCustomer.bind(this));
        this.router.post('/password', this.identityService.validateCustomer.bind(this), this.changePassword.bind(this));
        this.router.post('/addresses', this.identityService.validateCustomer.bind(this), this.createAddress.bind(this), this.getCustomer.bind(this));
        this.router.delete('/addresses/:addressId', this.identityService.validateCustomer.bind(this), this.removeAddress.bind(this));
    }

    public async getCustomer(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.venzra.customer.id;
        const subscription = req.venzra.subscription._id;

        const customer = await CustomerModel
            .findOne({ _id, subscription })
            .select('identity addresses primaryAddress status');

        if (!customer) {
            return next(new NotFoundError());
        }
        return res.status(200).send(customer);
    }

    public async changePassword(req: VenzraRequest, res: Response, next: NextFunction) {
        const errors = [];

        if (!req.body.password) {
            errors.push({ path: 'password', kind: 'required' });
        } else {
            const { score } = zxcvbn(req.body.password);
            if (score < 3) {
                errors.push({ path: 'password', kind: 'strength' });
            }
        }

        if (req.body.password !== req.body.confirmation) {
            errors.push({ path: 'confirmation', kind: 'invalid' });
        }

        if (errors.length) {
            return next(new ValidationError(errors));
        }

        const passwordCheck = pbkdf2Sync(req.body.current, req.venzra.customer.password.salt, 10000, 256, 'sha512').toString('base64');

        if (passwordCheck === req.venzra.customer.password.secure) {
            const salt = createHash('sha1').update(v4()).digest('hex');

            const password = {
                salt: salt,
                secure: pbkdf2Sync(req.body.password, salt, 10000, 256, 'sha512').toString('base64'),
                created: new Date(),
            };

            req.venzra.customer.set('password', password);

            try {
                await req.venzra.customer.save();
                res.status(202).send();
            } catch (error) {
                next(error);
            }
        } else {
            next(new ValidationError([{ path: 'current', kind: 'invalid' }]));
        }
    }

    public async createAddress(req: VenzraRequest, res: Response, next: NextFunction) {
        const address = {
            addressee: req.body.addressee,
            street: req.body.street,
            building: req.body.building,
            city: req.body.city,
            county: req.body.county,
            country: req.body.country,
            postalCode: req.body.postalCode,
        };

        req.venzra.customer.addresses.push(<Address>address);

        let customer: Customer;
        try {
            customer = await req.venzra.customer.save();
        } catch (error) {
            return next(error);
        }

        if (customer.addresses.length === 1) {
            customer.primaryAddress = customer.addresses[0]._id;
        } else if (!customer.primaryAddress || req.body.makeDefault) {
            customer.primaryAddress = customer.addresses[customer.addresses.length - 1]._id;
        }

        try {
            await customer.save();
            next();
        } catch (error) {
            next(error);
        }
    }

    public async removeAddress(req: VenzraRequest, res: Response, next: NextFunction) {
        const addresses = req.venzra.customer.addresses.filter((address) => address.get('_id', 'string') !== req.params.addressId);
        const changes: any = { $pull: { addresses: { _id: req.params.addressId } } };

        if (addresses.length === 0) {
            changes.$unset = { primaryAddress: 1 };
        } else if (!req.venzra.customer.primaryAddress || req.venzra.customer.get('primaryAddress', 'string') === req.params.addressId) {
            changes.$set = { primaryAddress: addresses[0]._id };
        }

        try {
            await req.venzra.customer.update(changes).exec();
            res.status(202).send();
        } catch (error) {
            next(error);
        }
    }

}

export default new CustomerController().router;
