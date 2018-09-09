import { Document } from 'mongoose';

export interface Career extends Document {
    position: string;
    description: string;
    expires: Date;
    created: Date;
    updated: Date;
}
