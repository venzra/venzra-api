const mongoose = require('mongoose');
const { Given, When, Then } = require('cucumber');

const checkValues = require('../support/compare');
const databaseConnect = require('../../src/database');

const Accounts = require('../../src/models/accounts.schema');
const Plans = require('../../src/models/plans.schema');

Given(/^there are the following "([^"]*)" records in the database$/, function (collection, dataset) {
    dataset = this.getHashes(dataset);

    return databaseConnect()
        .then(() => {
            if (mongoose.models[collection]) {
                return Promise
                    .all(dataset.map((row) => {
                        const creation = new mongoose.models[collection](row);
                        return creation.save();
                    }))
                    .then((records) => this.history[collection] = records);
            } else {
                throw new Error(`No model known for collection "${collection}" has it been imported in the test step definitions?`);
            }
        });
});

Then(/^the database record for "([^"]*)" in the "([^"]*)" table equals:$/, function(record, collection, dataset) {
    record = this.parseTemplateString(record);
    dataset = this.getHashes(dataset);

    return databaseConnect()
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
