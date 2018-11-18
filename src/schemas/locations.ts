import { Schema, Model, model, models } from 'mongoose';

import { AddressSchema } from './documents';
import { Location } from '../models';

const LocationSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    displayName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 120
    },
    description: {
        type: String,
        required: true,
        trim: true,
        maxlength: 2000
    },
    address: {
        type: AddressSchema,
        required: true
    },
    featureImage: {
        type: Schema.Types.ObjectId,
        ref: 'images',
        required: true
    },
    usage: {
        type: String,
        enum: ['BUSINESS', 'STORE'],
        uppercase: true,
        required: true,
        default: 'BUSINESS'
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

LocationSchema.pre('save', function (this: Location, next: any) {
    this.updated = new Date();
    next();
});

export const LocationModel: Model<Location> = models['locations'] ? <Model<Location>>models['locations'] : <Model<Location>>model('locations', LocationSchema);
