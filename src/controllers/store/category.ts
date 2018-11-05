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

        // CategoryModel
        //     .aggregate([
        //         { $match: { slug, subscription } },
        //         { $lookup: { from: 'images', localField: 'featureImage', foreignField: '_id', as: 'featureImage' } },
        //         { $unwind: '$featureImage' },
        //         { $lookup: { from: 'categories', localField: 'parent', foreignField: '_id', as: 'parent' } },
        //         { $unwind: '$parent' },
        //         { $lookup: { from: 'categories', localField: 'children', foreignField: '_id', as: 'children' } },
        //         {
        //             $lookup: {
        //                 from: 'images',
        //                 localField: 'parent.featureImage',
        //                 foreignField: '_id',
        //                 as: 'parent.featureImage'
        //             }
        //         },
        //         { $unwind: '$parent.featureImage' },
        //         {
        //             $lookup: {
        //                 from: 'images',
        //                 localField: 'children.featureImage',
        //                 foreignField: '_id',
        //                 as: 'children.featureImage'
        //             }
        //         },
        //         { $unwind: { path: '$children.featureImage', preserveNullAndEmptyArrays: true } },
        //         {
        //             $project: {
        //                 _id: 1,
        //                 name: 1,
        //                 slug: 1,
        //                 description: 1,
        //                 featureImage: { $concat: ['https://', config.imageBucket, '/', '$featureImage.path'] },
        //                 parent: {
        //                     _id: 1,
        //                     name: 1,
        //                     slug: 1,
        //                     featureImage: { $concat: ['https://', config.imageBucket, '/', '$parent.featureImage.path'] }
        //                 },
        //                 children: {
        //                     _id: 1,
        //                     name: 1,
        //                     slug: 1,
        //                     featureImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$children.featureImage.path', 0] }] }
        //                 }
        //             }
        //         },
        //         {
        //             $group: {
        //                 _id: '$_id',
        //                 name: { '$first': '$name' },
        //                 slug: { '$first': '$slug' },
        //                 description: { '$first': '$description' },
        //                 featureImage: { '$first': '$featureImage' },
        //                 parent: { '$first': '$parent' },
        //                 children: { $push: '$children' }
        //             }
        //         }
        //     ])
        //     .then((categories) => {
        //         console.log(categories);
        //         categories = categories.map((category) => {
        //             category.children = category.children.filter((child: any) => child._id !== undefined);
        //             return category;
        //         });
        //         console.log(categories);
        //         return categories;
        //     })
        //     .then((categories) => categories.length ? res.status(200).send(categories[0]) : next(new NotFoundError()))
        //     .catch((category) => next(category));

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
