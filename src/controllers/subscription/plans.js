const databaseConnect = require('../../database');
const Plans = require('../../models/plans.schema');

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
                        .then((list) => done(null, { statusCode: 200, body: JSON.stringify({ list, total }) }))
                ))
        .catch((planError) => done(planError));
};

module.exports = { findAll };
