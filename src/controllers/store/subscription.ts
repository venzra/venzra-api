import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Subscription, VenzraRequest } from '../../models';
import { config } from '../../config';

export class SubscriptionController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.retrieve.bind(this));
    }

    retrieve(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription: any = req.venzra.subscription;

        let { _id, features, domainName, storeName, strapline, icon, logo, gateway, contact, created } = subscription;
        return res.status(200).send({ _id, features, domainName, storeName, strapline, icon, logo, contact, gateway: (gateway ? gateway.publicKey : ''), created });
    }

}

export default new SubscriptionController().router;
