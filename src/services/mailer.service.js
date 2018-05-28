const ejs = require('ejs');
const path = require('path');

const { SES } = require('aws-sdk');

const mailer = {
    send: (subject, origin, destination, template, content, replyTo) => {
        const ses = new SES({ region: 'eu-west-1' });

        const promise = new Promise((resolve, reject) =>
            ejs.renderFile(
                path.join(__dirname, 'templates', `${template}.ejs`),
                content,
                ((error, message) => {
                    if (error) {
                        return reject(error);
                    }
                    return resolve({
                        Source: origin,
                        Destination: {
                            ToAddresses: [destination]
                        },
                        Message: {
                            Subject: {
                                Data: subject
                            },
                            Body: {
                                Html: {
                                    Data: message
                                }
                            }
                        },
                        ReplyToAddresses: [replyTo]
                    });
                })
            )
        );

        return promise.then((request) => ses.sendEmail(request).promise());
    }
};

module.exports = { mailer };
