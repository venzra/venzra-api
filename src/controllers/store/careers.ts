import * as parser from 'body-parser';
import * as moment from 'moment';

import { Response, NextFunction, Router } from 'express';

import { VenzraRequest } from '../../models';
import { CareerModel } from '../../schemas';

export class CareerController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findAll.bind(this));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.subscription._id;
        const expires = { $gte: moment().startOf('day').toDate() };

        const searchParams = { subscription, expires };
        const order = { expires: 1, position: 1 };

        CareerModel
            .count(searchParams).exec()
            .then((total) =>
                CareerModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $project: { position: 1, description: 1, expires: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((error) => next(error));
    }

}

export default new CareerController().router;
