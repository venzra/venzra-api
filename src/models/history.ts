import { Document } from 'mongoose';

export interface History extends Document {
    account?: string;
    field: string;
    previous: any;
    next: any;
    updated?: Date;
}
