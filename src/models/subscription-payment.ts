import { Charges } from '.';

export interface SubscriptionPayment {
    package: string;
    customer: string;
    subscription: string;
    price: Charges;
    term: Date;
    status: string;
}
