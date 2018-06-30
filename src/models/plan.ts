import { Document } from 'mongoose';

export interface Plan extends Document {
    _id: any;
    reference: string;
    name: string;
    currency: string;
    price: number;
    interval: number;
    frequency: 'day' | 'week' | 'month' | 'year';
    created: Date;
    updated: Date;
}
