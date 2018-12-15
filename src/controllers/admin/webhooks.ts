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

    registerRoutes() {
        this.router.use(parser.raw({ type: '*/*' }));
        this.router.post('/stripe', this.actionStripeHook.bind(this));
        this.router.post('/connect', this.actionConnectHook.bind(this));
    }

    actionStripeHook(req: VenzraRequest, res: Response, next: NextFunction) {
        const signature = <string> req.headers['stripe-signature'];

        const promise = new Promise((resolve, reject) => {
            try {
                const event: StripeWebhook = stripe.webhooks.constructEvent(req.body, signature, config.stripeWebhooks);

                const type = event.type;
                const data = event.data.object;

                resolve({ type, data });
            } catch (error) {
                reject(error);
            }
        });

        promise
            .catch((error) => { throw new WebhookError(error); })
            .then(async (payload: StripeWebhook): Promise<any> => {
                switch (payload.type) {
                    case 'plan.created':
                        const planData = {
                            reference: payload.data.id,
                            name: payload.data.nickname,
                            currency: payload.data.currency,
                            price: payload.data.amount,
                            interval: payload.data.interval_count,
                            frequency: payload.data.interval
                        };

                        let planCreate = await PlanModel.findOne({ reference: payload.data.id });

                        if (!planCreate) {
                            return await PlanModel.create(planData);
                        } else {
                            return null;
                        }
                    case 'plan.deleted':
                        const planDelete = await PlanModel.findOne({ reference: payload.data.id });

                        if (planDelete) {
                            await planDelete.remove();
                        }

                        return planDelete;
                    case 'customer.subscription.deleted':
                        let subscriptionDelete = await SubscriptionModel.findOne({ 'payment.customer': payload.data.customer, 'payment.subscription': payload.data.id });

                        if(subscriptionDelete) {
                            await subscriptionDelete.update({
                                $unset: {
                                    'payment.subscription': 1,
                                    'payment.package': 1,
                                    'payment.price': 1
                                },
                                $set: {
                                    'transactions.rate': 0.046,
                                    'payment.status': 'CANCELED',
                                    'payment.term': new Date(payload.data.canceled_at * 1000)
                                }
                            });
                        }

                        return subscriptionDelete;
                    default:
                        console.log(`Ignored stripe hook for "${payload.type}"`);
                }

            })
            .then((record: any) => res.status(200).send({ result: record ? record._id : 'skipped' }))
            .catch((error) => next(error));
    }

    actionConnectHook(req: VenzraRequest, res: Response, next: NextFunction) {
        const signature = <string> req.headers['stripe-signature'];

        const promise = new Promise((resolve, reject) => {
            try {
                const event: StripeWebhook = stripe.webhooks.constructEvent(req.body, signature, config.stripeConnect);

                const type = event.type;
                const account = event.account;
                const data = event.data.object;

                resolve({ type, account, data });
            } catch (error) {
                reject(error);
            }
        });

        promise
            .catch((error) => { throw new WebhookError(error); })
            .then(async (payload: StripeWebhook): Promise<any> => {
                switch (payload.type) {
                    case 'account.application.deauthorized':
                        let subscriptionDeauth = await SubscriptionModel.findOne({ 'gateway.account': payload.account });

                        if (subscriptionDeauth) {
                            await subscriptionDeauth.update({ status: 'INACTIVE', $unset: { gateway: 1 } });
                        }

                        return subscriptionDeauth;
                    case 'charge.succeeded':
                        const orderCharge = await OrderModel.findOne({ 'payment.reference': payload.data.id }).populate({ path: 'history' });

                        if (!orderCharge) {
                            throw new NotFoundError();
                        }

                        if (orderCharge.status === 'CREATED') {
                            const history = new OrderHistoryModel({ field: 'status', previous: 'CREATED', next: 'AUTHORISED' });

                            await history.save();
                            orderCharge.history.unshift(history);
                            orderCharge.set('status', 'AUTHORISED');
                        }

                        return await orderCharge.save();
                    case 'charge.refunded':
                        let orderRefund = await OrderModel.findOne({ 'payment.reference': payload.data.id }).populate({ path: 'history' });

                        if (!orderRefund) {
                            throw new NotFoundError();
                        }

                        const subscription = await SubscriptionModel.findById(orderRefund.subscription);

                        if (!subscription) {
                            throw new NotFoundError();
                        }

                        if (orderRefund.status === 'REFUNDED') {
                            return orderRefund;
                        }

                        if (payload.data.amount === payload.data.amount_refunded) {
                            const history = new OrderHistoryModel({ field: 'status', previous: orderRefund.status, next: 'REFUNDED' });

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

                        const transaction = await stripeConnect.balance.retrieveTransaction(<string> payload.data.refunds.data[0].balance_transaction);

                        await orderRefund.update({
                            $inc: {
                                'payment.fee.total': transaction.fee + (fee ? -fee.amount : 0),
                                'payment.fee.venzra.refund': fee ? fee.amount : 0,
                                'payment.fee.gateway.refund': -transaction.fee
                            }
                        });

                        return await orderRefund.save();
                    default:
                        console.log(`Ignored connect hook for "${payload.type}"`);
                }

            })
            .then((record: any) => res.status(200).send({ result: record ? record._id : 'skipped' }))
            .catch((error) => next(error));
    }

}

export default new WebhookController().router;
