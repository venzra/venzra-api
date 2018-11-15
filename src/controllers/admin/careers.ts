import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, PatchRequest, VenzraRequest } from '../../models';
import { CareerModel } from '../../schemas';
import { IdentityService } from '../../services';

export class CareerController {

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
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createCareer.bind(this), this.findOne.bind(this));
        this.router.get('/:careerId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:careerId', this.identityService.validateAdmin.bind(this), this.updateCareer.bind(this), this.findOne.bind(this));
        this.router.delete('/:careerId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    createCareer(req: VenzraRequest, res: Response, next: NextFunction) {
        const career = new CareerModel({
            subscription: req.venzra.account.subscription._id,
            position: req.body.position,
            description: req.body.description,
            expires: req.body.expires
        });

        career.save()
            .then((result) => {
                req.params.careerId = result._id;
                next();
            })
            .catch((error) => next(error));
    }

    updateCareer(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        CareerModel
            .findOne({ _id, subscription })
            .then((career) => {
                if (!career) {
                    throw new NotFoundError();
                }

                if (!(req.body instanceof Array)) {
                    return;
                }

                (<Array<PatchRequest>>req.body).forEach((operation) => {
                    switch (operation.op) {
                        case 'replace':
                            switch (operation.path) {
                                case 'position':
                                case 'description':
                                case 'expires':
                                    career.set(operation.path, operation.value);
                                    break;
                            }
                    }
                });

                return career.save();
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        CareerModel.findOneAndRemove({ _id, subscription })
            .then((result) => {
                if (!result) {
                    throw new NotFoundError();
                }
                res.status(202).send();
            })
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        CareerModel
            .findOne({ _id, subscription })
            .select('position description expires created updated')
            .then((content) => {
                if (!content) {
                    throw new NotFoundError();
                }
                res.status(200).send(content);
            })
            .catch((error) => next(error));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.account.subscription._id };
        const order = { expires: 1 };

        CareerModel
            .count(searchParams).exec()
            .then((total) =>
                CareerModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $project: { position: 1, expires: 1, created: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total }))
            )
            .catch((error) => next(error));
    }

}

export default new CareerController().router;
