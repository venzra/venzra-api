import { Document } from 'mongoose';

export interface Content extends Document {
    content: string;
    usage: string;
    created: Date;
    updated: Date;
}
