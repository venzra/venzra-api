import * as parser from 'body-parser';
import * as Stripe from 'stripe';
import { ICard } from 'stripe';

import { Response, NextFunction, Router } from 'express';

import { Address, BadRequestError, GatewayError, NotFoundError, Order, ValidationError, VenzraRequest } from '../../models';
import { CartModel, OrderModel, ProductModel } from '../../schemas';
import { ErrorService, IdentityService, MailService } from '../../services';

import { config } from '../../config';

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

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validate.bind(this), this.findAll.bind(this));
        this.router.post('/', this.identityService.validate.bind(this), this.createOrder.bind(this), this.findOne.bind(this));
    }

    createOrder(req: VenzraRequest, res: Response, next: NextFunction) {
        const destination = <Address>req.venzra.customer.addresses.find((address: Address) => address.id === req.body.destination);
        const requestErrors = this.errorService.requiredFields(req.body, ['cart', 'destination', 'token']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const gatewayKey = req.venzra.subscription.gateway.privateKey;
        const stripe = new Stripe(gatewayKey);

        CartModel.findOne({ _id: req.body.cart, subscription: req.venzra.subscription._id })
            .populate({
                path: 'items.product'
            })
            .then((cart) => {
                if (!cart) {
                    throw new BadRequestError('Invalid cart reference');
                }

                const postage = cart.shipping.price;
                const charge = cart.items.reduce((total, item) => total + (item.quantity * item.product.currentPrice), postage);
                const fee = Math.round(charge * req.venzra.subscription.transactions.rate) + req.venzra.subscription.transactions.base;

                return stripe.charges
                    .create({
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
                                postal_code: destination.postalCode
                            }
                        },
                        statement_descriptor: req.venzra.subscription.storeName.substr(0, 22)
                    })
                    .then((payment) => stripe.balance.retrieveTransaction(<string> payment.balance_transaction).then((transaction) => ({ payment, transaction })))
                    .then(({ payment, transaction }) => {
                        const card = <ICard>payment.source;
                        const order = new OrderModel({
                            subscription: req.venzra.subscription,
                            customer: req.venzra.customer,
                            reference: Math.floor((Math.random() * 0.9 + 0.1) * Math.pow(10, 10)),
                            items: cart.items.map((item) => ({ product: item.product, quantity: item.quantity, price: item.product.currentPrice })),
                            shipping: cart.shipping,
                            destination: destination,
                            billing: {
                                addressee: card.name,
                                street: card.address_line1,
                                building: card.address_line2,
                                city: card.address_city,
                                county: card.address_state,
                                country: card.address_country,
                                postalCode: card.address_zip
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
                                    total: transaction.fee
                                },
                                value: payment.amount
                            }
                        });

                        return order.save()
                            .then((result) => req.params.orderId = result._id)
                            .then(() => cart.update({ $set: { items: [] } }).exec())
                            .then(() => order)
                            .catch((orderError) => next(orderError));
                    })
                    .then((order: Order) => {
                        const subject = 'Order confirmation';
                        const subscription = req.venzra.subscription;
                        const origin = `${req.venzra.subscription.storeName} <${req.venzra.subscription.domainName}@${config.emailDomain}>`;

                        const mailer = new MailService(subject, origin, [req.venzra.customer.identity], [origin]);
                        const content = { subject, subscription, order };

                        return mailer.send('order', content);
                    })
                    .then(() => next())
                    .catch((err) => next(new GatewayError(`Stripe Error - ${err.message}`)));
            })
            .catch((err) => next(err));

    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.subscription._id;

        OrderModel
            .findOne({ _id, subscription })
            .select('reference')
            .then((order) => order ? res.status(200).send(order) : next(new NotFoundError()));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.subscription._id, customer: req.venzra.customer._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 5;
        const order = { created: -1 };

        OrderModel
            .count(searchParams).exec()
            .then((total) =>
                OrderModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $skip: skip },
                        { $limit: limit },
                        { $project: { reference: 1, shipping: 1, destination: 1, payment: { name: 1, card: 1, brand: 1, value: 1 }, items: 1, status: 1, created: 1 } }
                    ])
                    .then((result) => ProductModel.populate(result, {
                        path: 'items.product',
                        select: '-_id slug displayName promotionalImage status',
                        populate: {
                            path: 'featureImage',
                            select: '_id name path'
                        }
                    }))
                    .then((list) => res.status(200).send({ list, total, skip, limit }))
            )
            .catch((productError) => next(productError));
    }

}

export default new OrdersController().router;
