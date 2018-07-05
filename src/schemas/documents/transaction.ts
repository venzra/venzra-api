import { Schema } from 'mongoose';

const FeeSchema: Schema = new Schema({
    base: {
        type: Number,
        required: true,
        default: 10
    },
    rate: {
        type: Number,
        required: true,
        default: 0.046
    }
}, { _id: false });

export { FeeSchema };
