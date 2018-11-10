import { Document } from 'mongoose';

export interface Cart extends Document {
    subscription?: string;
    items: Array<{ product: any, quantity: number }>;
    value: number;
    created: Date;
    updated: Date;
}
