import { Schema, model, Model, models } from 'mongoose';

import { Category } from '../models';

const CategorySchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    parent: {
        type: Schema.Types.ObjectId,
        ref: 'categories'
    },
    children: {
        type: [Schema.Types.ObjectId],
        ref: 'categories',
        default: []
    },
    slug: {
        type: String,
        lowercase: true,
        maxlength: 30
    },
    name: {
        type: String,
        required: true,
        trim: true,
        maxlength: 30
    },
    description: {
        type: String,
        required: true,
        trim: true,
        maxlength: 1000
    },
    primary: {
        type: Boolean,
        required: true,
        default: false
    },
    featureImage: {
        type: Schema.Types.ObjectId,
        ref: 'images'
    },
    products: {
        type: [{
            type: Schema.Types.ObjectId,
            ref: 'products'
        }],
        default: []
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

CategorySchema.index({ subscription: 1, slug: 1 }, { unique: true });

CategorySchema.index({ name: 1 });

CategorySchema.pre('validate', function (this: Category, next: any) {
    this.slug = (this.name || '').replace(/[^a-z|0-9\-\s]/gi, ' ').trim().replace(/\s+/g, '-');
    next();
});

CategorySchema.pre('save', function (this: Category, next: any) {
    this.updated = new Date();
    next();
});

export const CategoryModel: Model<Category> = models['categories'] ? <Model<Category>>models['categories'] : <Model<Category>>model('categories', CategorySchema);
