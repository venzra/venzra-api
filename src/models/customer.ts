import { Document } from 'mongoose';
import { Address, Subscription } from '.';

export interface Customer extends Document {
    subscription: Subscription;
    identity: string;
    password: {
        salt: string;
        secure: string;
        created: Date;
    };
    addresses: Array<Address>;
    primaryAddress: string;
    access: {
        key: string;
        ip: string;
        created: Date;
    }
    lock: {
        failures: number;
        ip: string;
        updated: Date;
    }
    status: 'ACTIVE' | 'RECOVERY' | 'LOCKED';
    created: Date;
    updated: Date;
}
