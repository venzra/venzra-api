import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import * as Stripe from 'stripe';
import IApplicationFeeRefund = Stripe.applicationFees.IApplicationFeeRefund;

import { NotFoundError, StripeWebhook, VenzraRequest, WebhookError } from '../../models';

import { OrderModel, PlanModel, SubscriptionModel, OrderHistoryModel } from '../../schemas';
import { config } from '../../config';

const stripe = new Stripe(config.stripe);

export class WebhookController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.raw({ type: '*/*' }));
        this.router.post('/stripe', this.actionStripeHook.bind(this));
        this.router.post('/connect', this.actionConnectHook.bind(this));
    }

    public async actionStripeHook(req: VenzraRequest, res: Response, next: NextFunction) {
        const signature = <string>req.headers['stripe-signature'];

        let event: any;
        try {
            event = stripe.webhooks.constructEvent(req.body, signature, config.stripeWebhooks);
        } catch (error) {
            return next(new WebhookError(error));
        }

        let record = null;
        const payload: StripeWebhook = { type: event.type, data: event.data.object };

        switch (payload.type) {
            case 'plan.created':
                const planData = {
                    reference: payload.data.id,
                    name: payload.data.nickname,
                    currency: payload.data.currency,
                    price: payload.data.amount,
                    interval: payload.data.interval_count,
                    frequency: payload.data.interval,
                };

                let planCreate = await PlanModel.findOne({ reference: payload.data.id });

                if (!planCreate) {
                    record = await PlanModel.create(planData);
                }
                break;
            case 'plan.deleted':
                record = await PlanModel.findOneAndRemove({ reference: payload.data.id });
                break;
            case 'customer.subscription.deleted':
                let subscriptionDelete = await SubscriptionModel.findOne({
                    'payment.customer': payload.data.customer,
                    'payment.subscription': payload.data.id,
                });

                if (subscriptionDelete) {
                    await subscriptionDelete.update({
                        $unset: {
                            'payment.subscription': 1,
                            'payment.package': 1,
                            'payment.price': 1,
                        },
                        $set: {
                            'transactions.rate': 0.046,
                            'payment.status': 'CANCELED',
                            'payment.term': new Date(payload.data.canceled_at * 1000),
                        },
                    });
                }

                record = subscriptionDelete;
                break;
            default:
                console.log(`Ignored stripe hook for "${payload.type}"`);
        }

        res.status(200).send({ result: record ? record._id : 'skipped' });
    }

    public async actionConnectHook(req: VenzraRequest, res: Response, next: NextFunction) {
        const signature = <string>req.headers['stripe-signature'];

        let event: any;
        try {
            event = stripe.webhooks.constructEvent(req.body, signature, config.stripeConnect);
        } catch (error) {
            return next(new WebhookError(error));
        }

        let record = null;
        const payload: StripeWebhook = { type: event.type, account: event.account, data: event.data.object };

        switch (payload.type) {
            case 'account.application.deauthorized':
                let subscriptionDeauth = await SubscriptionModel.findOne({ 'gateway.account': payload.account });

                if (subscriptionDeauth) {
                    await subscriptionDeauth.update({ status: 'INACTIVE', $unset: { gateway: 1 } });
                }

                record = subscriptionDeauth;
                break;
            case 'charge.succeeded':
                const orderCharge = await OrderModel.findOne({ 'payment.reference': payload.data.id }).populate({ path: 'history' });

                if (!orderCharge) {
                    return next(new NotFoundError());
                }

                if (orderCharge.status === 'CREATED') {
                    const history = new OrderHistoryModel({
                        field: 'status',
                        previous: 'CREATED',
                        next: 'AUTHORISED',
                    });

                    await history.save();
                    orderCharge.history.unshift(history);
                    orderCharge.set('status', 'AUTHORISED');
                }

                record = await orderCharge.save();
                break;
            case 'charge.refunded':
                let orderRefund = await OrderModel.findOne({ 'payment.reference': payload.data.id }).populate({ path: 'history' });

                if (!orderRefund) {
                    return next(new NotFoundError());
                }

                const subscription = await SubscriptionModel.findById(orderRefund.subscription);

                if (!subscription) {
                    return next(new NotFoundError());
                }

                if (orderRefund.status === 'REFUNDED') {
                    record = orderRefund;
                    break;
                }

                if (payload.data.amount === payload.data.amount_refunded) {
                    const history = new OrderHistoryModel({
                        field: 'status',
                        previous: orderRefund.status,
                        next: 'REFUNDED',
                    });

                    await history.save();
                    orderRefund.history.unshift(history);
                    orderRefund.set('status', 'REFUNDED');
                }

                orderRefund.set('payment.refund', payload.data.amount_refunded);

                const stripeConnect = await new Stripe(subscription.gateway.privateKey);

                let fee: IApplicationFeeRefund;
                if (payload.data.amount === payload.data.amount_refunded) {
                    fee = await stripe.applicationFees.createRefund(payload.data.application_fee);
                } else {
                    const amount = Math.round(payload.data.refunds.data[0].amount * subscription.transactions.rate);
                    fee = await stripe.applicationFees.createRefund(payload.data.application_fee, { amount });
                }

                const transaction = await stripeConnect.balance.retrieveTransaction(<string>payload.data.refunds.data[0].balance_transaction);

                await orderRefund.update({
                    $inc: {
                        'payment.fee.total': transaction.fee + (fee ? -fee.amount : 0),
                        'payment.fee.venzra.refund': fee ? fee.amount : 0,
                        'payment.fee.gateway.refund': -transaction.fee,
                    },
                });

                record = await orderRefund.save();
                break;
            default:
                console.log(`Ignored connect hook for "${payload.type}"`);
        }

        res.status(200).send({ result: record ? record._id : 'skipped' });
    }

}

export default new WebhookController().router;
