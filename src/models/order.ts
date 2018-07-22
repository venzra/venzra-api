import { Document } from 'mongoose';
import { Address, History, Item, Shipment } from '.';

export interface Order extends Document {
    _id: string;
    subscription: string;
    customer: string;
    reference: string;
    items: Array<Item>;
    shipping: Shipment;
    destination: Address;
    billing: Address;
    payment: {
        reference: string;
        transaction: string;
        card: string;
        brand: string;
        fee: {
            venzra: { amount: number, currency: string };
            gateway: { amount: number, currency: string };
            total: number;
        };
        value: number;
        refund: number;
    };
    history: Array<History>;
    status: string;
    created: Date;
    updated: Date;
}
