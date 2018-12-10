import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';
import * as request from 'request';
import * as Stripe from 'stripe';

import { PatchRequest, StripeError, ValidationError, VenzraRequest } from '../../models';
import { ErrorService, IdentityService } from '../../services';

import { config } from '../../config';

const stripe = new Stripe(config.stripe);

export class SubscriptionController {

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
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.identityService.getSubscription.bind(this));
        this.router.patch('/', this.identityService.validateAdmin.bind(this), this.updateSettings.bind(this), this.identityService.getSubscription.bind(this));
        this.router.patch('/add-ons', this.identityService.validateAdmin.bind(this), this.enableAddon.bind(this), this.identityService.getSubscription.bind(this));
        this.router.post('/contact', this.identityService.validateAdmin.bind(this), this.createContact.bind(this), this.identityService.getSubscription.bind(this));
        this.router.post('/payment', this.identityService.validateAdmin.bind(this), this.attachPayment.bind(this), this.identityService.getSubscription.bind(this));
        this.router.post('/gateway', this.identityService.validateAdmin.bind(this), this.attachGateway.bind(this), this.identityService.getSubscription.bind(this));
    }

    enableAddon(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!(req.body instanceof Array)) {
            return next();
        }

        const subscription = req.venzra.account.subscription;

        (<Array<PatchRequest>>req.body).forEach((operation) => {
            switch (operation.op) {
                case 'add':
                    if (!subscription.addons.find((addon) => addon.name === operation.value)) {
                        subscription.addons.push({
                            name: operation.value,
                            value: 0
                        });
                    }
                    break;
                case 'remove':
                    subscription.addons = subscription.addons.filter((addon) => addon.name !== operation.value);
            }
        });

        subscription.save()
            .then(() => subscription.update({ $push: { addons: { $each: [], $sort: { name: 1 } } } }))
            .then(() => next())
            .catch((error) => next(error));
    }

    createContact(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription;

        subscription.contact = {
            recipient: req.body.recipient,
            fields: req.body.fields
        };

        subscription.save()
            .then(() => next())
            .catch((error) => next(error));
    }

    attachPayment(req: VenzraRequest, res: Response, next: NextFunction) {
        const requestErrors = this.errorService.requiredFields(req.body, ['email', 'plan', 'token']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const promise = new Promise((resolve, reject) => {
            if (req.venzra.account.subscription.payment && req.venzra.account.subscription.payment.customer) {
                stripe.subscriptions
                    .create({
                        customer: req.venzra.account.subscription.payment.customer,
                        plan: req.body.plan,
                        quantity: 20,
                        source: req.body.token.id
                    })
                    .then((subscription) => resolve(subscription))
                    .catch((error) => reject(error));
            } else {
                stripe.customers
                    .create({
                        email: req.body.email,
                        plan: req.body.plan,
                        quantity: 20,
                        source: req.body.token.id
                    })
                    .then((customer) => resolve(customer.subscriptions.data[0]))
                    .catch((error) => reject(error));
            }
        });

        promise
            .then((subscription: any) => {
                req.venzra.account.subscription.transactions.rate = 0.021;

                req.venzra.account.subscription.payment = {
                    customer: subscription.customer,
                    subscription: subscription.id,
                    package: subscription.plan.id,
                    price: {
                        currency: subscription.plan.currency,
                        quantity: subscription.quantity,
                        value: subscription.plan.amount
                    },
                    term: new Date(subscription.current_period_end * 1000),
                    status: subscription.status
                };

                return req.venzra.account.subscription.save();
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    attachGateway(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!req.venzra.account.subscription || req.venzra.account.subscription.gateway) {
            return next();
        }

        const errors = [];

        if (!req.body.reference) {
            errors.push({ path: 'reference', kind: 'required' });
        }

        if (errors.length) {
            return next(new ValidationError(errors));
        }

        const promise = new Promise((resolve, reject) => {
            request.post({
                uri: 'https://connect.stripe.com/oauth/token',
                json: {
                    client_secret: config.stripe,
                    code: req.body.reference,
                    grant_type: 'authorization_code'
                }
            }, (error, response, body) => (response.statusCode !== 200) ? reject(body) : resolve(body));
        });

        promise
            .then((gateway: { stripe_user_id: string, refresh_token: string, stripe_publishable_key: string, access_token: string }) => {
                req.venzra.account.subscription.status = 'ACTIVE';

                req.venzra.account.subscription.gateway = {
                    account: gateway.stripe_user_id,
                    refreshToken: gateway.refresh_token,
                    publicKey: gateway.stripe_publishable_key,
                    privateKey: gateway.access_token,
                    modified: new Date()
                };

                return req.venzra.account.subscription.save();
            })
            .then(() => next())
            .catch((err) => next(new StripeError(err.error_description)));
    }

    updateSettings(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!(req.body instanceof Array)) {
            return next();
        }

        (<Array<PatchRequest>>req.body).forEach((operation) => {
            switch (operation.op) {
                case 'replace':
                    switch (operation.path) {
                        case 'storeName':
                            if (!operation.value) {
                                return next(new ValidationError([{ path: 'storeName', kind: 'required' }]));
                            }
                        /* falls through */
                        case 'additionalDomains':
                        case 'theme':
                        case 'strapline':
                        case 'icon':
                        case 'logo':
                            req.venzra.account.subscription[operation.path] = operation.value;
                    }
            }
        });

        req.venzra.account.subscription.save()
            .then(() => next())
            .catch((error) => next(error));
    }

}

export default new SubscriptionController().router;
