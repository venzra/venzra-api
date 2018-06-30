import * as parser from 'body-parser';

import { Request, Response, NextFunction, Router } from 'express';

import { PlanModel } from '../../schemas';

export class SubscriptionController {

    public router: Router;

    constructor() {
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/plans', this.getPlans.bind(this));
    }

    getPlans(req: Request, res: Response, next: NextFunction): void {
        const order = { price: 1, name: 1 };

        PlanModel
            .count(undefined)
            .exec()
            .then((total) =>
                PlanModel
                    .aggregate([
                        { $sort: order },
                        { $project: { reference: 1, name: 1, currency: 1, price: 1, interval: 1, frequency: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((err) => next(err));
    }

}

export default new SubscriptionController().router;
