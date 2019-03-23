import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Image, NotFoundError, PatchRequest, Product, VenzraRequest } from '../../models';
import { CategoryModel, ProductModel, ProductHistoryModel } from '../../schemas';
import { IdentityService } from '../../services';
import { config } from '../../config';

export class ProductsController {

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
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createProduct.bind(this), this.findOne.bind(this));
        this.router.get('/:productId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:productId', this.identityService.validateAdmin.bind(this), this.updateProduct.bind(this), this.findOne.bind(this));
    }

    public async createProduct(req: VenzraRequest, res: Response, next: NextFunction) {
        const product = new ProductModel({
            subscription: req.venzra.account.subscription._id,
            code: req.body.code,
            displayName: req.body.displayName,
            description: req.body.description,
            promotionalImage: req.body.promotionalImage,
            previousPrice: req.body.previousPrice,
            currentPrice: req.body.currentPrice,
            status: req.body.status,
        });

        try {
            const result = await product.save();
            req.params.productId = result._id;
            next();
        } catch (error) {
            next(error);
        }
    }

    public async updateProduct(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.productId;
        const subscription = req.venzra.account.subscription._id;

        const product = await ProductModel
            .findOne({ _id, subscription })
            .populate({ path: 'categories' })
            .populate({ path: 'history' });

        if (!product) {
            return next(new NotFoundError());
        }

        if (!(req.body instanceof Array)) {
            return next();
        }

        const update = (<Array<PatchRequest>>req.body).reduce(async (promise, operation) => {
            await promise;

            switch (operation.op) {
                case 'replace':
                    switch (operation.path) {
                        case 'displayName':
                        case 'description':
                        case 'promotionalImage':
                        case 'previousPrice':
                        case 'currentPrice':
                        case 'status':
                            const history = new ProductHistoryModel({
                                account: req.venzra.account._id,
                                field: operation.path,
                                previous: product.get(operation.path),
                                next: operation.value,
                            });

                            await history.save();
                            product.history.unshift(history);
                            product.set(operation.path, operation.value);
                            break;
                        case 'categories':
                            if (operation.value instanceof Array) {
                                const removeCategories = product.categories.filter((category) => !operation.value.includes(category._id));

                                await Promise.all(removeCategories.map((category) => category.update({ $pull: { products: product._id } })));
                                const result = await Promise.all(
                                    operation.value
                                        .map(async (categoryId: string) => {
                                            const category = await CategoryModel.findOneAndUpdate({
                                                _id: categoryId,
                                                subscription,
                                                parent: { $ne: null },
                                            }, {
                                                $addToSet: { products: product._id },
                                            });
                                            return category ? category._id : false;
                                        }),
                                );
                                product.set(operation.path, result.filter(Boolean));
                            }
                            break;
                    }
            }
        }, Promise.resolve());

        try {
            await update;
            await product.save();
            next();
        } catch (error) {
            next(error);
        }
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.productId;
        const subscription = req.venzra.account.subscription._id;

        const product = await ProductModel
            .findOne({ _id, subscription })
            .select('slug code displayName description promotionalImage previousPrice currentPrice status created updated')
            .populate({
                path: 'promotionalImage',
                select: '_id name path',
            })
            .populate({
                path: 'categories',
                select: '_id name',
                populate: {
                    path: 'parent',
                    select: '_id name',
                },
            })
            .populate({
                path: 'history',
                select: '-_id -__v',
                populate: {
                    path: 'account',
                    select: 'identity',
                },
            })
            .lean();

        if (!product) {
            return next(new NotFoundError());
        }

        product.promotionalImage = `https://${config.imageBucket}/${(<Image>product.promotionalImage).path}`;
        res.status(200).send(product);
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.account.subscription._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 20;
        let order: { [key: string]: number } = {};

        if (req.query.search) {
            searchParams.code = new RegExp(req.query.search, 'i');
        }

        if (req.query.status) {
            searchParams.status = req.query.status.toUpperCase();
        }

        switch (req.query.sort) {
            case 'displayName':
            case 'currentPrice':
                order[req.query.sort] = (req.query.direction === 'desc') ? -1 : 1;
                break;
            default:
                order = { created: req.query.direction === 'asc' ? 1 : -1 };
        }

        const total = await ProductModel.countDocuments(searchParams).exec();

        const list = await ProductModel
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
                        as: 'promotionalImage',
                    },
                },
                {
                    $project: {
                        slug: 1,
                        code: 1,
                        displayName: 1,
                        promotionalImage: { $concat: ['https://', config.imageBucket, '/', { $arrayElemAt: ['$promotionalImage.path', 0] }] },
                        previousPrice: 1,
                        currentPrice: 1,
                        status: 1,
                        created: 1,
                    },
                },
            ]);

        res.status(200).send({ list, total, skip, limit });
    }

}

export default new ProductsController().router;
