import * as fs from 'fs';
import * as parser from 'body-parser';
import * as path from 'path';

import { Request, Response, NextFunction, Router } from 'express';

import { NotFoundError, ValidationError } from '../../models';
import { ErrorService, MailService } from '../../services';

import { config } from '../../config';

export class SupportController {

    public router: Router;

    private errorService: ErrorService;

    constructor() {
        this.router = Router();
        this.errorService = new ErrorService();
        this.registerRoutes();
    }

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/contact', this.contact.bind(this));
        this.router.get('/guides/:section/:page', this.guide.bind(this));
    }

    public async contact(req: Request, res: Response, next: NextFunction) {
        const requestErrors = this.errorService.requiredFields(req.body, ['alias', 'emailAddress', 'reason', 'message']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const subject = req.body.reason;
        const alias = req.body.alias;
        const emailAddress = req.body.emailAddress;
        const message = req.body.message;

        const mailer = new MailService(subject, config.replyTo, [config.contactEmail], [emailAddress]);
        const content = { subject, alias, emailAddress, message };

        try {
            mailer.send('support', content);
            res.status(202).send();
        } catch (error) {
            next(error);
        }
    }

    public async guide(req: Request, res: Response, next: NextFunction) {
        const documentPath = path.join(__dirname, '..', '..', 'docs', req.params.section, `${req.params.page}.md`);

        fs.readFile(documentPath, 'utf-8', (err, data) => {
            if (err) {
                return next(new NotFoundError());
            }

            let result: { [key: string]: string } = {};
            const liquid = data.split('-----');

            if (liquid.length > 1) {
                const meta = liquid[0].split('\n');
                meta.forEach((description) => {
                    const pos = description.indexOf('=');
                    if (pos > 0) {
                        const field = description.substr(0, pos - 1).trim();
                        result[field] = description.substr(pos + 1).trim();
                    }
                });
                result.content = liquid[1].trim();
            } else {
                result.content = liquid[0].trim();
            }

            res.status(200).send(result);
        });
    }
}

export default new SupportController().router;
