import { Schema } from 'mongoose';

import { FeeSchema } from '.';

const OrderPaymentSchema: Schema = new Schema({
    reference: {
        type: String,
        required: true
    },
    transaction: {
        type: String,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    card: {
        type: String,
        required: true
    },
    brand: {
        type: String,
        required: true
    },
    fee: {
        type: FeeSchema,
        required: true
    },
    value: {
        type: Number,
        required: true
    },
    refund: {
        type: Number
    }
}, { _id: false });

export { OrderPaymentSchema };
