import * as parser from 'body-parser';
import * as moment from 'moment';

import { createHash, pbkdf2Sync } from 'crypto';
import { Response, NextFunction, Router } from 'express';
import { encode } from 'jwt-simple';
import { v4 } from 'uuid';

import { Account, AcceptedError, AuthenticationError, ValidationError, VenzraRequest } from '../../models';
import { AccountModel } from '../../schemas';
import { ErrorService, IdentityService, MailService } from '../../services';

import { config } from '../../config';

export class IdentityController {

    public router: Router;

    private identityService: IdentityService;

    private errorService: ErrorService;

    constructor() {
        this.router = Router();
        this.errorService = new ErrorService();
        this.identityService = new IdentityService();
        this.registerRoutes();
    }

    registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.identityService.getAccount.bind(this));
        this.router.post('/', this.recover.bind(this));
        this.router.post('/login', this.authorise.bind(this), this.tokenise.bind(this));
    }

    recover(req: VenzraRequest, res: Response, next: NextFunction): void {
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

    authorise(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!req.body.identity || !req.body.password) {
            return next(new AuthenticationError(`Missing ${req.body.identity ? 'identity' : 'password'} credential`));
        }

        const identity = (req.body.identity || '').toLowerCase();

        AccountModel.findOne({ identity })
            .then((account: Account) => {
                if (!account) {
                    throw new AuthenticationError(`Account "${identity}" not found`);
                }

                switch (account.status) {
                    case 'ACTIVE':
                    case 'RECOVERY':
                        break;
                    case 'REGISTERED':
                        throw new AuthenticationError(`Account "${account.identity}" not activated`);
                    case 'LOCKED':
                        // TODO: Allow for timeout on account lock for new attempts
                        throw new AuthenticationError(`Account "${account.identity}" locked`);
                    default:
                        throw new AuthenticationError(`Account "${account.identity}" state is ${account.status}`);
                }

                const password = pbkdf2Sync(req.body.password, account.password.salt, 10000, 256, 'sha512');

                if (account.password.secure === password.toString('base64')) {
                    const token = {
                        key: createHash('sha256').update(v4()).digest('hex').toString(),
                        ip: req.ip,
                        created: new Date()
                    };

                    const changes = {
                        $unset: { validation: 1 },
                        $set: {
                            access: token,
                            lock: { failures: 0 },
                            status: 'ACTIVE'
                        }
                    };

                    return account
                        .update(changes)
                        .exec()
                        .then(() => account);
                } else {
                    const changes = {
                        $unset: { access: 1 },
                        $set: {
                            'lock.ip': req.ip,
                            'lock.attempted': new Date()
                        },
                        $inc: { 'lock.failures': 1 },
                        status: (account.lock.failures >= 4 ? 'LOCKED' : account.status)
                    };

                    return account
                        .update(changes)
                        .exec()
                        .then(() => {
                            throw new AuthenticationError(`Password for "${account.identity}" incorrect`);
                        })
                        .then(() => account);
                }
            })
            .then((account: Account) => {
                return AccountModel.findById(account._id).then((account: Account) => {
                    Object.assign(req.venzra, { account });
                    next();
                })
            })
            .catch((error: any) => next(error));
    }

    tokenise(req: VenzraRequest, res: Response, next: NextFunction) {
        const account = {
            _id: req.venzra.account._id,
            key: req.venzra.account.access.key,
            ip: req.venzra.account.access.ip
        };
        const encoded = encode(account, config.secret, 'HS512');

        res.cookie('jwt', encoded, { httpOnly: true, secure: config.secure });
        res.status(202).send();
    }

}

export default new IdentityController().router;
