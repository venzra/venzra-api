import { Schema, Model, model, models } from 'mongoose';

import { Product } from '../models';

const ProductSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    slug: {
        type: String,
        lowercase: true,
        maxlength: 80
    },
    code: {
        type: String,
        required: true,
        trim: true,
        maxlength: 20
    },
    displayName: {
        type: String,
        required: true,
        trim: true,
        maxlength: 80
    },
    description: {
        type: String,
        required: true,
        trim: true,
        maxlength: 2000
    },
    featureImage: {
        type: Schema.Types.ObjectId,
        ref: 'images'
    },
    promotionalImage: {
        type: Schema.Types.ObjectId,
        ref: 'images',
        required: true
    },
    previousPrice: {
        type: Number,
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
    categories: {
        type: [{
            type: Schema.Types.ObjectId,
            ref: 'categories'
        }],
        default: []
    },
    status: {
        type: String,
        enum: ['ACTIVE', 'INACTIVE'],
        required: true,
        default: 'INACTIVE'
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

ProductSchema.index({ subscription: 1, code: 1 }, { unique: true });
ProductSchema.index({ subscription: 1, slug: 1 }, { unique: true });

ProductSchema.index({ code: 1 });
ProductSchema.index({ displayName: 1 });
ProductSchema.index({ currentPrice: 1 });
ProductSchema.index({ status: 1 });

ProductSchema.index({ code: 'text', displayName: 'text', description: 'text' }, { weights: { displayName: 10, description: 2 } });

ProductSchema.pre('validate', function (this: Product, next: any) {
    this.slug = (this.displayName || '').replace(/[^a-z|0-9\-\s]/gi, ' ').trim().replace(/\s+/g, '-');
    this.previousPrice = this.previousPrice ? Math.floor(this.previousPrice) : this.previousPrice;
    this.currentPrice = this.currentPrice ? Math.floor(this.currentPrice) : this.currentPrice;
    next();
});

ProductSchema.pre('save', function (this: Product, next: any) {
    this.updated = new Date();
    next();
});

export const ProductModel: Model<Product> = models['products'] ? <Model<Product>>models['products'] : <Model<Product>>model('products', ProductSchema);
