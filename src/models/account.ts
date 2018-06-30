import { Document } from 'mongoose';

export interface Account extends Document {
    _id: any;
    identity: string;
    validation: {
        key: string;
        expires: Date;
    };
    terms: Date;
    status: 'REGISTERED' | 'ACTIVE' | 'RECOVERY' | 'LOCKED' | 'DISABLED';
    created: Date;
    updated: Date;
}
