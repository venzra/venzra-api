import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Image, Location, NotFoundError, PatchRequest, VenzraRequest } from '../../models';
import { LocationModel } from '../../schemas';
import { IdentityService } from '../../services';
import { config } from '../../config';

export class LocationController {

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
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createLocation.bind(this), this.findOne.bind(this));
        this.router.get('/:locationId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:locationId', this.identityService.validateAdmin.bind(this), this.updateLocation.bind(this), this.findOne.bind(this));
        this.router.delete('/:locationId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    createLocation(req: VenzraRequest, res: Response, next: NextFunction) {
        const location = new LocationModel({
            subscription: req.venzra.account.subscription._id,
            displayName: req.body.displayName,
            description: req.body.description,
            address: req.body.address,
            featureImage: req.body.featureImage,
            usage: req.body.usage
        });

        location.save()
            .then((result) => {
                req.params.locationId = result._id;
                next();
            })
            .catch((error) => next(error));
    }

    updateLocation(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        LocationModel
            .findOne({ _id, subscription })
            .then((location) => {
                if (!location) {
                    throw new NotFoundError();
                }

                if (!(req.body instanceof Array)) {
                    return;
                }

                (<Array<PatchRequest>>req.body).forEach((operation) => {
                    switch (operation.op) {
                        case 'replace':
                            switch (operation.path) {
                                case 'displayName':
                                case 'description':
                                case 'address':
                                case 'featureImage':
                                case 'usage':
                                    location.set(operation.path, operation.value);
                                    break;
                            }
                    }
                });

                return location.save();
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        LocationModel.findOneAndRemove({ _id, subscription })
            .then((result) => {
                if (!result) {
                    throw new NotFoundError();
                }
                res.status(202).send();
            })
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        LocationModel
            .findOne({ _id, subscription })
            .select('displayName description address featureImage usage created updated')
            .populate({
                path: 'featureImage',
                select: '_id name usage path'
            })
            .lean()
            .then((location: Location) => {
                if(!location) {
                    throw new NotFoundError();
                }
                location.featureImage = `https://${config.imageBucket}/${(<Image>location.featureImage).path}`;
                res.status(200).send(location);
            })
            .catch((locationError) => next(locationError));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.account.subscription._id };
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
                                address: 1,
                                featureImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$featureImage.path', 0] }] },
                                usage: 1,
                                created: 1
                            }
                        }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((error) => next(error));
    }

}

export default new LocationController().router;
