import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Image, NotFoundError, PatchRequest, VenzraRequest } from '../../models';
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

    public registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.findAll.bind(this));
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createLocation.bind(this), this.findOne.bind(this));
        this.router.get('/:locationId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:locationId', this.identityService.validateAdmin.bind(this), this.updateLocation.bind(this), this.findOne.bind(this));
        this.router.delete('/:locationId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    public async createLocation(req: VenzraRequest, res: Response, next: NextFunction) {
        const location = new LocationModel({
            subscription: req.venzra.account.subscription._id,
            displayName: req.body.displayName,
            description: req.body.description,
            address: req.body.address,
            featureImage: req.body.featureImage,
            usage: req.body.usage,
        });

        try {
            const result = await location.save();
            req.params.locationId = result._id;
            next();
        } catch (error) {
            next(error);
        }
    }

    public async updateLocation(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        const location = await LocationModel.findOne({ _id, subscription });

        if (!location) {
            return next(new NotFoundError());
        }

        if (!(req.body instanceof Array)) {
            return next();
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

        try {
            await location.save();
            next();
        } catch(error) {
            next(error);
        }
    }

    public async removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        const result = await LocationModel.findOneAndRemove({ _id, subscription });

        if (!result) {
            return next(new NotFoundError());
        }

        res.status(202).send();
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.locationId;
        const subscription = req.venzra.account.subscription._id;

        const location = await LocationModel
            .findOne({ _id, subscription })
            .select('displayName description address featureImage usage created updated')
            .populate({
                path: 'featureImage',
                select: '_id name usage path',
            })
            .lean();

        if (!location) {
            return next(new NotFoundError());
        }

        location.featureImage = `https://${config.imageBucket}/${(<Image>location.featureImage).path}`;
        res.status(200).send(location);
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.account.subscription._id };
        const order = { displayName: 1 };

        const total = await LocationModel.countDocuments(searchParams).exec();

        const list = await LocationModel
            .aggregate([
                { $match: searchParams },
                { $sort: order },
                {
                    $lookup: {
                        from: 'images',
                        localField: 'featureImage',
                        foreignField: '_id',
                        as: 'featureImage',
                    },
                },
                {
                    $project: {
                        displayName: 1,
                        address: 1,
                        featureImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$featureImage.path', 0] }] },
                        usage: 1,
                        created: 1,
                    },
                },
            ]);

        res.status(200).send({ list, total });
    }

}

export default new LocationController().router;
