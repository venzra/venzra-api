import * as parser from 'body-parser';

import { Request, Response, NextFunction, Router } from 'express';

import { PlanModel } from '../../schemas';

export class SubscriptionController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/plans', this.getPlans.bind(this));
    }

    public async getPlans(req: Request, res: Response, next: NextFunction) {
        const order = { price: 1, name: 1 };

        const total = await PlanModel.countDocuments().exec();

        const list = await PlanModel
            .aggregate([
                { $sort: order },
                { $project: { reference: 1, name: 1, currency: 1, price: 1, interval: 1, frequency: 1 } },
            ]);

        res.status(200).send({ list, total });
    }

}

export default new SubscriptionController().router;
