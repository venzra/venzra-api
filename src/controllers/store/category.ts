import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { CategoryModel, ImageModel } from '../../schemas';
import { config } from '../../config';

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
            .lean()
            .then((category) => ImageModel.populate(category, {
                path: 'children.featureImage',
                select: '_id name path'
            }))
            .then((category: any) => {
                if (!category) {
                    throw new NotFoundError();
                }
                category.featureImage = `https://${config.imageBucket}/${category.featureImage.path}`;
                if (category.parent) {
                    category.parent.featureImage = `https://${config.imageBucket}/${category.parent.featureImage.path}`;
                }
                if (category.children.length) {
                    category.children = category.children.map((child: any) => {
                        child.featureImage = `https://${config.imageBucket}/${child.featureImage.path}`;
                        return child;
                    });
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
            .lean()
            .then((categories: any) => {
                categories = categories.map((category: any) => {
                    if (category.featureImage) {
                        category.featureImage = `https://${config.imageBucket}/${category.featureImage.path}`;
                    }
                    return category;
                });
                res.status(200).send({ list: categories });
            })
            .catch((error) => next(error));
    }

}

export default new CategoryController().router;
