import { Schema } from 'mongoose';

const GatewaySchema: Schema = new Schema({
    account: {
        type: String
    },
    refreshToken: {
        type: String
    },
    publicKey: {
        type: String
    },
    privateKey: {
        type: String
    },
    modified: {
        type: Date
    }
}, { _id: false });

export { GatewaySchema };
