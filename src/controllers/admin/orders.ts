import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, Order, PatchRequest, VenzraRequest } from '../../models';
import { CustomerModel, OrderModel, ProductModel } from '../../schemas';
import { IdentityService } from '../../services';
import { OrderHistoryModel } from '../../schemas/order-history';

export class OrdersController {

    public router: Router;

    private identityService: IdentityService;

    constructor() {
        this.router = Router();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.findAll.bind(this));
        this.router.get('/:orderId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:orderId', this.identityService.validateAdmin.bind(this), this.updateOrder.bind(this), this.findOne.bind(this));
    }

    updateOrder(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.account.subscription._id;

        OrderModel
            .findOne({ _id, subscription })
            .populate({
                path: 'customer',
                select: '-_id identity status'
            })
            .populate({
                path: 'history'
            })
            .then((order: Order) => {
                if (!order) {
                    throw new NotFoundError();
                }

                if (!(req.body instanceof Array)) {
                    return;
                }

                let promise: Promise<any> = Promise.resolve();

                (<Array<PatchRequest>>req.body).forEach((operation) => {
                    switch (operation.op) {
                        case 'replace':
                            switch (operation.path) {
                                case 'status':
                                    if (order.status !== 'REFUNDED') {
                                        const history = new OrderHistoryModel({ account: req.venzra.account._id, field: operation.path, previous: order.get(operation.path), next: operation.value });
                                        promise = promise
                                            .then(() => history.save())
                                            .then(() => order.history.unshift(history))
                                            .then(() => order.set(operation.path, operation.value));
                                    }
                                    break;
                                case 'courier':
                                case 'tracking':
                                    promise = promise
                                        .then(() => order.shipping.set(operation.path, operation.value));
                            }
                    }
                });

                return promise.then(() => order.save());
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.account.subscription._id;

        OrderModel
            .findOne({ _id, subscription })
            .select('customer reference items shipping destination billing payment history status created updated')
            .populate({
                path: 'customer',
                select: '-_id identity status'
            })
            .populate({
                path: 'items.product',
                select: '-_id slug code displayName promotionalImage currentPrice status',
                populate: {
                    path: 'promotionalImage',
                    select: '_id name usage path'
                }
            })
            .populate({
                path: 'history',
                select: '-_id -__v',
                populate: {
                    path: 'account',
                    select: 'identity'
                }
            })
            .then((order) => order ? res.status(200).send(order) : next(new NotFoundError()));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.account.subscription._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 20;
        let order: { [key: string ]: number } = {};

        if (req.query.search) {
            searchParams.reference = new RegExp(req.query.search, 'i');
        }

        if (req.query.status) {
            searchParams.status = req.query.status.toUpperCase();
        }

        switch (req.query.sort) {
            case 'status':
                order[req.query.sort] = (req.query.direction === 'desc') ? -1 : 1;
                break;
            default:
                order = { created: req.query.direction === 'asc' ? 1 : -1 };
        }

        OrderModel
            .count(searchParams).exec()
            .then((total) =>
                OrderModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $skip: skip },
                        { $limit: limit },
                        { $project: { customer: 1, reference: 1, shipping: 1, destination: 1, payment: { name: 1, card: 1, brand: 1, fee: 1, value: 1, refund: 1 }, items: 1, status: 1, created: 1 } }
                    ])
                    .then((result) => CustomerModel.populate(result, {
                        path: 'customer',
                        select: '-_id identity status'
                    }))
                    .then((result) => ProductModel.populate(result, {
                        path: 'items.product',
                        select: '-_id slug code displayName promotionalImage currentPrice status',
                        populate: {
                            path: 'promotionalImage',
                            select: '_id name usage path'
                        }
                    }))
                    .then((list) => res.status(200).send({ list, total, skip, limit }))
            )
            .catch((productError) => next(productError));
    }

}

export default new OrdersController().router;
