const mongoose = require('mongoose');
const { Given, When, Then } = require('cucumber');

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
                throw new Error(`No model known for collection ${collection}`);
            }
        });
});
