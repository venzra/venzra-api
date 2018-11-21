import { Document } from 'mongoose';

import { Category } from './category';
import { History } from './history';
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
    history: Array<History>;
    status: string;
    created: Date;
    updated: Date;
}
