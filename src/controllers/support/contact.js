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
        return done(null, { statusCode: 400, body: JSON.stringify({ errors }) });
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
        .then(() => done(null, { statusCode: 202 }))
        .catch((error) => done(null, { statusCode: 500, body: JSON.stringify(error) }));
};

module.exports = { sendEmail };
