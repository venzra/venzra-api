import * as parser from 'body-parser';
import * as moment from 'moment';

import { createHash } from 'crypto';
import { Request, Response, NextFunction, Router } from 'express';
import { v4 } from 'uuid';

import { AcceptedError, ValidationError } from '../../models';
import { AccountModel } from '../../schemas';
import { ErrorService, MailService } from '../../services';

import { config } from '../../config';

export class IdentityController {

    public router: Router;

    private errorService: ErrorService;

    constructor() {
        this.registerRoutes();
        this.errorService = new ErrorService();
    }

    registerRoutes() {
        this.router = Router();
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.post('/', this.recover.bind(this));
    }

    recover(req: Request, res: Response, next: NextFunction): void {
        const requestErrors = this.errorService.requiredFields(req.body, ['identity']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const identity = (req.body.identity).toLowerCase();

        AccountModel
            .findOne({ identity })
            .then((account) => {
                if (!account) {
                    throw new Error(`Recovery not possible, no account for "${identity}"`);
                }

                let expiry = 8;

                account.status = 'RECOVERY';
                account.validation = {
                    key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
                    expires: moment().add(expiry, 'hours').toDate()
                };

                return account.save();
            })
            .then((account) => {
                const subject = 'Account recovery';
                const managementUrl = config.managementPortal;
                const expires = moment(account.validation.expires).format('dddd, Do MMMM YYYY [at] HH:mm');
                const forgottenUrl = `${managementUrl}/forgotten`;
                const recoveryUrl = `${managementUrl}/recovery/${account._id}?token=${account.validation.key}`;

                const mailer = new MailService(subject, config.replyTo, [account.identity]);
                const content = { subject, managementUrl, account, expires, forgottenUrl, recoveryUrl };

                return mailer.send('recovery', content);
            })
            .then(() => res.status(202).send())
            .catch((err) => next(new AcceptedError(err.message)));
    }

}

export default new IdentityController().router;
