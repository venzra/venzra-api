import * as parser from 'body-parser';
import * as stream from 'stream';

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

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/:imageId', this.findOne.bind(this));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        ImageModel
            .findOne({ _id: req.params.imageId, subscription: req.venzra.subscription._id })
            .select('_id name usage path size')
            .then((image: Image) => {
                if (!image) {
                    throw new NotFoundError();
                }
                res.status(200).send(image);
            })
            .catch((error) => next(error));
    }

}

export default new ImagesController().router;
