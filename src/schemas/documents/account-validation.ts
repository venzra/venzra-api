import { Schema } from "mongoose";

const AccountValidationSchema: Schema = new Schema({
    key: {
        type: String,
        required: true
    },
    expires: {
        type: Date,
        required: true
    }
}, { _id: false });

export { AccountValidationSchema };
