import { Schema } from 'mongoose';

const ChargesSchema: Schema = new Schema({
    currency: {
        type: String
    },
    quantity: {
        type: Number
    },
    value: {
        type: Number
    }
}, { _id: false });

export { ChargesSchema };
