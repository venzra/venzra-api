import { Document } from 'mongoose';

export interface Image extends Document {
    subscription: string;
    name: string;
    usage: string;
    size: number;
    created: Date;
    updated: Date;
}
