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

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/', this.create.bind(this), this.findOne.bind(this));
    }

    public async create(req: Request, res: Response, next: NextFunction) {
        const requestErrors = this.errorService.requiredFields(req.body, ['identity', 'acceptTerms']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const identity = (req.body.identity).toLowerCase();

        let account;
        account = await AccountModel.findOne({ identity });

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
            expires: moment(terms).add(expiry, 'days').toDate(),
        };

        try {
            await account.save();
        } catch (error) {
            next(new ValidationError([error.message]));
        }

        const subject = 'Registration confirmation';
        const marketingUrl = config.marketingPortal;
        const managementUrl = config.managementPortal;
        const expires: string = moment(account.validation.expires).format('dddd, Do MMMM YYYY [at] HH:mm');
        const validationUrl: string = `${managementUrl}/activate/${account._id}?token=${account.validation.key}`;

        const mailer = new MailService(subject, config.replyTo, [account.identity]);
        const content = { subject, marketingUrl, managementUrl, account, expires, validationUrl };

        try {
            await mailer.send('registration', content);
            req.params.accountId = account.id;
            next();
        } catch (error) {
            next(error);
        }
    }

    public async findOne(req: Request, res: Response, next: NextFunction) {
        const account = await AccountModel
            .findById(req.params.accountId)
            .select('_id identity terms status created updated');

        if (!account) {
            return next(new NotFoundError());
        }

        res.status(200).send(account);
    }

}

export default new IdentityController().router;
