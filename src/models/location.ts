import { Document } from 'mongoose';

import { Image } from './image';

export interface Location extends Document {
    content: string;
    featureImage: string | Image;
    created: Date;
    updated: Date;
}
