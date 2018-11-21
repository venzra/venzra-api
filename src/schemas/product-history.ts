import { Schema, Model, model, models } from 'mongoose';

import { History } from '../models';

const ProductHistorySchema: Schema = new Schema({
    account: {
        type: Schema.Types.ObjectId,
        ref: 'accounts',
        required: true
    },
    field: {
        type: String,
        required: true
    },
    previous: {
        type: String
    },
    next: {
        type: String,
        required: true
    },
    created: {
        type: Date,
        required: true,
        default: Date.now,
        expires: 2419200
    }
});

export const ProductHistoryModel: Model<History> = models['productHistory'] ? <Model<History>>models['productHistory'] : <Model<History>>model('productHistory', ProductHistorySchema);
