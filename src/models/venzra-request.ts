import { Request } from 'express';

import { Account, Customer, Subscription } from '.';

export interface VenzraRequest extends Request {
    venzra: {
        account: Account,
        subscription: Subscription,
        customer: Customer
    }
}
