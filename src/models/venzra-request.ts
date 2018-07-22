import { Request } from 'express';

import { Customer, Subscription } from '.';

export interface VenzraRequest extends Request {
    venzra: {
        subscription: Subscription,
        customer: Customer
    }
}
