import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';
import { S3 } from 'aws-sdk';

import { Image, NotFoundError, VenzraRequest } from '../../models';
import { ImageModel } from '../../schemas';

import { config } from '../../config';

export class ImagesController {

    private awsClient: S3;

    public router: Router;

    constructor() {
        this.router = Router();
        this.awsClient = new S3({ region: 'eu-west-1' });
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/:imageId([0-9a-f]{24})', this.findOne.bind(this));
    }

    public async findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const image = await ImageModel
            .findOne({ _id: req.params.imageId, subscription: req.venzra.subscription._id })
            .select('_id name usage path size');

        if (!image) {
            return next(new NotFoundError());
        }
        image.path = `https://${config.imageBucket}/${image.path}`;
        res.status(200).send(image);
    }

}

export default new ImagesController().router;
