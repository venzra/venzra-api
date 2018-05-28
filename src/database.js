const mongoose = require('mongoose');

mongoose.Promise = global.Promise;
let databaseConnection;

module.exports = databaseConnect = () => {

    const mongo = {
        uri: process.env['DB_URI'],
        options: {
            socketTimeoutMS: 0,
            keepAlive: 120,
            reconnectTries: 30,
            poolSize: 5
        }
    };

    if (databaseConnection) {
        return Promise.resolve();
    }

    return mongoose.connect(mongo.uri, mongo.options).then((db) => databaseConnection = db.connections[0].readyState);

};
