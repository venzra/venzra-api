import { Response, NextFunction } from 'express';
import { decode } from 'jwt-simple';

import { VenzraRequest } from '../models';
import { CustomerModel } from '../schemas';

import { config } from '../config';

export class VenzraCustomer {
    static load(req: VenzraRequest, res: Response, next: NextFunction) {
        Promise.resolve(req.cookies.jwt)
            .then((jwt) => {
                if (!jwt) {
                    throw new Error('No authentication token found');
                }

                return decode(jwt, config.secret, false, 'HS512');
            })
            .then((token) => {
                if (req.ip !== token.ip) {
                    throw new Error('Change of IP address detected');
                }

                return token;
            })
            .then((token) =>
                CustomerModel
                    .findOne({ _id: token._id, 'access.key': token.key, subscription: req.venzra.subscription._id })
                    .populate('subscription')
                    .then((customer) => {
                        if (!customer) {
                            res.clearCookie('jwt');
                            throw new Error(`Invalid customer token for ${token._id}`);
                        }

                        // TODO: Check token expiry against customer
                        req.venzra = req.venzra || {};
                        Object.assign(req.venzra, { customer });
                    }))
            .catch(() => null)
            .then(() => next());
    }
}

export default VenzraCustomer.load;
