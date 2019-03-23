import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { NotFoundError, VenzraRequest } from '../../models';
import { ContentModel } from '../../schemas';

import { defaultTerms } from '../../docs/default-terms';

export class ContentController {

    public router: Router;

    constructor() {
        this.router = Router();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/:contentUsage', this.getContent.bind(this));
    }

    public async getContent(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.subscription._id;
        const usage = req.params.contentUsage.toUpperCase();

        if (usage === 'TERMS') {
            return res.status(200).send({ content: defaultTerms });
        }

        const content = await ContentModel.findOne({ subscription, usage }).select('content');

        if (!content) {
            return next(new NotFoundError());
        }

        res.status(200).send(content);
    }
}

export default new ContentController().router;
