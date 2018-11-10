import { Schema, Model, model, models } from 'mongoose';

import { Cart } from '../models';

const CartSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    items: {
        type: [{
            product: {
                type: Schema.Types.ObjectId,
                ref: 'products',
                required: true
            },
            quantity: {
                type: Number,
                required: true,
                default: 1
            }
        }],
        default: []
    },
    ip: {
        type: String,
        required: true,
        default: '0.0.0.0'
    },
    created: {
        type: Date,
        required: true,
        default: Date.now
    },
    updated: {
        type: Date,
        required: true,
        default: Date.now,
        expires: 2419200
    }
});

CartSchema.pre('save', function (this: Cart, next: any) {
    this.updated = new Date();
    next();
});

export const CartModel: Model<Cart> = models['carts'] ? <Model<Cart>>models['carts'] : <Model<Cart>>model('carts', CartSchema);
