import { Document } from 'mongoose';

export interface Address extends Document {
    addressee: string;
    street: string;
    building: string;
    city: string;
    county: string;
    postalCode: string;
    country: string;
}
