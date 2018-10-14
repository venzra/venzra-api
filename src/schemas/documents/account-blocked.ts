import { Schema } from "mongoose";

const AccountBlockedSchema: Schema = new Schema({
    failures: {
        type: Number,
        required: true,
        default: 0
    },
    ip: {
        type: String,
        required: true,
        default: '0.0.0.0'
    },
    updated: {
        type: Date
    }
}, { _id: false });

export { AccountBlockedSchema };
