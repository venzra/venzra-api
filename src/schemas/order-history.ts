import { Schema, Model, model, models } from 'mongoose';

import { History } from '../models';

const OrderHistorySchema: Schema = new Schema({
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
        expires: 7776000
    }
});

export const OrderHistoryModel: Model<History> = models['orderHistory'] ? <Model<History>>models['orderHistory'] : <Model<History>>model('orderHistory', OrderHistorySchema);
