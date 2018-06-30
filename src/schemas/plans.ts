import { Plan } from '../models';

import { Model, model, models, Schema } from 'mongoose';

const PlanSchema = new Schema({
    reference: {
        type: String,
        required: true
    },
    name: {
        type: String,
        required: true
    },
    currency: {
        type: String,
        required: true
    },
    price: {
        type: Number,
        required: true
    },
    interval: {
        type: Number,
        required: true
    },
    frequency: {
        type: String,
        enum: ['day', 'week', 'month', 'year'],
        required: true
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

PlanSchema.index({ name: 1 }, { unique: true });

PlanSchema.pre('save', function (this: Plan, next: any) {
    this.updated = new Date();
    next();
});

export const PlanModel: Model<Plan> = models['plans'] ? <Model<Plan>>models['plans'] : <Model<Plan>>model('plans', PlanSchema);
