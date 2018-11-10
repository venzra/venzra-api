import { Request, Response, NextFunction } from 'express';
import * as mongoose from 'mongoose';

import { MongoError } from 'mongodb';

export class VenzraDatabase {

    static connect(req: Request, res: Response, next: NextFunction): void {
        const mongo = {
            uri: <string>process.env['DB_URI'],
            options: {
                autoIndex: true,
                bufferCommands: false,
                bufferMaxEntries: 0,
                keepAlive: 120,
                poolSize: 1,
                reconnectTries: 30,
                socketTimeoutMS: 0,
                useCreateIndex: true,
                useNewUrlParser: true
            }
        };

        if (!mongoose.connection.readyState) {
            mongoose
                .connect(mongo.uri, mongo.options)
                .then(() => next())
                .catch((err: MongoError) => next(err));
        } else {
            next();
        }
    }

}

export default VenzraDatabase.connect;
