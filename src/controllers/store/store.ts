import { NextFunction, Request, Response } from 'express';

import { Subscription } from '../../models';
import { SubscriptionModel } from '../../schemas';

export class StoreController {

    protected subscription: Subscription;

    loadSubscription(req: Request, res: Response, next: NextFunction) {
        const domainName = req.subdomains.pop();

        SubscriptionModel
            .findOne({ domainName })
            .then((subscription: Subscription) => {
                subscription.features = subscription.addons.map((addon) => addon.name);
                this.subscription = subscription;
                next();
            })
            .catch((error) => next(error));
    }

}
