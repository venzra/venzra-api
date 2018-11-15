import { Account } from '../models';

import { Model, model, models, Schema } from 'mongoose';
import { AccountAccessSchema, AccountBlockedSchema, AccountPasswordSchema, AccountValidationSchema } from './documents';

const EMAIL_REGEX = /^[a-z0-9!#$%&'*+\/=?^_`{|}~.-]+@[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;

const AccountSchema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions'
    },
    identity: {
        type: String,
        required: true,
        trim: true,
        lowercase: true,
        maxlength: 255,
        validate: [
            (val: string) => EMAIL_REGEX.test(val), 'Invalid email address'
        ]
    },
    validation: {
        type: AccountValidationSchema
    },
    password: {
        type: AccountPasswordSchema
    },
    access: {
        type: AccountAccessSchema
    },
    lock: {
        type: AccountBlockedSchema,
        default: AccountBlockedSchema
    },
    terms: {
        type: Date,
        required: true,
        default: Date.now
    },
    status: {
        type: String,
        enum: ['REGISTERED', 'ACTIVE', 'RECOVERY', 'LOCKED', 'DISABLED'],
        required: true,
        default: 'REGISTERED'
    },
    created: {
        type: Date,
        required: true,
        default: Date.now
    },
    updated: {
        type: Date,
        required: true,
        default: Date.now
    }
});

AccountSchema.index({ identity: 1 }, { unique: true });

AccountSchema.pre('save', function (this: Account, next: any) {
    this.updated = new Date();
    next();
});


export const AccountModel: Model<Account> = models['accounts'] ? <Model<Account>>models['accounts'] : <Model<Account>>model('accounts', AccountSchema);
