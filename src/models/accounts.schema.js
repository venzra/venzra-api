const mongoose = require('mongoose');

const EMAIL_REGEX = /^[a-z0-9!#$%&'*+\/=?^_`{|}~.-]+@[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;

const AccountsSchema = new mongoose.Schema({
    identity: {
        type: String,
        required: true,
        trim: true,
        lowercase: true,
        validate: [
            (val) => EMAIL_REGEX.test(val), 'Invalid email address'
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

AccountsSchema.index({ identity: 1 }, { unique: true });

AccountsSchema.pre('save', function (next) {
    this.updated = new Date();
    next();
});

module.exports = mongoose.models['accounts'] ? mongoose.models['accounts'] : mongoose.model('accounts', AccountsSchema);
