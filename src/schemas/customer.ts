import { Schema, Model, model, models } from 'mongoose';

import { Customer } from '../models';
import { AccountAccessSchema, AccountBlockedSchema, AccountPasswordSchema, AddressSchema } from './documents';

const EMAIL_REGEX = /^[a-z0-9!#$%&'*+\/=?^_`{|}~.-]+@[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;

const CustomerSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions'
    },
    identity: {
        type: String,
        required: true,
        trim: true,
        lowercase: true,
        maxlength: 80,
        validate: [
            (val: string) => EMAIL_REGEX.test(val), 'Invalid email address'
        ]
    },
    password: {
        type: AccountPasswordSchema
    },
    addresses: {
        type: [AddressSchema],
        default: []
    },
    primaryAddress: {
        type: Schema.Types.ObjectId
    },
    access: {
        type: AccountAccessSchema
    },
    lock: {
        type: AccountBlockedSchema,
        default: AccountBlockedSchema
    },
    status: {
        type: String,
        enum: ['ACTIVE', 'RECOVERY', 'LOCKED'],
        required: true,
        default: 'ACTIVE'
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

CustomerSchema.index({ subscription: 1, identity: 1 }, { unique: true });

CustomerSchema.pre('save', function (this: Customer, next: any) {
    this.updated = new Date();
    next();
});

export const CustomerModel: Model<Customer> = models['customers'] ? <Model<Customer>>models['customers'] : <Model<Customer>>model('customers', CustomerSchema);
