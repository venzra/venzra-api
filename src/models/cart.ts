import { Document } from 'mongoose';

export interface CartItem {
    product: any;
    quantity: number;
}

export interface Cart extends Document {
    subscription?: string;
    items: Array<CartItem>;
    value: number;
    created: Date;
    updated: Date;
}
