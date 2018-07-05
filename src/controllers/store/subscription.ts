import * as parser from 'body-parser';

import { Request, Response, NextFunction, Router } from 'express';
import { StoreController } from './store';

export class SubscriptionController extends StoreController {

    public router: Router;

    constructor() {
        super();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.loadSubscription.bind(this), this.retrieve.bind(this));
    }

    retrieve(req: Request, res: Response, next: NextFunction) {
        const { _id, features, domainName, storeName, strapline, icon, logo, gateway, contact, created } = this.subscription;
        return res.status(200).send({ _id, features, domainName, storeName, strapline, icon, logo, contact, gateway: (gateway ? gateway.publicKey : ''), created });
    }

}

export default new SubscriptionController().router;
