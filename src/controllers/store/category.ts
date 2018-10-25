import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { CategoryModel, ImageModel } from '../../schemas';

export class CategoryController {

    public router: Router;

    constructor() {
        this.router = Router();
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
            .select('slug name description featureImage parent children')
            .populate({
                path: 'featureImage',
                select: '_id name path'
            })
            .populate({
                path: 'parent',
                select: 'slug name featureImage',
                populate: {
                    path: 'featureImage',
                    select: '_id name path'
                }
            })
            .populate({
                path: 'children',
                select: 'slug name featureImage'
            })
            .then((category) => ImageModel.populate(category, {
                path: 'children.featureImage',
                select: '_id name path'
            }))
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
                path: 'featureImage',
                select: '_id name path'
            })
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
