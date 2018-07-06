import { Document } from 'mongoose';
import { Category } from './category';

export interface Product extends Document {
    subscription: string;
    slug: string;
    code: string;
    displayName: string;
    previousPrice: number;
    currentPrice: number;
    categories: Array<Category>;
    status: string;
    created: Date;
    updated: Date;
}
