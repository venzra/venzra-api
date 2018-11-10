import { Document } from 'mongoose';
import { Category } from './category';
import { Image } from './image';

export interface Product extends Document {
    subscription: string;
    slug: string;
    code: string;
    displayName: string;
    promotionalImage: Image | string;
    previousPrice: number;
    currentPrice: number;
    categories: Array<Category>;
    status: string;
    created: Date;
    updated: Date;
}
