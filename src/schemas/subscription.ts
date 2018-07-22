import { Schema, Model, model, models } from 'mongoose';
import { v4 } from 'uuid';

import { AddonSchema, ContactSchema, GatewaySchema, TransactionSchema, ThemeSchema, SubscriptionPaymentSchema } from './documents';
import { Subscription } from '../models';

const SubscriptionSchema: Schema = new Schema({
    storeName: {
        type: String,
        required: true,
        trim: true,
        minlength: 3,
        maxlength: 40
    },
    addons: {
        type: [AddonSchema],
        default: []
    },
    strapline: {
        type: String,
        trim: true,
        maxlength: 120
    },
    domainName: {
        type: String,
        lowercase: true,
        required: true
    },
    icon: {
        type: Schema.Types.ObjectId,
        ref: 'images'
    },
    logo: {
        type: Schema.Types.ObjectId,
        ref: 'images'
    },
    theme: {
        type: ThemeSchema
    },
    payment: {
        type: SubscriptionPaymentSchema
    },
    gateway: {
        type: GatewaySchema
    },
    transactions: {
        type: TransactionSchema,
        default: TransactionSchema
    },
    contact: {
        type: ContactSchema
    },
    status: {
        type: String,
        enum: ['TRIAL', 'ACTIVE', 'INACTIVE'],
        required: true,
        default: 'TRIAL'
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

SubscriptionSchema.index({ storeName: 1 }, { unique: true });
SubscriptionSchema.index({ domainName: 1 }, { unique: true });

SubscriptionSchema.pre('validate', function (this: Subscription, next: any) {
    this.storeName = this.storeName || `store ${v4().substr(0, 8)}`;
    this.domainName = (this.storeName).replace(/[^a-z|0-9\-\s]/gi, ' ').trim().replace(/\s+/g, '-');
    next();
});

SubscriptionSchema.pre('save', function (this: Subscription, next: any) {
    this.updated = new Date();
    next();
});

export const SubscriptionModel: Model<Subscription> = models['subscriptions'] ? <Model<Subscription>>models['subscriptions'] : <Model<Subscription>>model('subscriptions', SubscriptionSchema);
