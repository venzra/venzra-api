import * as parser from 'body-parser';
import * as moment from 'moment';

import { createHash, pbkdf2Sync } from 'crypto';
import { Response, NextFunction, Router } from 'express';
import { encode } from 'jwt-simple';
import { v4 } from 'uuid';

import { AcceptedError, AuthenticationError, ValidationError, VenzraRequest } from '../../models';
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

    public registerRoutes() {
        this.router.use(parser.json({ type: 'application/json' }));

        this.router.get('/', this.identityService.validateAdmin.bind(this), this.identityService.getAccount.bind(this));
        this.router.post('/', this.recover.bind(this));
        this.router.post('/login', this.authorise.bind(this), this.tokenise.bind(this));
        this.router.post('/logout', this.identityService.validateAdmin.bind(this), this.logout.bind(this));
    }

    public async recover(req: VenzraRequest, res: Response, next: NextFunction) {
        const requestErrors = this.errorService.requiredFields(req.body, ['identity']);

        if (requestErrors.length) {
            return next(new ValidationError(requestErrors));
        }

        const identity = (req.body.identity).toLowerCase();

        const account = await AccountModel.findOne({ identity });

        if (!account) {
            return next(new AcceptedError(`Recovery not possible, no account for "${identity}"`));
        }

        let expiry = 8;

        account.status = 'RECOVERY';
        account.validation = {
            key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
            expires: moment().add(expiry, 'hours').toDate(),
        };

        await account.save();

        const subject = 'Account recovery';
        const managementUrl = config.managementPortal;
        const expires = moment(account.validation.expires).format('dddd, Do MMMM YYYY [at] HH:mm');
        const forgottenUrl = `${managementUrl}/forgotten`;
        const recoveryUrl = `${managementUrl}/recovery/${account._id}?token=${account.validation.key}`;

        const mailer = new MailService(subject, config.replyTo, [account.identity]);
        const content = { subject, managementUrl, account, expires, forgottenUrl, recoveryUrl };

        await mailer.send('recovery', content);

        res.status(202).send();
    }

    public async authorise(req: VenzraRequest, res: Response, next: NextFunction) {
        if (!req.body.identity || !req.body.password) {
            return next(new AuthenticationError(`Missing ${req.body.identity ? 'identity' : 'password'} credential`));
        }

        const identity = (req.body.identity || '').toLowerCase();
        const user = await AccountModel.findOne({ identity });

        if (!user) {
            return next(new AuthenticationError(`Account "${identity}" not found`));
        }

        switch (user.status) {
            case 'ACTIVE':
            case 'RECOVERY':
                break;
            case 'REGISTERED':
                return next(new AuthenticationError(`Account "${user.identity}" not activated`));
            case 'LOCKED':
                // TODO: Allow for timeout on account lock for new attempts
                return next(new AuthenticationError(`Account "${user.identity}" locked`));
            default:
                return next(new AuthenticationError(`Account "${user.identity}" state is ${user.status}`));
        }

        const password = pbkdf2Sync(req.body.password, user.password.salt, 10000, 256, 'sha512');

        if (user.password.secure === password.toString('base64')) {
            const token = {
                key: createHash('sha256').update(v4()).digest('hex').toString(),
                ip: req.ip,
                created: new Date(),
            };

            const changes = {
                $unset: { validation: 1 },
                $set: {
                    access: token,
                    lock: { failures: 0 },
                    status: 'ACTIVE',
                },
            };

            await user.update(changes).exec();
        } else {
            const changes = {
                $unset: { access: 1 },
                $set: {
                    'lock.ip': req.ip,
                    'lock.attempted': new Date(),
                },
                $inc: { 'lock.failures': 1 },
                status: (user.lock.failures >= 4 ? 'LOCKED' : user.status),
            };

            await user.update(changes).exec();
            return next(new AuthenticationError(`Password for "${user.identity}" incorrect`));
        }

        const account = await AccountModel.findById(user._id);
        Object.assign(req.venzra, { account });
        next();
    }

    public tokenise(req: VenzraRequest, res: Response, next: NextFunction) {
        const account = {
            _id: req.venzra.account._id,
            key: req.venzra.account.access.key,
            ip: req.venzra.account.access.ip,
        };
        const encoded = encode(account, config.secret, 'HS512');

        res.cookie('jwt', encoded, { httpOnly: true, secure: config.secure });
        res.status(202).send();
    }

    public async logout(req: VenzraRequest, res: Response, next: NextFunction) {
        await req.venzra.account.update({ $unset: { access: 1 } }).exec();
        res.clearCookie('jwt');
        res.status(202).send();
    }

}

export default new IdentityController().router;
