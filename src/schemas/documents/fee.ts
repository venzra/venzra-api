import { Schema } from 'mongoose';

const FeeSchema: Schema = new Schema({
    venzra: {
        type: {
            amount: Number,
            currency: String,
            refund: Number
        },
        required: true
    },
    gateway: {
        type: {
            amount: Number,
            currency: String,
            refund: Number
        },
        required: true
    },
    total: {
        type: Number,
        required: true
    }
}, { _id: false });

export { FeeSchema };
