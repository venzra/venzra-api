import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, PatchRequest, VenzraRequest } from '../../models';
import { CategoryModel, ImageModel } from '../../schemas';
import { IdentityService } from '../../services';

import { config } from '../../config';

export class CategoryController {

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
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createCategory.bind(this), this.findOne.bind(this));
        this.router.get('/summary', this.identityService.validateAdmin.bind(this), this.getSummary.bind(this));
        this.router.get('/:categoryId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:categoryId', this.identityService.validateAdmin.bind(this), this.updateCategory.bind(this), this.findOne.bind(this));
        this.router.delete('/:categoryId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    public async createCategory(req: VenzraRequest, res: Response, next: NextFunction) {
        const category = new CategoryModel({
            subscription: req.venzra.account.subscription._id,
            name: req.body.name,
            description: req.body.description,
            primary: req.body.primary,
            featureImage: req.body.featureImage,
        });

        if (req.body.parent && !req.body.primary) {
            category.parent = req.body.parent;
        }

        if (category.parent) {
            const _id = category.parent;
            const subscription = req.venzra.account.subscription._id;

            const parent = await CategoryModel.findOne({ _id, subscription });

            if (!parent) {
                return next(new NotFoundError());
            }

            const result = await category.save();
            parent.children.push(result);

            try {
                await parent.save();
            } catch (error) {
                return next(error);
            }
        } else {
            try {
                await category.save();
            } catch (error) {
                return next(error);
            }
        }

        req.params.categoryId = category._id;
        next();
    }

    public async updateCategory(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.categoryId;
        const subscription = req.venzra.account.subscription._id;

        const category = await CategoryModel.findOne({ _id, subscription }).populate('parent');

        if (!category) {
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
                        case 'primary':
                            if (!category.parent) {
                                category.set(operation.path, operation.value);
                            }
                            break;
                        case 'parent':
                            if (category.children.length === 0) {
                                const parent = await CategoryModel.findOne({
                                    _id: operation.value,
                                    subscription: subscription,
                                });
                                if (!parent) {
                                    throw new NotFoundError();
                                }
                                await parent.update({ $addToSet: { children: category._id } });

                                if (category.parent) {
                                    const parent = category.parent;
                                    await parent.update({ $pull: { children: category._id } });
                                }

                                category.set(operation.path, operation.value);
                            }
                            break;
                        case 'name':
                        case 'description':
                        case 'featureImage':
                            category.set(operation.path, operation.value);
                    }
            }
        }, Promise.resolve());

        try {
            await update;
            await category.save();
            next();
        } catch (error) {
            next(error);
        }
    }

    public async removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.categoryId;
        const subscription = req.venzra.account.subscription._id;

        const category = await CategoryModel.findOne({ _id, subscription });
        if (!category) {
            return next(new NotFoundError());
        }

        if (category.parent) {
            await CategoryModel
                .findOneAndUpdate(
                    { _id: category.parent, subscription },
                    { $pull: { children: category._id } },
                );
        } else if (category.children.length) {
            await Promise.all(category.children
                .map(
                    async (child) => await CategoryModel.findOneAndUpdate(
                        { _id: child, subscription },
                        { $unset: { parent: 1 } },
                    ),
                ),
            );
        }

        await category.remove();
        res.status(202).send();
        next();
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.categoryId;
        const subscription = req.venzra.account.subscription._id;

        const category = await CategoryModel
            .findOne({ _id, subscription })
            .select('slug name description featureImage parent primary created updated')
            .populate({
                path: 'featureImage',
                select: '_id name path',
            })
            .populate({
                path: 'parent',
                select: 'slug name featureImage primary created updated',
                populate: {
                    path: 'featureImage',
                    select: '_id name path',
                },
            })
            .populate({
                path: 'children',
                select: 'slug name featureImage primary created updated',
                populate: {
                    path: 'featureImage',
                    select: '_id name path',
                },
            })
            .populate({
                path: 'products',
                select: '_id code displayName promotionalImage status created updated',
                populate: {
                    path: 'promotionalImage',
                    select: '_id name path',
                },
            })
            .lean();

        if (!category) {
            return next(new NotFoundError());
        }
        if (category.featureImage) {
            category.featureImage = `https://${config.imageBucket}/${category.featureImage.path}`;
        }
        if (category.parent && category.parent.featureImage) {
            category.parent.featureImage = `https://${config.imageBucket}/${category.parent.featureImage.path}`;
        }
        if (category.children.length) {
            category.children = category.children.map((child: any) => {
                if (child.featureImage) {
                    child.featureImage = `https://${config.imageBucket}/${child.featureImage.path}`;
                }
                return child;
            });
        }
        if (category.products.length) {
            category.products = category.products.map((product: any) => {
                product.promotionalImage = `https://${config.imageBucket}/${product.promotionalImage.path}`;
                return product;
            });
        }
        res.status(200).send(category);
    }

    public async findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.account.subscription._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 20;
        let order: any = {};

        if (req.query.search) {
            searchParams.name = new RegExp(req.query.search, 'i');
        }

        if (req.query.parent) {
            searchParams.parent = { $eq: null };
        }

        switch (req.query.sort) {
            case 'name':
            case 'created':
                order[req.query.sort] = (req.query.direction === 'desc') ? -1 : 1;
                break;
            default:
                order = { name: req.query.direction === 'desc' ? -1 : 1 };
        }

        const total = await CategoryModel.count(searchParams).exec();
        const result = await CategoryModel
            .aggregate([
                { $match: searchParams },
                { $sort: order },
                { $skip: skip },
                { $limit: limit },
                {
                    $project: {
                        slug: 1,
                        name: 1,
                        featureImage: 1,
                        primary: 1,
                        parent: 1,
                        children: { $size: { '$ifNull': ['$children', []] } },
                        products: { $size: { '$ifNull': ['$products', []] } },
                        created: 1,
                    },
                },
            ]);

        const list = await ImageModel.populate(result, {
            path: 'featureImage',
            select: '_id name usage path',
        });

        res.status(200).send({ list, total, skip, limit });
    }

    public async getSummary(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams = { subscription: req.venzra.account.subscription._id, parent: { $eq: null } };

        const categories = await CategoryModel.find(searchParams)
            .select('_id name')
            .populate({
                path: 'children',
                select: '_id name',
                options: { sort: { name: 1 } },
            })
            .sort({ name: 1 });

        res.status(200).send({ list: categories });
    }

}

export default new CategoryController().router;
