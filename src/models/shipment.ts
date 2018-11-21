import { Document } from 'mongoose';

export interface Shipment extends Document {
    reference: string;
    name: string;
    courier: string;
    tracking: string;
    price: number;
}
