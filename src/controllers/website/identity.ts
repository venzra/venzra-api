import * as parser from 'body-parser';
import * as moment from 'moment';

import { createHash } from 'crypto';
import { Request, Response, NextFunction, Router } from 'express';
import { v4 } from 'uuid';

import { NotFoundError, ValidationError } from '../../models';
import { AccountModel } from '../../schemas';
import { ErrorService, MailService } from '../../services';

import { config } from '../../config';

export class IdentityController {

    public router: Router;

    private errorService: ErrorService;

    constructor() {
        this.router = Router();
        this.errorService = new ErrorService();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/', this.create.bind(this), this.findOne.bind(this));
    }

    create(req: Request, res: Response, next: NextFunction): void {
        const requestErrors = this.errorService.requiredFields(req.body, ['identity', 'acceptTerms']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const identity = (req.body.identity).toLowerCase();

        AccountModel
            .findOne({ identity })
            .then((account) => {
                let expiry = 7;
                const terms = new Date();

                if (!account) {
                    account = new AccountModel({ identity, terms });
                } else {
                    expiry = 2;
                    account.status = 'RECOVERY';
                }

                account.validation = {
                    key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
                    expires: moment(terms).add(expiry, 'days').toDate()
                };

                return account.save();
            })
            .then((account) => {
                const subject = 'Registration confirmation';
                const marketingUrl = config.marketingPortal;
                const managementUrl = config.managementPortal;
                const expires: string = moment(account.validation.expires).format('dddd, Do MMMM YYYY [at] HH:mm');
                const validationUrl: string = `${managementUrl}/activate/${account._id}?token=${account.validation.key}`;

                const mailer = new MailService(subject, config.replyTo, [account.identity]);
                const content = { subject, marketingUrl, managementUrl, account, expires, validationUrl };

                return mailer
                    .send('registration', content)
                    .then(() => account);
            })
            .then((account) => {
                req.params.accountId = account.id;
                return next();
            })
            .catch((error) => next(new ValidationError([error.message])));
    }

    findOne(req: Request, res: Response, next: NextFunction): void {
        AccountModel
            .findById(req.params.accountId)
            .select('_id identity terms status created updated')
            .then((account) => res.status(200).send(account))
            .catch(() => next(new NotFoundError()));
    }

}

export default new IdentityController().router;
