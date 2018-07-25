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
            .select('_id name usage size')
            .then((image: Image) => {
                if (!image) {
                    throw new NotFoundError();
                }

                return Promise.resolve()
                    .then(() => {
                        const Bucket = config.imageBucket;
                        const Key = `${req.venzra.subscription._id}/${image.usage}/${image._id}`;

                        const params = { Bucket, Key };

                        return this.awsClient.headObject(params).promise();
                    })
                    .then((meta) => res.setHeader('content-type', meta.ContentType || 'application/octet-stream'))
                    .then(() => {
                        const Bucket = config.imageBucket;
                        const Key = `${req.venzra.subscription._id}/${image.usage}/${image._id}`;

                        const params = { Bucket, Key };

                        return this.awsClient.getObject(params).createReadStream();
                    })
                    .then((result: stream.Readable) => result.pipe(res));
            })
            .catch((error) => next(error));
    }

}

export default new ImagesController().router;
