const fs = require('fs');
const path = require('path');

const { security } = require('../../services/security.service');

const findOne = (event, context, done) => {
    const params = event.pathParameters;
    const documentPath = path.join(__dirname, params.section, `${params.page}.md`);

    console.log(event);
    fs.readFile(documentPath, 'utf-8', (err, data) => {
        if (err) {
            return done(null, { statusCode: 404 });
        }

        let result = {};
        const liquid = data.split('-----');

        if (liquid.length > 1) {
            const meta = liquid[0].split('\n');
            meta.forEach((description) => {
                const pos = description.indexOf('=');
                if (pos > 0) {
                    const field = description.substr(0, pos - 1).trim();
                    result[field] = description.substr(pos + 1).trim();
                }
            });
            result.content = liquid[1].trim();
        } else {
            result.content = liquid[0].trim();
        }

        const response = {
            statusCode: 200,
            headers: security.accessControl(event.headers),
            body: JSON.stringify(result)
        };
        return done(null, response);
    });
};

module.exports = { findOne };
