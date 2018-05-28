const { createHash } = require('crypto');
const moment = require('moment');
const { v4 } = require('uuid');

const config = require('../../config');
const databaseConnect = require('../../database');

const { mailer } = require('../../services/mailer.service');
const Accounts = require('../../models/accounts.schema');

const findOne = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    Accounts
        .findById(event.pathParameters.accountId)
        .select('_id identity status created updated')
        .then((account) => done(null, { statusCode: 200, body: JSON.stringify(account) }))
        .catch((err) => done(null, { statusCode: 404, body: JSON.stringify(err) }));
};

const createOne = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const body = JSON.parse(event.body);

    const subject = 'Registration confirmation';
    const marketingUrl = config.marketingPortal;
    const managementUrl = config.managementPortal;

    const identity = (body.identity || '').toLowerCase();

    databaseConnect()
        .then(() => Accounts
            .findOne({ identity })
            .then((account) => {
                const date = new Date();

                let expiry = 7;

                if (!account) {
                    account = new Accounts({ identity });
                } else {
                    expiry = 2;
                    account.status = 'RECOVERY';
                }

                account.validation = {
                    key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
                    expires: new Date(date.setDate(date.getDate() + expiry))
                };

                return account.save();
            })
        )
        .then((account) => {
            const content = { subject, marketingUrl, managementUrl, account };
            content.expires = moment(content.account.validation.expires).format('Do MMM YYYY [at] HH:mm');
            content.validationUrl = `${content.managementUrl}/activate/${content.account._id}?token=${content.account.validation.key}`;

            return mailer
                .send(
                    subject,
                    config.replyTo,
                    account.get('identity'),
                    'registration',
                    content,
                    null
                )
                .then(() => account);
        })
        .then((account) => {
            event.pathParameters = { accountId: account._id };
            return findOne(event, context, done);
        })
        .catch(() => done(null, { statusCode: 400, body: JSON.stringify({ error: 'Bad Request' }) }));
};

module.exports = { createOne, findOne };
