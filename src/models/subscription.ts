import { Document } from 'mongoose';
import { Addon, Contact, Fee, Gateway, SubscriptionPayment, Theme } from '.';

export interface Subscription extends Document {
    storeName: string;
    features: string[];
    addons: Addon[];
    strapline: string;
    domainName: string;
    icon: string;
    logo: string;
    theme: Theme;
    payment: SubscriptionPayment;
    gateway: Gateway;
    transactions: Fee;
    contact: Contact;
    status: string;
    created: Date;
    updated: Date;
}
