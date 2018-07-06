const { Given, When, Then } = require('cucumber');
const { expect } = require('chai');

const cookieParser = require('cookie');
const checkValues = require('../support/compare');

Then(/^the status returned from the "([^"]*)" request should be (201|202)$/, function (historyName, statusCode) {
    return Promise.resolve(this.getHistory(historyName))
        .then((history) => expect(history.status).to.equal(parseInt(statusCode)));
});

Then(/^the status returned from the "([^"]*)" request should be a (401|403|404) error$/, function (historyName, statusCode) {
    return Promise.resolve(this.getHistory(historyName))
        .then((history) => expect(history.status).to.equal(parseInt(statusCode)));
});

Then(/^(?:there should be a (200|400|500) (?:response|error) from )?the "([^"]*)" request that(?: has (?:a|an) "([^"]*)" field and row (\d+))? contains:$/, function (statusCode, historyName, expectedField, expectedRecord, expectedData) {
    expectedData = this.getHashes(expectedData);

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => Promise.all([
                statusCode ? expect(history.status).to.equal(parseInt(statusCode)) : true,
                checkValues(expectedData[0], expectedField && expectedRecord ? history.response[expectedField][expectedRecord - 1] : history.response)
            ])
        );
});

Then(/^the response path "([^"]*)" from the "([^"]*)" request contains:/, function (responsePath, historyName, expectedData) {
    expectedData = this.getHashes(expectedData);

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => history.response)
        .then((response) => {
            response = responsePath.split('.').reduce((response, pathItem) => response[pathItem], response);
            if (response instanceof Array) {
                return Promise.all(expectedData.map((expected, idx) => checkValues(expected, response[idx])));
            } else {
                return checkValues(expectedData[0], response);
            }
        });
});

Then(/^there is a(?: (deleted))? cookie called "([^"]*)" in the "([^"]*)" response header$/, function (negative, cookieName, historyName) {
    return Promise.resolve(this.getHistory(historyName))
        .then((history) => {
            const targetCookie = history.headers['set-cookie']
                .map((cookie) => cookieParser.parse(cookie))
                .find((cookie) => cookie[cookieName] !== undefined);

            if (negative) {
                if (targetCookie) {
                    expect(targetCookie[cookieName], `Cookie called ${cookieName} expected to be empty`).to.equal('');
                    expect(new Date(targetCookie.Expires).getTime()).to.equal(0);
                }
            } else {
                expect(targetCookie[cookieName], `Cookie called ${cookieName} not found`).to.not.equal('');
            }
        });
});

Then(/^the response from the "([^"]*)" request has a "([^"]*)" that contains rows:$/, function (historyName, expectedField, expectedData) {
    expectedData = this.getHashes(expectedData);

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => expectedData.reduce((chain, next, idx) => chain.then(() => checkValues(next, history.response[expectedField][idx], false)), Promise.resolve()));
});
