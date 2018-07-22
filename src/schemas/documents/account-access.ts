import { Schema } from "mongoose";

const AccountAccessSchema: Schema = new Schema({
    key: {
        type: String,
        required: true
    },
    ip: {
        type: String,
        required: true
    },
    created: {
        type: Date,
        required: true
    }
}, { _id: false });

export { AccountAccessSchema };
