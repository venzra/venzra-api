import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { CartItem, NotFoundError, PatchRequest, Product, VenzraRequest } from '../../models';
import { CartModel, ProductModel } from '../../schemas';

import { config } from '../../config';

export class CartController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findOne.bind(this));
        this.router.patch('/', this.updateBasket.bind(this), this.findOne.bind(this));
    }

    public async updateBasket(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.cookies.vid;
        const subscription = req.venzra.subscription._id;

        const cart = await CartModel.findOne({ _id, subscription });

        if (!cart) {
            return next(new NotFoundError());
        }

        if (!(req.body instanceof Array)) {
            return next();
        }

        const update = (<Array<PatchRequest>>req.body).reduce(async (promise, operation) => {
            await promise;

            switch (operation.op) {
                case 'add':
                    switch (operation.path) {
                        case 'product':
                            const product = await ProductModel
                                .findOne({ _id: operation.value, subscription, status: 'ACTIVE' })
                                .exec();

                            if (!product) {
                                return;
                            }

                            const item = cart.items.find((entry) => entry.product.toString() === product._id.toString());

                            if (item) {
                                item.quantity++;
                            } else {
                                cart.items.push({ product: product._id, quantity: 1 });
                            }

                            cart.set('shipping', undefined);
                    }
                    break;
                case 'remove':
                    switch (operation.path) {
                        case 'product':
                            const item = cart.items.find((entry) => entry.product.toString() === operation.value);

                            if (!item) {
                                return;
                            }

                            item.quantity--;

                            if (item.quantity <= 0) {
                                cart.items = cart.items.filter((entry) => entry.product.toString() !== operation.value);
                            }

                            cart.set('shipping', undefined);
                    }
            }
        }, Promise.resolve());

        try {
            await update;
            await cart.save();
            next();
        } catch(error) {
            next(error);
        }
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.cookies.vid;
        const subscription = req.venzra.subscription._id;

        const cart = await CartModel
            .findOne({ _id, subscription })
            .select('items')
            .populate({
                path: 'items.product',
                select: 'displayName promotionalImage currentPrice',
                match: { status: 'ACTIVE' },
                populate: {
                    path: 'promotionalImage',
                    select: '_id name path',
                },
            })
            .lean();

        const items: Array<CartItem> = cart.items
            .filter((item: CartItem) => item.product)
            .map((item: CartItem) => {
                item.product.promotionalImage = `https://${config.imageBucket}/${item.product.promotionalImage.path}`;
                return item;
            });
        const value = items.reduce((total, item) => total + (item.quantity * (<Product>item.product).currentPrice), 0);

        res.status(200).send({ ...cart, items, value });
    }

}

export default new CartController().router;
