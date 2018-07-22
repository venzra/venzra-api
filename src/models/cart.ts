import { Document } from 'mongoose';

import { Shipment } from '.';

export interface Cart extends Document {
    subscription?: string;
    items: Array<{ product: any, quantity: number }>;
    shipping: Shipment;
    value: number;
    created: Date;
    updated: Date;
}
