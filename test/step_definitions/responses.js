const { Given, When, Then } = require('cucumber');
const { expect } = require('chai');
const sharp = require('sharp');

const cookieParser = require('cookie');
const checkValues = require('../support/compare');

Then(/^the status returned from the "([^"]*)" request should be (201|202)$/, function (historyName, statusCode) {
    return Promise.resolve(this.getHistory(historyName))
        .then((history) => expect(history.status).to.equal(parseInt(statusCode)));
});

Then(/^the status returned from the "([^"]*)" request should be a (401|403|404|500) error$/, function (historyName, statusCode) {
    return Promise.resolve(this.getHistory(historyName))
        .then((history) => expect(history.status).to.equal(parseInt(statusCode)));
});

Then(/^(?:there should be a (200|400|413|500|503) (?:response|error) from )?the "([^"]*)" request that(?: has (?:a|an) "([^"]*)" field and row (\d+))? contains(?: an object called "([^"]*)" with)?:$/, function (statusCode, historyName, expectedField, expectedRecord, expectedObject, expectedData) {
    expectedData = this.getHashes(expectedData);

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => {
                let targetObject = expectedField && expectedRecord ? history.response[expectedField][expectedRecord - 1] : history.response;

                if (expectedObject) {
                    targetObject = targetObject[expectedObject];
                }

                return Promise.all([
                    statusCode ? expect(history.status).to.equal(parseInt(statusCode)) : true,
                    checkValues(expectedData[0], targetObject)
                ]);
            }
        );
});

Then(/^there should be a 200 response from the "([^"]*)" request with an "([^"]*)" binary containing:$/, function (historyName, expectedType, expectedData) {
    expectedData = this.getHashes(expectedData);

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => Promise.all([
                expect(history.status).to.equal(parseInt(200)),
                expect(history.headers['content-type']).to.equal(expectedType),
                sharp(history.response).metadata().then((metadata) => checkValues(expectedData[0], metadata, '', false))
            ])
        );
});

Then(/^the response path "([^"]*)" from the "([^"]*)" request(?: (partially))? contains:/, function (responsePath, historyName, partial, expectedData) {
    expectedData = this.getHashes(expectedData);
    partial = !partial;

    return Promise.resolve(this.getHistory(historyName))
        .then((history) => history.response)
        .then((response) => {
            response = responsePath.split('.').reduce((response, pathItem) => response[pathItem], response);
            if (response instanceof Array) {
                return Promise.all(expectedData.map((expected, idx) => checkValues(expected, response[idx], `row "${idx + 1}" does not match`, partial)));
            } else {
                return checkValues(expectedData[0], response, '', partial);
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
        .then((history) => expectedData.reduce((chain, next, idx) => chain.then(() => checkValues(next, history.response[expectedField][idx], `row "${idx + 1}" does not match`, false)), Promise.resolve()));
});
