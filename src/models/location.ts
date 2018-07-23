import { Document } from 'mongoose';

export interface Location extends Document {
    content: string;
    created: Date;
    updated: Date;
}
