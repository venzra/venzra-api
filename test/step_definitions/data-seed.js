const mongoose = require('mongoose');
const { Given, When, Then } = require('cucumber');

const checkValues = require('../support/compare');

Given(/^there are the following "([^"]*)" records in the database(?: (in series))?$/, function (collection, series, dataset) {
    dataset = this.getHashes(dataset);

    if (!mongoose.connection.readyState) {
        const mongo = {
            uri: process.env['DB_URI'],
            options: {
                autoIndex: true,
                bufferCommands: false,
                bufferMaxEntries: 0,
                keepAlive: 120,
                poolSize: 2,
                reconnectTries: 30,
                socketTimeoutMS: 0,
                useCreateIndex: true,
                useNewUrlParser: true
            }
        };
        mongoose.connect(mongo.uri, mongo.options);
    }

    return Promise.resolve()
        .then(() => {
            if (mongoose.models[collection]) {
                if (series) {
                    return new Promise((resolve) => {
                        const results = [];
                        const insert = dataset.reduce((chain, row) => chain.then(() => new Promise((resolve) => setTimeout(resolve, 5))).then(() => new mongoose.models[collection](row).save().then((result) => results.push(result))), Promise.resolve());
                        insert.then(() => resolve(results));
                    }).then((records) => this.history[collection] = records);
                } else {
                    return Promise
                        .all(dataset.map((row) => {
                            Object.keys(row).forEach((key) => (row[key] === null || row[key] === '') && delete row[key]);
                            const creation = new mongoose.models[collection](row);
                            return creation.save();
                        }))
                        .then((records) => this.history[collection] = records);
                }
            } else {
                throw new Error(`No model known for collection "${collection}" has it been imported in the test step definitions?`);
            }
        });
});

Given(/^the following "([^"]*)" records are updated in the database$/, function (collection, dataset) {
    dataset = this.getHashes(dataset);

    if (!mongoose.connection.readyState) {
        mongoose.connect(process.env['DB_URI']);
    }

    if (mongoose.models[collection]) {
        return Promise
            .all(dataset.map((row) => mongoose.models[collection].findOne({ _id: row._id })
                .then((record) => {
                    Object.keys(row).forEach((key) => (row[key] == null) && delete row[key]);
                    return record.update(row);
                }))
            );
    } else {
        throw new Error(`No model known for collection "${collection}" has it been imported in the test step definitions?`);
    }
});

Then(/^the database record for "([^"]*)" in the "([^"]*)" table equals:$/, function (record, collection, dataset) {
    record = this.parseTemplateString(record);
    dataset = this.getHashes(dataset);

    return Promise.resolve()
        .then(() => {
            if (mongoose.models[collection]) {
                return mongoose.models[collection].findOne({ _id: record }).select('-__v').lean();
            } else {
                throw new Error(`No model known for collection "${collection}" has it been imported in the test step definitions?`);
            }
        })
        .then((result) => {
            result = JSON.parse(JSON.stringify(result));
            return checkValues(dataset[0], result);
        });
});
