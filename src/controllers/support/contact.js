const config = require('../../config');
const { mailer } = require('../../services/mailer.service');

const sendEmail = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const body = JSON.parse(event.body);

    const errors = ['alias', 'emailAddress', 'reason', 'message'].map((key) => {
        if (!body[key]) {
            return `${key} required`;
        }
    }).filter(Boolean);

    if (errors.length) {
        const response = {
            statusCode: 400,
            headers: { 'Access-Control-Allow-Origin': process.env['CROSS_ORIGIN_REQUESTS'] },
            body: JSON.stringify({ errors })
        };
        return done(null, response);
    }

    const alias = body.alias;
    const emailAddress = body.emailAddress;
    const subject = body.reason;
    const message = body.message;

    mailer
        .send(
            subject,
            config.replyTo,
            config.contactEmail,
            'contact',
            { subject, alias, emailAddress, message },
            emailAddress
        )
        .then(() => {
            const response = {
                statusCode: 202,
                headers: { 'Access-Control-Allow-Origin': process.env['CROSS_ORIGIN_REQUESTS'] }
            };
            return done(null, response);
        })
        .catch((error) => {
            const response = {
                statusCode: 500,
                headers: { 'Access-Control-Allow-Origin': process.env['CROSS_ORIGIN_REQUESTS'] },
                body: JSON.stringify(error)
            };
            return done(null, response);
        });
};

module.exports = { sendEmail };
