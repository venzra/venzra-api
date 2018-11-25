import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { ShippingModel } from '../../schemas';
import { IdentityService } from '../../services';

export class ShippingController {

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
        this.router.post('/', this.identityService.validateAdmin.bind(this), this.createShipping.bind(this), this.findOne.bind(this));
        this.router.get('/:shippingId', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.delete('/:shippingId', this.identityService.validateAdmin.bind(this), this.removeOne.bind(this));
    }

    createShipping(req: VenzraRequest, res: Response, next: NextFunction) {
        const shipping = new ShippingModel({
            subscription: req.venzra.account.subscription._id,
            displayName: req.body.displayName,
            cartMinimum: req.body.cartMinimum,
            cartMaximum: req.body.cartMaximum,
            currentPrice: req.body.currentPrice,
            shipmentTime: req.body.shipmentTime
        });

        shipping.save()
            .then((result) => {
                req.params.shippingId = result._id;
                next();
            })
            .catch((shippingError) => next(shippingError));
    }

    removeOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.shippingId;
        const subscription = req.venzra.account.subscription._id;

        ShippingModel.findOneAndRemove({ _id, subscription })
            .then((result) => result ? res.status(202).send() : next(new NotFoundError()))
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const _id = req.params.shippingId;
        const subscription = req.venzra.account.subscription._id;

        ShippingModel
            .findOne({ _id, subscription })
            .select('displayName cartMinimum cartMaximum currentPrice shipmentTime created updated')
            .then((shipping) => shipping ? res.status(200).send(shipping) : next(new NotFoundError()))
            .catch((error) => next(error));
    }

    findAll(req: VenzraRequest, res: Response, next: NextFunction) {
        const searchParams: any = { subscription: req.venzra.account.subscription._id };
        const skip = parseInt(req.query.skip, 10) || 0;
        const limit = parseInt(req.query.limit, 10) || 20;
        let order: any = {};

        switch (req.query.sort) {
            case 'currentPrice':
                order[req.query.sort] = (req.query.direction === 'asc') ? 1 : -1;
                break;
            default:
                order = { currentPrice: req.query.direction === 'desc' ? -1 : 1 };
        }

        order.shipmentTime = 1;

        ShippingModel
            .count(searchParams).exec()
            .then((total) =>
                ShippingModel
                    .aggregate([
                        { $match: searchParams },
                        { $sort: order },
                        { $skip: skip },
                        { $limit: limit },
                        {
                            $project: {
                                displayName: 1,
                                cartMinimum: 1,
                                cartMaximum: 1,
                                currentPrice: 1,
                                shipmentTime: 1,
                                created: 1
                            }
                        }
                    ])
                    .then((list) => res.status(200).send({ list, total, skip, limit }))
            )
            .catch((shippingError) => next(shippingError));
    }

}

export default new ShippingController().router;
