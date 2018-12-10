import { Response, NextFunction } from 'express';

import { decode } from 'jwt-simple';

import { AccessDeniedError, Account, VenzraRequest } from '../models';
import { AccountModel, SubscriptionModel } from '../schemas';

import { config } from '../config';

export class IdentityService {

    validateCustomer(req: VenzraRequest, res: Response, next: NextFunction) {
        if (req.venzra.customer && req.venzra.customer._id) {
            next();
        } else {
            next(new AccessDeniedError());
        }
    }

    validateAdmin(req: VenzraRequest, res: Response, next: NextFunction) {
        Promise.resolve(req.cookies.jwt)
            .then((jwt) => {
                if (!jwt) {
                    throw new AccessDeniedError('No authentication token found');
                }

                return decode(jwt, config.secret, false, 'HS512');
            })
            .then((token) =>
                AccountModel
                    .findOne({ _id: token._id, 'access.key': token.key })
                    .populate('subscription')
                    .then((account: Account) => {
                        if (!account) {
                            throw new AccessDeniedError(`Invalid account token for ${token._id}`);
                        }

                        // TODO: Check token expiry against account
                        req.venzra.account = account;
                        return next();
                    }))
            .catch((err) => next(err));
    }

    getAccount(req: VenzraRequest, res: Response, next: NextFunction) {
        AccountModel
            .findById(req.venzra.account.id)
            .select('identity subscription status')
            .then((account) => res.status(200).send(account));
    }

    getSubscription(req: VenzraRequest, res: Response) {
        SubscriptionModel
            .findById(req.venzra.account.subscription)
            .select('storeName domainName additionalDomains strapline icon logo theme payment gateway.account gateway.modified transactions addons contact status')
            .populate({
                path: 'icon',
                select: '_id name usage path'
            })
            .populate({
                path: 'logo',
                select: '_id name usage path'
            })
            .sort({ addons: 1 })
            .then((subscription) => res.status(200).send(subscription));
    }

}
