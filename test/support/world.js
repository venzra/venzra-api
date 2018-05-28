const fs = require('fs');
const path = require('path');

const request = require('request-promise');
const { setWorldConstructor } = require('cucumber');

let history = {};

class World {

    constructor() {
        this.server = 'http://localhost:3001';
        this.headers = new Set();
        this.history = history;
    }

    setHeader(name, value) {
        this.headers.add({ name, value });
    }

    readMock(file) {
        const filePath = path.join(__dirname, '../mocks', file);
        return JSON.parse(fs.readFileSync(filePath));
    }

    parseTemplateString(string) {
        let template = string.match(/{{\s?(\S*)\s?}}/);
        if (template !== null) {
            let target = template[1].split('.');
            let request = target.shift();
            let parts = request.match(/\[(\d+)\]/);
            if (parts) {
                let history = this.getHistory(request.replace(parts[0], ''), parts[1] - 1);
                target.forEach((field) => history = history[field]);
                string = string.replace(template[0], history);
            }
            string = this.parseTemplateString(string);
        }
        return string;
    }

    getHashes(data) {
        let cleaned = [];
        let rows = data.hashes();

        for (let row of rows) {
            for (let hash in row) {
                if (!row[hash] || row[hash] === '') {
                    delete row[hash];
                    break;
                }

                row[hash] = this.parseTemplateString(row[hash]);

                const keywords = row[hash].match(/^(\S*)\((\S*)\)$/);
                const keyword = keywords ? keywords[1] : row[hash];

                switch (keyword) {
                    case 'DATETIME':
                        row[hash] = Date.now();
                        break;
                }

                try {
                    let parsed = JSON.parse(row[hash]);
                    row[hash] = parsed;
                } catch (ex) {
                }
            }
            cleaned.push(row);
        }
        return cleaned;
    }

    getHistory(name, row) {
        if (row !== undefined) {
            return this.history[name][row];
        }
        return this.history[name];
    }

    performGet(endpoint, storage) {
        const params = {
            uri: this.parseTemplateString(endpoint),
            method: 'GET',
            headers: this.headers,
            json: true,
            resolveWithFullResponse: true
        };

        return this.performRequest(params)
            .then((data) => {
                if (storage) {
                    this.history[storage] = data;
                }
            });
    }

    performPost(endpoint, data, storage) {
        const params = {
            uri: this.parseTemplateString(endpoint),
            method: 'POST',
            headers: this.headers,
            body: data,
            json: true,
            resolveWithFullResponse: true
        };

        return this.performRequest(params)
            .then((data) => {
                if (storage) {
                    this.history[storage] = data;
                }
            });
    }

    performPatch(endpoint, data, storage) {
        const params = {
            uri: this.parseTemplateString(endpoint),
            method: 'POST',
            headers: this.headers,
            body: data,
            json: true,
            resolveWithFullResponse: true
        };

        return this.performRequest(params)
            .then((data) => {
                if (storage) {
                    this.history[storage] = data;
                }
            });
    }

    performRequest(params) {
        params.uri = `${this.server}${params.uri}`;

        return request(params)
            .catch((error) => error)
            .then((res) => {
                let data = {
                    status: res.statusCode,
                    headers: res.headers
                };

                try {
                    data.response = JSON.parse(res.text);
                } catch (ex) {
                    data.response = res.text || res.error || res.body;
                }

                return data;
            });
    }

}

setWorldConstructor(World);
