import { Request, Response, NextFunction } from 'express';
import * as mongoose from 'mongoose';

import { MongoError } from 'mongodb';

export class VenzraDatabase {

    static connect(req: Request, res: Response, next: NextFunction): void {
        const mongo = {
            uri: <string>process.env['DB_URI'],
            options: {
                autoIndex: false,
                bufferCommands: false,
                bufferMaxEntries: 0,
                socketTimeoutMS: 0,
                keepAlive: 120,
                reconnectTries: 30,
                poolSize: 1
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
