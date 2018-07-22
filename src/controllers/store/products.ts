import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { CategoryModel, ProductModel } from '../../schemas';

export class ProductsController {

    public router: Router;

    constructor() {
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.checkCategory.bind(this), this.findAll.bind(this));
        this.router.get('/:productSlug', this.findOne.bind(this));
    }

    checkCategory(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!req.query.category) {
            return next();
        }

        const slug = req.query.category;
        const subscription = req.venzra.subscription._id;

        CategoryModel
            .find({ subscription, slug })
            .select('_id')
            .populate({
                path: 'children',
                select: '_id'
            })
            .then((categories) => req.params.categories = categories.reduce((categoryList, category) => categoryList.concat(category.get('_id'), ...category.children.map((child) => child.get('_id'))), []))
            .then(() => next())
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const slug = req.params.productSlug;
        const subscription = req.venzra.subscription._id;
        const status = 'ACTIVE';

        ProductModel
            .findOne({ slug, subscription, status })
            .select('slug code displayName description featureImage promotionalImage previousPrice currentPrice')
            .then((product) => product ? res.status(200).send(product) : next(new NotFoundError()));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.subscription._id, status: 'ACTIVE' };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 24;

        let order: any = { displayName: 1 };

        if (req.params.categories) {
            searchParams.categories = { $in: req.params.categories };
        }

        if (req.query.search) {
            searchParams.$text = { $search: req.query.search };
            order = { score: { $meta: 'textScore' } };
        }

        ProductModel
            .count(searchParams).exec()
            .then((total) =>
                ProductModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $skip: skip },
                        { $limit: limit },
                        { $project: { slug: 1, code: 1, displayName: 1, promotionalImage: 1, previousPrice: 1, currentPrice: 1 } }
                    ])
                    .then((list) => res.status(200).send({ list, total, skip, limit }))
            )
            .catch((productError) => next(productError));
    }

}

export default new ProductsController().router;

