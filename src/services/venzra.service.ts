import { Response, NextFunction } from 'express';

import { CartModel } from '../schemas';
import { VenzraRequest } from '../models';

export class VenzraService {

    session(req: VenzraRequest, res: Response, next: NextFunction) {
        Promise.resolve(req.venzra.subscription._id)
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
