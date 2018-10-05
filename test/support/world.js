const crypto = require('crypto');
const fs = require('fs');
const moment = require('moment');
const path = require('path');
const uuid = require('uuid');

const { setWorldConstructor } = require('cucumber');

let history = {};

class World {

    constructor() {
        this.loadConfig((process.env['NODE_ENV'] || 'TEST').toLowerCase());
        this.headers = new Set();
        this.mocks = [];
        this.history = history;
    }

    loadConfig(mode) {
        const config = require('../../config');
        Object.assign(process.env, config[mode]);
    }

    setHeader(name, value) {
        this.headers.add({ name, value });
    }

    setCookie(name, value) {
        value = this.parseTemplateString(value);
        this.agent.jar.setCookie(`${name}=${value}`);
    }

    addMock(mock) {
        this.mocks.push(mock);
    }

    readMock(file) {
        const filePath = path.join(__dirname, '../mocks', file);
        return JSON.parse(fs.readFileSync(filePath));
    }

    parseTemplateString(string) {
        let template = string.match(/{{\s?(\S*)\s?}}/);
        if (template !== null) {
            let history;
            let target = template[1].split('.');
            let request = target.shift();
            let parts = request.match(/\[(\d+)\]/);

            if (parts) {
                history = this.getHistory(request.replace(parts[0], ''), parts[1] - 1);
            } else {
                history = this.getHistory(request)['response'];
            }

            target.forEach((field) => {
                let subArray = field.match(/\[(\d+)\]/);
                if(subArray) {
                    field = field.replace(subArray[0], '');
                    history = history[field][subArray[1] - 1];
                } else {
                    history = history[field]
                }
            });

            string = string.replace(template[0], history);
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
                    case 'DATE':
                        row[hash] = moment().add(keywords[2], 'hours').toISOString();
                        break;
                    case 'DATETIME':
                        row[hash] = Date.now();
                        break;
                    case 'PASSWORD':
                        const salt = crypto.createHash('sha1').update(uuid.v4()).digest('hex');
                        row[hash] = { salt: salt, secure: crypto.pbkdf2Sync('VenzraTest$1', salt, 10000, 256, 'sha512').toString('base64'), created: Date.now() };
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

    processResponse(res, storage) {
        if (this.mocks.length > 0) {
            this.mocks.forEach((mock) => {
                mock.done();
            });
        }

        let data = {
            status: res.statusCode,
            headers: res.headers
        };

        try {
            data.response = JSON.parse(res.text);
        } catch (ex) {
            data.response = res.text || res.body;
        }

        if (storage) {
            this.history[storage] = data;
        }
    }

    performGet(endpoint, storage) {
        return new Promise((resolve, reject) => {
            const uri = this.parseTemplateString(endpoint);
            const request = this.agent.get(uri);

            this.headers.forEach((header) => request.set(header.name, header.value));
            request.expect((res) => this.processResponse(res, storage));
            request.end((err, res) => err ? reject(err) : resolve(res));
        });
    }

    performPost(endpoint, data, storage) {
        return new Promise((resolve, reject) => {
            const uri = this.parseTemplateString(endpoint);
            const request = this.agent.post(uri);

            this.headers.forEach((header) => request.set(header.name, header.value));
            request.send(data);
            request.expect((res) => this.processResponse(res, storage));
            request.end((err, res) => err ? reject(err) : resolve(res));
        });
    }

    performPatch(endpoint, data, storage) {
        return new Promise((resolve, reject) => {
            const uri = this.parseTemplateString(endpoint);
            const request = this.agent.patch(uri);

            this.headers.forEach((header) => request.set(header.name, header.value));
            request.send(data);
            request.expect((res) => this.processResponse(res, storage));
            request.end((err, res) => err ? reject(err) : resolve(res));
        });
    }

    performDelete(endpoint, storage) {
        return new Promise((resolve, reject) => {
            const uri = this.parseTemplateString(endpoint);
            const request = this.agent.delete(uri);

            this.headers.forEach((header) => request.set(header.name, header.value));
            request.expect((res) => this.processResponse(res, storage));
            request.end((err, res) => err ? reject(err) : resolve(res));
        });
    }

}

setWorldConstructor(World);
