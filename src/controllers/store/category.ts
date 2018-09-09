import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { CategoryModel } from '../../schemas';
import { ErrorService, IdentityService } from '../../services';

export class CategoryController {

    public router: Router;

    private errorService: ErrorService;
    private identityService: IdentityService;

    constructor() {
        this.router = Router();
        this.errorService = new ErrorService();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.findAll.bind(this));
        this.router.get('/:categorySlug', this.findOne.bind(this));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const slug = req.params.categorySlug;
        const subscription = req.venzra.subscription._id;

        CategoryModel
            .findOne({ subscription, slug })
            .select('slug name description featureImage')
            .populate({
                path: 'parent',
                select: 'slug name featureImage'
            })
            .populate({
                path: 'children',
                select: 'slug name featureImage'
            })
            .then((category) => {
                if (!category) {
                    throw new NotFoundError();
                }
                res.status(200).send(category);
            })
            .catch((error) => next(error));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const parent = { $eq: null };
        const subscription = req.venzra.subscription._id;

        const query: any = { subscription, parent };

        if (req.query.primary) {
            query.primary = { $eq: true };
        }

        CategoryModel.find(query)
            .select('slug name featureImage')
            .populate({
                path: 'children',
                select: 'slug name',
                options: { sort: { name: 1 } }
            })
            .sort({ name: 1 })
            .then((categories) => res.status(200).send({ list: categories }))
            .catch((error) => next(error));
    }

}

export default new CategoryController().router;
