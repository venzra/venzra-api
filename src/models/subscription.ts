import { Document } from 'mongoose';
import { Addon, Charges, Contact, Gateway, Theme } from '.';

export interface Subscription extends Document {
    storeName: string;
    features: string[];
    addons: Addon[];
    strapline: string;
    domainName: string;
    additionalDomains: string[];
    icon: string;
    logo: string;
    theme: Theme;
    payment: {
        package: string;
        customer: string;
        subscription: string;
        price: Charges;
        term: Date;
        status: string;
    };
    gateway: Gateway;
    transactions: {
        rate: number,
        base: number
    };
    contact: Contact;
    status: string;
    created: Date;
    updated: Date;
}
