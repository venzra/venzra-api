import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { ImageModel, LocationModel, ProductModel } from '../../schemas';
import { config } from '../../config';

export class LocationController {

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
        const searchParams = { subscription: req.venzra.subscription._id };
        const order = { displayName: 1 };

        LocationModel
            .countDocuments(searchParams).exec()
            .then((total) =>
                LocationModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        {
                            $lookup: {
                                from: 'images',
                                localField: 'featureImage',
                                foreignField: '_id',
                                as: 'featureImage'
                            }
                        },
                        {
                            $project: {
                                displayName: 1,
                                description: 1,
                                address: 1,
                                featureImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$featureImage.path', 0] }] },
                                usage: 1
                            }
                        }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((error) => next(error));
    }

}

export default new LocationController().router;
