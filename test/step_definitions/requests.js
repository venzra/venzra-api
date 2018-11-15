const { Given, When, Then } = require('cucumber');


Given(/^the request origin headers are set to "([^"]*)"$/, function (requestOrigin) {
    this.setHeader('Origin', `http://${requestOrigin}`);
    this.setHeader('Referer', `http://${requestOrigin}`);
    this.setHeader('Host', requestOrigin);
});

Given(/^I am logged in with the "([^"]*)" (admin|store) account$/, function (userIdentity, userType) {
    return Promise.resolve(this.performPost(`/${userType}/identity/login`, { identity: userIdentity, password: 'VenzraTest$1' }));
});

Given(/^I set the "([^"]*)" cookie to the value "([^"]*)"$/, function (cookieName, cookieValue) {
    return this.setCookie(cookieName, cookieValue);
});

When(/^I make a (GET) request to the API endpoint "([^"]*)" as "([^"]*)"(?: with "([^"]*)" content type)?$/, function (requestMethod, requestEndpoint, historyName, contentType) {
    this.setHeader('content-type', contentType ? contentType : 'application/json');
    return Promise.resolve(this.performGet(requestEndpoint, historyName));
});

When(/^I make an empty (POST) request to the API endpoint "([^"]*)" as "([^"]*)"$/, function (requestMethod, requestEndpoint, historyName) {
    return Promise.resolve(this.performPost(requestEndpoint, null, historyName));
});

When(/^I make a (POST) request to the API endpoint "([^"]*)" as "([^"]*)" using:$/, function (requestMethod, requestEndpoint, historyName, requestData) {
    requestData = this.getHashes(requestData);
    return Promise.resolve(this.performPost(requestEndpoint, requestData[0], historyName));
});

When(/^I make a (POST) request to the API endpoint "([^"]*)" as "([^"]*)" with the mock "([^"]*)"$/, function (requestMethod, requestEndpoint, historyName, mockFile) {
    const requestData = this.readMock(mockFile);
    return Promise.resolve(this.performPost(requestEndpoint, requestData, historyName));
});

When(/^I make an empty (PATCH) request to the API endpoint "([^"]*)" as "([^"]*)"$/, function (requestMethod, requestEndpoint, historyName) {
    return Promise.resolve(this.performPatch(requestEndpoint, null, historyName));
});

When(/^I make a (PATCH) request to the API endpoint "([^"]*)" as "([^"]*)" using:$/, function (requestMethod, requestEndpoint, historyName, requestData) {
    requestData = this.getHashes(requestData);
    return Promise.resolve(this.performPatch(requestEndpoint, requestData, historyName));
});

When(/^I make a (DELETE) request to the API endpoint "([^"]*)" as "([^"]*)"$/, function (requestMethod, requestEndpoint, historyName) {
    return Promise.resolve(this.performDelete(requestEndpoint, historyName));
});
