import { Document } from 'mongoose';
import { Subscription } from '.';

export interface Account extends Document {
    _id: any;
    subscription: Subscription;
    identity: string;
    password: {
        salt: string;
        secure: string;
        created: Date;
    };
    validation: {
        key: string;
        expires: Date;
    };
    access: {
        key: string;
        ip: string;
        created: Date;
    };
    lock: {
        failures: number;
        ip: string;
        updated: Date;
    }
    terms: Date;
    status: 'REGISTERED' | 'ACTIVE' | 'RECOVERY' | 'LOCKED' | 'DISABLED';
    created: Date;
    updated: Date;
}
