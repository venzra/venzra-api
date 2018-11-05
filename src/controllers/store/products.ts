import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { CategoryModel, ImageModel, LocationModel, ProductModel } from '../../schemas';
import { config } from '../../config';

export class ProductsController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    registerRoutes() {
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
            .aggregate([
                { $match: { slug, subscription, status } },
                { $lookup: { from: 'images', localField: 'promotionalImage', foreignField: '_id', as: 'fullImage' } },
                {
                    $project: {
                        slug: 1,
                        code: 1,
                        displayName: 1,
                        description: 1,
                        promotionalImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$fullImage.path', 0] }] },
                        previousPrice: 1,
                        currentPrice: 1
                    }
                }
            ])
            .then((products) => products.length ? res.status(200).send(products[0]) : next(new NotFoundError()));
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
                        {
                            $lookup: {
                                from: 'images',
                                localField: 'promotionalImage',
                                foreignField: '_id',
                                as: 'promotionalImage'
                            }
                        },
                        {
                            $project: {
                                slug: 1,
                                code: 1,
                                displayName: 1,
                                promotionalImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$promotionalImage.path', 0] }] },
                                previousPrice: 1,
                                currentPrice: 1
                            }
                        }
                    ])
                    .then((list) => res.status(200).send({ list, total, skip, limit }))
            )
            .catch((error) => next(error));

        // ProductModel
        //     .count(searchParams).exec()
        //     .then((total) =>
        //         ProductModel
        //             .aggregate([
        //                 { $match: searchParams },
        //                 { $sort: order },
        //                 { $skip: skip },
        //                 { $limit: limit },
        //                 {
        //                     $project: {
        //                         slug: 1,
        //                         code: 1,
        //                         displayName: 1,
        //                         promotionalImage: 1,
        //                         previousPrice: 1,
        //                         currentPrice: 1
        //                     }
        //                 }
        //             ])
        //             .then((result) => ImageModel.populate(result, {
        //                 path: 'promotionalImage',
        //                 select: '_id name path'
        //             }))
        //             .then((list) => res.status(200).send({ list, total, skip, limit }))
        //     )
        //     .catch((productError) => next(productError));
    }

}

export default new ProductsController().router;

