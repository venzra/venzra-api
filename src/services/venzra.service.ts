import { Request, Response, NextFunction } from 'express';

import { CartModel, SubscriptionModel } from '../schemas';
import { NotFoundError } from '../models';

export class VenzraService {

    session(req: Request, res: Response, next: NextFunction) {
        const domainName = req.subdomains.pop();
        SubscriptionModel
            .findOne({ domainName })
            .then((subscription) => {
                if (!subscription) {
                    throw new NotFoundError();
                }
                return subscription._id;
            })
            .then((subscription) => {
                const _id = req.cookies.vid;
                return CartModel.findOne({ _id, subscription })
                    .then((cart) => {
                        if (!cart) {
                            const ip = req.ip;
                            return CartModel.create({ subscription, ip });
                        }
                        return cart;
                    });
            })
            .then((cart) => {
                req.cookies.vid = cart.id;
                res.cookie('vid', cart.id);
            })
            .then(() => next())
            .catch((error) => next(error));
    }

}
export default new VenzraService().session
