import { Schema, Model, model, models } from 'mongoose';

import { Shipping } from '../models/index';

const ShippingSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    displayName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 80
    },
    cartMinimum: {
        type: Number,
        required: true,
        min: 0,
        max: 1000000,
        default: 0
    },
    cartMaximum: {
        type: Number,
        required: true,
        min: 0,
        max: 1000000,
        default: 0
    },
    currentPrice: {
        type: Number,
        required: true,
        min: 0,
        max: 1000000
    },
    shipmentTime: {
        type: Number,
        required: true,
        min: 0,
        max: 3000,
        default: 48
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

ShippingSchema.pre('save', function (this: Shipping, next: any) {
    this.updated = new Date();
    next();
});

export const ShippingModel: Model<Shipping> = models['shipping'] ? <Model<Shipping>>models['shipping'] : <Model<Shipping>>model('shipping', ShippingSchema);
