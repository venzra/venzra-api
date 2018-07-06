import { Document } from 'mongoose';

export interface Shipping extends Document {
    subscription: string;
    displayName: string;
    cartMinimum: number;
    cartMaximum: number;
    currentPrice: number;
    shipmentTime: number;
    created: Date;
    updated: Date;
}
