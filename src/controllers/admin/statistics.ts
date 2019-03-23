import * as parser from 'body-parser';
import moment = require('moment');

import { NextFunction, Response, Router } from 'express';

import { VenzraRequest } from '../../models';
import { CartModel, OrderModel, ProductModel, ShippingModel } from '../../schemas';
import { IdentityService } from '../../services';

export class StatisticsController {

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
        this.router.get('/highlights', this.identityService.validateAdmin.bind(this), this.highlights.bind(this));
        this.router.get('/orders/volume', this.identityService.validateAdmin.bind(this), this.orderVolume.bind(this));
        this.router.get('/orders/status', this.identityService.validateAdmin.bind(this), this.orderStatus.bind(this));
    }

    public async highlights(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription._id;
        const numberOfDays = 30;
        const startDate = moment().startOf('day').subtract(numberOfDays - 1, 'days').toDate();

        const results = await Promise
            .all([
                ProductModel.countDocuments({ subscription, status: 'ACTIVE' }),
                ShippingModel.countDocuments({ subscription }),
                CartModel.aggregate([
                    { $match: { subscription, created: { $gte: startDate } } },
                    { $group: { _id: '$subscription', count: { $sum: 1 } } },
                    { $project: { _id: 0, count: 1 } },
                ]).exec(),
                CartModel.aggregate([
                    { $match: { subscription, created: { $gte: startDate } } },
                    {
                        $group: {
                            _id: '$subscription',
                            count: {
                                $sum: {
                                    $switch: {
                                        branches: [{ case: { $gt: [{ $size: '$items' }, 0] }, then: 1 }],
                                        default: 0,
                                    },
                                },
                            },
                        },
                    },
                    { $project: { _id: 0, count: 1 } },
                ]).exec(),
                OrderModel
                    .aggregate([
                        { $match: { subscription, status: { $ne: 'REFUNDED' }, created: { $gte: startDate } } },
                        {
                            $group: {
                                _id: '$subscription',
                                count: { $sum: 1 },
                                value: { $sum: '$payment.value' },
                                refund: { $sum: '$payment.refund' },
                                fees: { $sum: '$payment.fee.total' },
                            },
                        },
                        { $project: { _id: 0, count: 1, value: 1, refund: 1, fees: 1 } },
                    ]).exec(),
            ]);

        res.status(200).send({
            products: results[0],
            shipping: results[1],
            visitors: results[2][0] ? results[2][0].count : 0,
            carts: results[3][0] ? results[3][0].count : 0,
            orders: results[4][0] ? results[4][0].count : 0,
            turnover: results[4][0] ? results[4][0].value - (results[4][0].fees || 0) - (results[4][0].refund || 0) : 0,
        });
    }

    public async orderVolume(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription._id;
        const numberOfDays = 30;
        const startDate = moment().startOf('day').subtract(numberOfDays - 1, 'days').toDate();

        const result = await OrderModel
            .aggregate([
                { $match: { subscription, status: { $ne: 'REFUNDED' }, created: { $gte: startDate } } },
                {
                    $group: {
                        _id: {
                            year: { $year: '$created' },
                            month: { $month: '$created' },
                            day: { $dayOfMonth: '$created' },
                        },
                        count: { $sum: 1 },
                        value: { $sum: '$payment.value' },
                        refund: { $sum: '$payment.refund' },
                    },
                },
                {
                    $sort: {
                        '_id.year': 1,
                        '_id.month': 1,
                        '_id.day': 1,
                    },
                },
                {
                    $project: {
                        _id: 0,
                        year: '$_id.year',
                        month: '$_id.month',
                        day: '$_id.day',
                        count: 1,
                        value: 1,
                        refund: 1,
                    },
                },
            ]);

        let orderVolumes: Array<{ [key: string]: number }> = [];
        if (result.length > 0) {
            for (let i = 0; i < numberOfDays; i++) {
                const nextDate = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);
                const data = result.find((entry) => entry.year === nextDate.getFullYear() && entry.month === (nextDate.getMonth() + 1) && entry.day === nextDate.getDate());

                if (data) {
                    orderVolumes = [...orderVolumes, data];
                } else {
                    orderVolumes = [...orderVolumes, {
                        year: nextDate.getFullYear(),
                        month: nextDate.getMonth() + 1,
                        day: nextDate.getDate(),
                        value: 0,
                        refund: 0,
                        count: 0,
                    }];
                }
            }
        }
        res.status(200).send({ list: orderVolumes, total: orderVolumes.length });
    }

    public async orderStatus(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription._id;

        const result = await OrderModel
            .aggregate([
                { $match: { subscription, status: { $nin: ['DELIVERED', 'REFUNDED'] } } },
                {
                    $group: {
                        _id: { status: '$status' },
                        count: { $sum: 1 },
                        value: { $sum: '$payment.value' },
                    },
                },
                {
                    $sort: {
                        '_id.status': 1,
                    },
                },
                { $project: { _id: 0, status: '$_id.status', count: 1, value: 1 } },
            ]);

        res.status(200).send({ list: result, total: result.length });
    }

}

export default new StatisticsController().router;
