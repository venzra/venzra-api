import { Product } from './product';

export interface Item {
    product: Product | string;
    quantity: number;
    price: number;
}
