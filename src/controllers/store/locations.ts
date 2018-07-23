import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { VenzraRequest } from '../../models';
import { LocationModel } from '../../schemas';

export class LocationController {

    public router: Router;

    constructor() {
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findAll.bind(this));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.subscription._id };
        const order = { displayName: 1 };

        LocationModel
            .count(searchParams).exec()
            .then((total) =>
                LocationModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $project: { displayName: 1, description: 1, address: 1, featureImage: 1, usage: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((error) => next(error));
    }

}

export default new LocationController().router;
