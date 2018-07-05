import { Schema } from 'mongoose';

const ShipmentSchema: Schema = new Schema({
    reference: {
        type: String,
        trim: true
    },
    name: {
        type: String,
        required: true,
        trim: true,
        maxlength: 80
    },
    courier: {
        type: String,
        trim: true,
        maxlength: 50,
    },
    tracking: {
        type: String,
        trim: true,
        maxlength: 30
    },
    price: {
        type: Number,
        required: true,
        min: 0,
        max: 1000000
    }
}, { _id: false });

export { ShipmentSchema };
