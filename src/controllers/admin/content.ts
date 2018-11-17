import * as parser from 'body-parser';

import { Response, NextFunction, Router } from 'express';

import { Content, PatchRequest, VenzraRequest } from '../../models';
import { ContentModel } from '../../schemas';
import { IdentityService } from '../../services';

export class ContentController {

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

        this.router.get('/:contentUsage', this.identityService.validateAdmin.bind(this), this.findOne.bind(this));
        this.router.patch('/:contentUsage', this.identityService.validateAdmin.bind(this), this.update.bind(this), this.findOne.bind(this));
    }

    update(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription._id;
        const usage = req.params.contentUsage;

        ContentModel
            .findOne({ subscription, usage })
            .then((content: Content) => {
                if (!(req.body instanceof Array)) {
                    return;
                }

                if (!content) {
                    content = new ContentModel({ subscription, usage });
                }

                (<Array<PatchRequest>>req.body).forEach((operation) => {
                    switch (operation.op) {
                        case 'replace':
                            switch (operation.path) {
                                case 'content':
                                    content.set(operation.path, operation.value);
                                    break;
                            }
                    }
                });

                return content.save();
            })
            .then(() => next())
            .catch((error) => next(error));
    }

    findOne(req: VenzraRequest, res: Response, next: NextFunction) {
        const subscription = req.venzra.account.subscription._id;
        const usage = req.params.contentUsage;

        ContentModel
            .findOne({ subscription, usage })
            .select('content usage created updated')
            .then((content) => res.status(200).send(content))
            .catch((error) => next(error));
    }

}

export default new ContentController().router;
