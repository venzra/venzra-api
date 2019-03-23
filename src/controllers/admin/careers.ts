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

    public registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.findAll.bind(this));
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createCareer.bind(this), this.findOne.bind(this));
        this.router.get('/:careerId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:careerId', this.identityService.validateAdmin.bind(this), this.updateCareer.bind(this), this.findOne.bind(this));
        this.router.delete('/:careerId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    public async createCareer(req: VenzraRequest, res: Response, next: NextFunction) {
        const career = new CareerModel({
            subscription: req.venzra.account.subscription._id,
            position: req.body.position,
            description: req.body.description,
            expires: req.body.expires,
        });

        try {
            const result = await career.save();
            req.params.careerId = result._id;
        } catch (error) {
            return next(error);
        }
        next();
    }

    public async updateCareer(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        const career = await CareerModel.findOne({ _id, subscription });

        if (!career) {
            return next(new NotFoundError());
        }

        if (!(req.body instanceof Array)) {
            return next();
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

        try {
            await career.save();
        } catch (error) {
            return next(error);
        }

        next();
    }

    public async removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        try {
            const result = await CareerModel.findOneAndRemove({ _id, subscription });
            if (!result) {
                return next(new NotFoundError());
            }
        } catch (error) {
            return next(error);
        }

        res.status(202).send();
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.careerId;
        const subscription = req.venzra.account.subscription._id;

        const content = await CareerModel.findOne({ _id, subscription })
            .select('position description expires created updated');

        if (!content) {
            return next(new NotFoundError());
        }

        res.status(200).send(content);
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.account.subscription._id };
        const order = { expires: 1 };

        const total = await CareerModel.count(searchParams).exec();
        const list = await
            CareerModel
                .aggregate([
                    { $match: searchParams },
                    { $sort: order },
                    { $project: { position: 1, expires: 1, created: 1 } },
                ]);

        res.status(200).send({ list, total });
    }

}

export default new CareerController().router;
