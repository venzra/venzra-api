import { Request, Response, NextFunction } from 'express';
import * as mongoose from 'mongoose';

import { MongoError } from 'mongodb';
import { Mongoose } from 'mongoose';

let databaseConnection: number = 0;

export class VenzraDatabase {

    static connect(req: Request, res: Response, next: NextFunction): void {
        const mongo = {
            uri: <string>process.env['DB_URI'],
            options: {
                socketTimeoutMS: 0,
                keepAlive: 120,
                reconnectTries: 30,
                poolSize: 5
            }
        };

        if (!databaseConnection) {
            mongoose
                .connect(mongo.uri, mongo.options)
                .then((db: Mongoose) => {
                    databaseConnection = db.connection.readyState;
                    next();
                })
                .catch((err: MongoError) => next(err));
        } else {
            next();
        }
    }

}

export default VenzraDatabase.connect;
