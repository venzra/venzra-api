const { createHash } = require('crypto');
const moment = require('moment');
const { v4 } = require('uuid');

const config = require('../../config');
const databaseConnect = require('../../database');

const { mailer } = require('../../services/mailer.service');
const { security } = require('../../services/security.service');
const Accounts = require('../../models/accounts.schema');

const findOne = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    Accounts
        .findById(event.pathParameters.accountId)
        .select('_id identity terms status created updated')
        .then((account) => {
            const response = {
                statusCode: 200,
                headers: security.accessControl(event.headers),
                body: JSON.stringify(account)
            };
            return done(null, response);
        })
        .catch((err) => {
            const response = {
                statusCode: 404,
                headers: security.accessControl(event.headers),
                body: JSON.stringify(err)
            };
            return done(null, response);
        });
};

const createOne = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const body = JSON.parse(event.body);

    if (!body.acceptTerms) {
        const response = {
            statusCode: 400,
            headers: security.accessControl(event.headers),
            body: JSON.stringify({ error: 'Bad Request' })
        };
        return done(null, response);
    }

    const subject = 'Registration confirmation';
    const marketingUrl = config.marketingPortal;
    const managementUrl = config.managementPortal;
    const identity = (body.identity || '').toLowerCase();

    databaseConnect()
        .then(() => Accounts
            .findOne({ identity })
            .then((account) => {
                let expiry = 7;
                const terms = new Date();

                if (!account) {
                    account = new Accounts({ identity, terms });
                } else {
                    expiry = 2;
                    account.status = 'RECOVERY';
                }

                account.validation = {
                    key: createHash('sha256').update(v4()).digest('hex').substr(0, 16),
                    expires: new Date(terms.setDate(terms.getDate() + expiry))
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
        .catch(() => {
            const response = {
                statusCode: 400,
                headers: security.accessControl(event.headers),
                body: JSON.stringify({ error: 'Bad Request' })
            };
            return done(null, response);
        });
};

module.exports = { createOne, findOne };
