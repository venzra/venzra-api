import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, Order, PatchRequest, VenzraRequest } from '../../models';
import { CustomerModel, OrderHistoryModel, OrderModel, ProductModel } from '../../schemas';
import { IdentityService } from '../../services';

export class OrdersController {

    public router: Router;

    private identityService: IdentityService;

    constructor() {
        this.router = Router();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.findAll.bind(this));
        this.router.get('/:orderId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:orderId', this.identityService.validateAdmin.bind(this), this.updateOrder.bind(this), this.findOne.bind(this));
    }

    public async updateOrder(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.account.subscription._id;

        const order = await OrderModel
            .findOne({ _id, subscription })
            .populate({
                path: 'customer',
                select: '-_id identity status',
            })
            .populate({
                path: 'history',
            });

        if (!order) {
            return next(new NotFoundError());
        }

        if (!(req.body instanceof Array)) {
            return next();
        }

        const update = (<Array<PatchRequest>>req.body).reduce(async (promise, operation) => {
            await promise;

            switch (operation.op) {
                case 'replace':
                    switch (operation.path) {
                        case 'status':
                            if (order.status !== 'REFUNDED') {
                                const history = new OrderHistoryModel({
                                    account: req.venzra.account._id,
                                    field: operation.path,
                                    previous: order.get(operation.path),
                                    next: operation.value,
                                });

                                await history.save();
                                order.history.unshift(history);
                                order.set(operation.path, operation.value);
                            }
                            break;
                        case 'courier':
                        case 'tracking':
                            order.shipping.set(operation.path, operation.value);
                    }
            }
        }, Promise.resolve());

        try {
            await update;
            await order.save();
            next();
        } catch (error) {
            next(error);
        }
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.orderId;
        const subscription = req.venzra.account.subscription._id;

        const order = await OrderModel
            .findOne({ _id, subscription })
            .select('customer reference items shipping destination billing payment history status created updated')
            .populate({
                path: 'customer',
                select: '-_id identity status',
            })
            .populate({
                path: 'items.product',
                select: '-_id slug code displayName promotionalImage currentPrice status',
                populate: {
                    path: 'promotionalImage',
                    select: '_id name usage path',
                },
            })
            .populate({
                path: 'history',
                select: '-_id -__v',
                populate: {
                    path: 'account',
                    select: 'identity',
                },
            });

        order ? res.status(200).send(order) : next(new NotFoundError());
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.account.subscription._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 20;
        let order: { [key: string]: number } = {};

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

        const total = await OrderModel.countDocuments(searchParams).exec();

        const orders = await OrderModel
            .aggregate([
                { $match: searchParams },
                { $sort: order },
                { $skip: skip },
                { $limit: limit },
                {
                    $project: {
                        customer: 1,
                        reference: 1,
                        shipping: 1,
                        destination: 1,
                        payment: { name: 1, card: 1, brand: 1, fee: 1, value: 1, refund: 1 },
                        items: 1,
                        status: 1,
                        created: 1,
                    },
                },
            ]);

        const customerOrders = await CustomerModel.populate(orders, { path: 'customer', select: '-_id identity status' });

        const list = await ProductModel.populate(customerOrders, {
            path: 'items.product',
            select: '-_id slug code displayName promotionalImage currentPrice status',
            populate: {
                path: 'promotionalImage',
                select: '_id name usage path',
            },
        });

        res.status(200).send({ list, total, skip, limit });
    }

}

export default new OrdersController().router;
