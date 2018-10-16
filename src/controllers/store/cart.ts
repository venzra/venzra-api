import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Cart, PatchRequest, Product, Shipping, VenzraRequest } from '../../models';
import { CartModel, ProductModel, ShippingModel } from '../../schemas';

export class CartController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findOne.bind(this));
        this.router.patch('/', this.updateBasket.bind(this), this.findOne.bind(this));
    }

    updateBasket(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.cookies.vid;
        const subscription = req.venzra.subscription._id;

        CartModel
            .findOne({ _id, subscription })
            .then((cart: Cart) => {
                if (!(req.body instanceof Array)) {
                    return;
                }

                let promise = Promise.resolve();

                (<Array<PatchRequest>>req.body).forEach((operation) => {
                    switch (operation.op) {
                        case 'add':
                            switch (operation.path) {
                                case 'product':
                                    promise = promise
                                        .then(() => ProductModel.findOne({ _id: operation.value, subscription, status: 'ACTIVE' }).exec())
                                        .then((product: Product) => {
                                            if (!product) {
                                                return;
                                            }

                                            const item = cart.items.find((entry) => entry.product.toString() === product._id.toString());

                                            if (item) {
                                                item.quantity++;
                                            } else {
                                                cart.items.push({ product: product._id ,quantity: 1 });
                                            }

                                            cart.set('shipping', undefined);
                                        });
                            }
                            break;
                        case 'replace':
                            switch (operation.path) {
                                case 'shipping':
                                    promise = promise
                                        .then(() => ShippingModel.findOne({ _id: operation.value, subscription }).exec())
                                        .then((shipping: Shipping) => {
                                            if (!shipping) {
                                                return;
                                            }

                                            cart.set('shipping', { reference: shipping._id, name: shipping.displayName, price: shipping.currentPrice });
                                        });
                            }
                            break;
                        case 'remove':
                            switch (operation.path) {
                                case 'product':
                                    promise = promise
                                        .then(() => {
                                            const item = cart.items.find((entry) => entry.product.toString() === operation.value);

                                            if (!item) {
                                                return;
                                            }

                                            item.quantity--;

                                            if (item.quantity <= 0) {
                                                cart.items = cart.items.filter((entry) => entry.product.toString() !== operation.value);
                                            }

                                            cart.set('shipping', undefined);
                                        });
                            }
                    }
                });

                return promise.then(() => cart.save());
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.cookies.vid;
        const subscription = req.venzra.subscription._id;

        CartModel
            .findOne({ _id, subscription })
            .select('items shipping')
            .populate({
                path: 'items.product',
                select: 'displayName promotionalImage currentPrice',
                match: { status: 'ACTIVE' },
                populate: {
                    path: 'promotionalImage',
                    select: '_id name usage'
                }
            })
            .then((cart) => (<Cart>cart).toObject())
            .then((cart: Cart) => {
                const items = cart.items.filter((item) => item.product);
                const value = items.reduce((total, item) => total + (item.quantity * (<Product>item.product).currentPrice), 0);
                return { ...cart, items, value };
            })
            .then((cart) => res.status(200).send(cart));
    }

}

export default new CartController().router;
