import * as parser from 'body-parser';
import * as Stripe from 'stripe';
import { ICard } from 'stripe';

import { Response, NextFunction, Router } from 'express';

import {
    Address,
    Cart,
    GatewayError,
    Item,
    NotFoundError,
    Product,
    Shipping,
    ValidationError,
    VenzraRequest,
} from '../../models';

import { CartModel, OrderModel, ShippingModel } from '../../schemas';
import { ErrorService, IdentityService, MailService } from '../../services';

import { config } from '../../config';
import ICharge = Stripe.charges.ICharge;
import IBalanceTransaction = Stripe.balance.IBalanceTransaction;

export class OrdersController {

    public router: Router;

    private errorService: ErrorService;
    private identityService: IdentityService;

    constructor() {
        this.router = Router();
        this.errorService = new ErrorService();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateCustomer.bind(this), this.findAll.bind(this));
        this.router.post('/', this.identityService.validateCustomer.bind(this), this.createOrder.bind(this), this.findOne.bind(this));
    }

    public async createOrder(req: VenzraRequest, res: Response, next: NextFunction) {
        const destination = <Address>req.venzra.customer.addresses.find((address: Address) => address.id === req.body.destination);
        const requestErrors = this.errorService.requiredFields(req.body, ['token', 'destination', 'shipping']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        let cart: Cart;
        let shipping: Shipping;
        [cart, shipping] = await Promise
            .all([
                <any>CartModel.findOne({
                    _id: req.cookies.vid,
                    subscription: req.venzra.subscription._id,
                }).populate({ path: 'items.product' }),
                <any>ShippingModel.findOne({ _id: req.body.shipping, subscription: req.venzra.subscription._id }),
            ]);

        const errors = [];

        if (!cart.items.length) {
            errors.push({ path: 'cart', kind: 'invalid' });
        }

        if (!destination) {
            errors.push({ path: 'destination', kind: 'invalid' });
        }

        if (!shipping) {
            errors.push({ path: 'shipping', kind: 'invalid' });
        }

        if (errors.length) {
            return next(new ValidationError(errors));
        }

        const gatewayKey = req.venzra.subscription.gateway.privateKey;
        const stripe = new Stripe(gatewayKey);
        const postage = shipping.currentPrice;
        const charge = cart.items.reduce((total: number, item: Item) => total + (item.quantity * (<Product>item.product).currentPrice), postage);
        const fee = Math.round(charge * req.venzra.subscription.transactions.rate) + req.venzra.subscription.transactions.base;

        let payment: ICharge;
        let transaction: IBalanceTransaction;

        try {
            payment = await stripe.charges.create({
                amount: charge,
                currency: 'gbp',
                application_fee: fee,
                source: req.body.token.id,
                shipping: {
                    name: destination.addressee,
                    address: {
                        line1: destination.street,
                        line2: destination.building,
                        city: destination.city,
                        state: destination.county,
                        postal_code: destination.postalCode,
                    },
                },
                statement_descriptor: req.venzra.subscription.storeName.substr(0, 22),
            });
        } catch (error) {
            return next(new GatewayError(`Stripe Error - ${error.message}`));
        }

        try {
            transaction = await stripe.balance.retrieveTransaction(<string>payment.balance_transaction);
        } catch (error) {
            return next(new GatewayError(`Stripe Error - ${error.message}`));
        }

        const card = <ICard>payment.source;
        const order = new OrderModel({
            subscription: req.venzra.subscription,
            customer: req.venzra.customer,
            reference: Math.floor((Math.random() * 0.9 + 0.1) * Math.pow(10, 10)),
            items: cart.items.map((item: Item) => ({
                product: item.product,
                quantity: item.quantity,
                price: (<Product>item.product).currentPrice,
            })),
            shipping: {
                reference: shipping._id,
                name: shipping.displayName,
                price: shipping.currentPrice,
            },
            destination: destination,
            billing: {
                addressee: card.name,
                street: card.address_line1,
                building: card.address_line2,
                city: card.address_city,
                county: card.address_state,
                country: card.address_country,
                postalCode: card.address_zip,
            },
            payment: {
                reference: payment.id,
                transaction: transaction.id,
                name: card.name,
                card: card.last4,
                brand: card.brand,
                fee: {
                    venzra: transaction.fee_details.find((part) => part.type === 'application_fee'),
                    gateway: transaction.fee_details.find((part) => part.type === 'stripe_fee'),
                    total: transaction.fee,
                },
                value: payment.amount,
            },
        });

        try {
            await order.save();
            req.params.orderId = order._id;
        } catch (error) {
            return next(error);
        }

        try {
            await cart.update({ $set: { items: [] } }).exec();
        } catch (error) {
            return next(error);
        }

        const subject = 'Order confirmation';
        const subscription = req.venzra.subscription;
        const origin = `${req.venzra.subscription.storeName} <${req.venzra.subscription.domainName}@${config.emailDomain}>`;

        const mailer = new MailService(subject, origin, [req.venzra.customer.identity], [origin]);
        const content = { subject, subscription, order };

        try {
            await mailer.send('order', content);
            next();
        } catch (error) {
            next(error);
        }
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.subscription._id;

        const order = await OrderModel.findOne({ _id, subscription }).select('reference');

        if (!order) {
            return next(new NotFoundError());
        }

        res.status(200).send(order);
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.subscription._id, customer: req.venzra.customer._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 5;
        const order = { created: -1 };

        const total = await OrderModel.countDocuments(searchParams).exec();

        const list = await OrderModel
            .aggregate([
                { $match: searchParams },
                { $sort: order },
                { $skip: skip },
                { $limit: limit },
                { $unwind: '$items' },
                {
                    $lookup: {
                        from: 'products',
                        localField: 'items.product',
                        foreignField: '_id',
                        as: 'items.product',
                    },
                },
                { $unwind: '$items.product' },
                {
                    $lookup: {
                        from: 'images',
                        localField: 'items.product.promotionalImage',
                        foreignField: '_id',
                        as: 'items.fullImage',
                    },
                },
                {
                    $project: {
                        reference: 1,
                        shipping: 1,
                        destination: 1,
                        payment: { name: 1, card: 1, brand: 1, value: 1 },
                        items: {
                            product: {
                                slug: 1,
                                displayName: 1,
                                promotionalImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$items.fullImage.path', 0] }] },
                                status: 1,
                            },
                            quantity: 1,
                            price: 1,
                        },
                        status: 1,
                        created: 1,
                    },
                },
                {
                    $group: {
                        _id: '$_id',
                        reference: { $first: '$reference' },
                        shipping: { $first: '$shipping' },
                        destination: { $first: '$destination' },
                        payment: { $first: '$payment' },
                        items: { $push: '$items' },
                        status: { $first: '$status' },
                        created: { $first: '$created' },
                    },
                },
                { $sort: order },
            ]);

        res.status(200).send({ list, total, skip, limit });
    }

}

export default new OrdersController().router;
