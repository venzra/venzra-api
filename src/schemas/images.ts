import { Schema, Model, model, models } from 'mongoose';

import { Image } from '../models';

const ImageSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    usage: {
        type: String,
        enum: ['logo', 'icon', 'feature', 'promotion'],
        required: true,
        trim: true
    },
    size: {
        type: Number,
        required: true
    },
    created: {
        type: Date,
        required: true,
        default: Date.now
    }
});

export const ImageModel: Model<Image> = models['images'] ? <Model<Image>>models['images'] : <Model<Image>>model('images', ImageSchema);
