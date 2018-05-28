const mongoose = require('mongoose');

const PlanSchema = new mongoose.Schema({
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

PlanSchema.pre('save', function (next) {
    this.updated = new Date();
    next();
});

module.exports = mongoose.models['plans'] ? mongoose.models['plans'] : mongoose.model('plans', PlanSchema);
