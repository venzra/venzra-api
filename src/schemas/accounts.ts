import { Account } from '../models';

import { Model, model, models, Schema } from 'mongoose';

const EMAIL_REGEX = /^[a-z0-9!#$%&'*+\/=?^_`{|}~.-]+@[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;

const AccountSchema = new Schema({
    identity: {
        type: String,
        required: true,
        trim: true,
        lowercase: true,
        validate: [
            (val: string) => EMAIL_REGEX.test(val), 'Invalid email address'
        ]
    },
    validation: {
        type: {
            key: {
                type: String,
                required: true
            },
            expires: {
                type: Date,
                required: true
            }
        }
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
