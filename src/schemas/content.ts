import { Schema, Model, model, models } from 'mongoose';

import { Content } from '../models';

const ContentSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    content: {
        type: String,
        trim: true,
        maxlength: 20000
    },
    usage: {
        type: String,
        enum: ['ABOUT', 'CAREERS', 'CONTACT', 'LOCATION', 'TERMS'],
        uppercase: true,
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

ContentSchema.index({ subscription: 1, usage: 1 }, { unique: true });

ContentSchema.pre('save', function (this: Content, next: any) {
    this.updated = new Date();
    next();
});

export const ContentModel: Model<Content> = models['content'] ? <Model<Content>>models['content'] : <Model<Content>>model('content', ContentSchema, 'content');
