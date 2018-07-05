import { Document } from 'mongoose';

import { CartItem, Shipment } from '.';

export interface Cart extends Document {
    subscription?: string;
    items: CartItem[];
    shipping: Shipment;
    value: number;
    created: Date;
    updated: Date;
}
