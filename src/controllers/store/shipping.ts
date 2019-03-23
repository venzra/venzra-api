import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Cart, VenzraRequest } from '../../models';
import { CartModel, ShippingModel } from '../../schemas';

export class ShippingController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findAll.bind(this));
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const cartSearch: any = { _id: req.cookies.vid, subscription: req.venzra.subscription._id };

        const cart: Cart = await CartModel
            .findOne(cartSearch)
            .populate({ path: 'items.product' })
            .lean();

        const cartValue = cart.items.reduce((value, item) => value + (item.product.currentPrice * item.quantity), 0);

        const searchParams: any = {
            subscription: req.venzra.subscription._id,
            $and: [
                {
                    $or: [
                        { cartMinimum: { $eq: 0 } },
                        { cartMinimum: { $lte: cartValue } },
                    ],
                },
                {
                    $or: [
                        { cartMaximum: { $eq: 0 } },
                        { cartMaximum: { $gte: cartValue } },
                    ],
                },
            ],
        };
        const order = { currentPrice: 1, shipmentTime: 1 };

        const total = await ShippingModel.countDocuments(searchParams).exec();

        const list = await ShippingModel
            .aggregate([
                { $match: searchParams },
                { $sort: order },
                { $project: { displayName: 1, cartMinimum: 1, cartMaximum: 1, currentPrice: 1 } },
            ]);

        res.status(200).send({ list, total });
    }

}

export default new ShippingController().router;
