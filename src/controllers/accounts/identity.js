const { createHash } = require('crypto');
const moment = require('moment');
const { v4 } = require('uuid');

const config = require('../../config');
const databaseConnect = require('../../database');

const { mailer } = require('../../services/mailer.service');
const { security } = require('../../services/security.service');
const Accounts = require('../../models/accounts.schema');

const forgottenPassword = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const body = JSON.parse(event.body);

    const subject = 'Account recovery';
    const managementUrl = config.managementPortal;
    const identity = (body.identity || '').toLowerCase();

    databaseConnect()
        .then(() => Accounts
            .findOne({ identity })
            .then((account) => {
                if (!account) {
                    throw new Error(`No account for "${identity}"`);
                }

                let expiry = 2;
                const currentDate = new Date();

                account.status = 'RECOVERY';
                account.validation = {
                    key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
                    expires: new Date(currentDate.setDate(currentDate.getDate() + expiry))
                };

                return account.save();
            })
        )
        .then((account) => {
            const content = { subject, managementUrl, account };
            content.expires = moment(content.account.validation.expires).format('Do MMM YYYY [at] HH:mm');
            content.forgottenUrl = `${content.managementUrl}/forgotten`;
            content.recoveryUrl = `${content.managementUrl}/recovery/${content.account._id}?token=${content.account.validation.key}`;

            return mailer
                .send(
                    subject,
                    config.replyTo,
                    account.get('identity'),
                    'recovery',
                    content,
                    null
                )
                .then(() => account);
        })
        .then(() => {
            const response = {
                statusCode: 202,
                headers: security.accessControl(event.headers)
            };
            return done(null, response);
        })
        .catch(() => {
            const response = {
                statusCode: 202,
                headers: security.accessControl(event.headers)
            };
            return done(null, response);
        });
};

module.exports = { forgottenPassword };
