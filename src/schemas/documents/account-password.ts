import { Schema } from "mongoose";

const AccountPasswordSchema: Schema = new Schema({
    salt: {
        type: String,
        required: true
    },
    secure: {
        type: String,
        required: true
    },
    created: {
        type: Date,
        required: true
    }
}, { _id: false });

export { AccountPasswordSchema };
