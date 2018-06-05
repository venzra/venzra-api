const security = {
    accessControl: (request) => {
        const headers = {};

        if (request['origin'] === process.env['MARKETING_URL'] || request['origin'] === process.env['ADMIN_URL']) {
            headers['access-control-allow-origin'] = request['origin'];
        }
        headers['access-control-allow-headers'] = 'Content-Type';
        headers['access-control-allow-credentials'] = 'true';

        return headers;
    }
};

module.exports = { security };
