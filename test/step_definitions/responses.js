const { Given, When, Then } = require('cucumber');
const { expect } = require('chai');

const cookieParser = require('cookie');

const checkValues = (expected, actual) => {
    const expectedKeys = Object.keys(expected);
    const actualKeys = Object.keys(actual);

    expect(actualKeys, 'Response keys do not match expectation').to.have.members(expectedKeys);

    expectedKeys.map((key) => {
        let check;
        if (typeof expected[key] === 'string') {
            check = expected[key].match(/\[(\d+)\]/) || expected[key];
            if (check instanceof Array) {
                expected[key] = expected[key].replace(check[0], '');
            }
        }

        switch (expected[key]) {
            case 'OBJECT_ID':
                expect(actual[key]).to.match(/^[0-9A-F]{24}$/i);
                break;
            case 'DATE_TIME':
                expect(actual[key]).to.match(/^\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d\.\d+([+-][0-2]\d:[0-5]\d|Z)$/);
                break;
            case 'STRING':
                expect(actual[key]).to.be.a('string');
                break;
            case 'ARRAY':
                expect(actual[key]).to.be.an.instanceof(Array);
                expect(actual[key]).to.have.length(check[1]);
                break;
            case 'OBJECT':
                expect(actual[key]).to.be.an('object');
                break;
            default:
                expect(actual[key]).to.deep.equal(expected[key]);
        }
    });
};

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
