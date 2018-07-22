import { Response, NextFunction } from 'express';

import { SubscriptionModel } from '../schemas';
import { NotFoundError, Subscription, VenzraRequest } from '../models';

export class VenzraSubscription {

    static load(req: VenzraRequest, res: Response, next: NextFunction): void {
        const domainName = req.subdomains.pop();

        SubscriptionModel
            .findOne({ domainName })
            .then((subscription: Subscription) => {
                if(!subscription) {
                    throw new NotFoundError();
                }

                req.venzra = req.venzra || {};

                subscription.features = subscription.addons.map((addon) => addon.name);
                Object.assign(req.venzra, { subscription });

                next();
            })
            .catch((error) => next(error));
    }

}

export default VenzraSubscription.load;
