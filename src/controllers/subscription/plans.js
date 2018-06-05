const databaseConnect = require('../../database');
const Plans = require('../../models/plans.schema');

const { security } = require('../../services/security.service');

const findAll = (event, context, done) => {
    context.callbackWaitsForEmptyEventLoop = false;

    const order = { price: 1, name: 1 };

    databaseConnect()
        .then(() =>
            Plans
                .count(null)
                .exec()
                .then((total) =>
                    Plans
                        .aggregate([
                            { $sort: order },
                            { $project: { reference: 1, name: 1, currency: 1, price: 1, interval: 1, frequency: 1 } }
                        ])
                        .then((list) => {
                            const response = {
                                statusCode: 200,
                                headers: security.accessControl(event.headers),
                                body: JSON.stringify({ list, total })
                            };
                            return done(null, response)
                        })
                ))
        .catch((planError) => {
            const response = {
                statusCode: 500,
                headers: security.accessControl(event.headers),
                body: JSON.stringify(planError)
            };
            return done(null, response)
        });
};

module.exports = { findAll };
