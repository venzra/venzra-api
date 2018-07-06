import { Document } from 'mongoose';

export interface Category extends Document {
    slug: string;
    name: string;
    parent: Category;
    children: Category[];
    description: string;
    featureImage: string;
    created: Date;
    updated: Date;
}
