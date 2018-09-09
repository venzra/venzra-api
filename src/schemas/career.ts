import moment = require('moment');

import { Schema, Model, model, models } from 'mongoose';
import { Career } from '../models';

const CareerSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    position: {
        type: String,
        required: true,
        trim: true,
        maxlength: 120
    },
    description: {
        type: String,
        required: true,
        trim: true,
        maxlength: 5000
    },
    expires: {
        type: Date,
        required: true,
        expires: 604800
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

CareerSchema.pre('validate', function (this: Career, next: any) {
    if (this.expires) {
        this.expires = moment(this.expires).endOf('day').toDate();
    }
    next();
});

CareerSchema.pre('save', function (this: Career, next: any) {
    this.updated = new Date();
    next();
});

export const CareerModel: Model<Career> = models['careers'] ? <Model<Career>>models['careers'] : <Model<Career>>model('careers', CareerSchema);
