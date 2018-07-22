import { Schema, Model, model, models } from 'mongoose';

import { Order } from '../models';
import { AddressSchema, ItemSchema, OrderPaymentSchema, ShipmentSchema } from './documents';

const OrderSchema: Schema = new Schema({
    subscription: {
        type: Schema.Types.ObjectId,
        ref: 'subscriptions',
        required: true
    },
    customer: {
        type: Schema.Types.ObjectId,
        ref: 'customers',
        required: true
    },
    reference: {
        type: String,
        required: true,
        trim: true,
        maxlength: 20
    },
    items: {
        type: [ItemSchema],
        required: true
    },
    shipping: {
        type: ShipmentSchema,
        required: true
    },
    destination: {
        type: AddressSchema,
        required: true
    },
    billing: {
        type: AddressSchema,
        required: true
    },
    payment: {
        type: OrderPaymentSchema,
        required: true
    },
    history: {
        type: [{
            type: Schema.Types.ObjectId,
            ref: 'orderHistory'
        }]
    },
    status: {
        type: String,
        enum: ['CREATED', 'AUTHORISED', 'PROCESSING', 'DISPATCHED', 'DELIVERED', 'REFUNDED'],
        required: true,
        default: 'CREATED'
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

OrderSchema.index({ subscription: 1, reference: 1 }, { unique: true });

OrderSchema.index({ reference: 1 });
OrderSchema.index({ status: 1 });

export const OrderModel: Model<Order> = models['orders'] ? <Model<Order>>models['orders'] : <Model<Order>>model('orders', OrderSchema);
