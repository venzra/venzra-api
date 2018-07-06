import * as parser from 'body-parser';
import * as zxcvbn from 'zxcvbn';

import { Request, Response, NextFunction, Router } from 'express';

export class ValidationController {

    public router: Router;

    constructor() {
        this.registerRoutes();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/password', this.password.bind(this));
    }

    password(req: Request, res: Response, next: NextFunction) {
        const { score, feedback } = zxcvbn(req.body.password || '');

        const message = feedback.warning ? feedback.warning : feedback.suggestions[0];

        res.status(200).send({ score, message });
    }

}

export default new ValidationController().router;
