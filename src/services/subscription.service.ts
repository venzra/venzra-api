import { Response, NextFunction } from 'express';

import { SubscriptionModel } from '../schemas';
import { NotFoundError, Subscription, VenzraRequest } from '../models';

export class VenzraSubscription {

    static load(req: VenzraRequest, res: Response, next: NextFunction): void {
        let domainName: string = '';

        if (req.headers && req.headers.origin) {
            const origin = <string>req.headers.origin;
            domainName = origin.replace(/https?:\/\//, '');
        } else if (req.headers && req.headers.referer) {
            const referer = <string>req.headers.referer;
            domainName = referer.replace(/https?:\/\//, '');
        }

        if (domainName.indexOf('/') > 0) {
            domainName = domainName.substr(0, domainName.indexOf('/'));
        }

        if (domainName.indexOf(':') > 0) {
            domainName = domainName.substr(0, domainName.indexOf(':'));
        }

        const additionalDomains = domainName;

        domainName = domainName.split('.').shift() || '';

        SubscriptionModel
            .findOne({ $or: [{ domainName }, { additionalDomains }] })
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
