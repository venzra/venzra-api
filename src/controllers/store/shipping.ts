import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { VenzraRequest } from '../../models';
import { ShippingModel } from '../../schemas';

export class ShippingController {

    public router: Router;

    constructor() {
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findAll.bind(this));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.subscription._id };
        const order = { currentPrice: 1, shipmentTime: 1 };

        ShippingModel
            .count(searchParams).exec()
            .then((total) =>
                ShippingModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $project: { displayName: 1, cartMinimum: 1, cartMaximum: 1, currentPrice: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((shippingError) => next(shippingError));
    }

}

export default new ShippingController().router;
