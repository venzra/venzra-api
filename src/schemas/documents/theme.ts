import { Schema } from 'mongoose';

const ThemeSchema: Schema = new Schema({
    color: {
        type: String,
        trim: true,
        required: true,
        lowercase: true
    }
}, { _id: false });

export { ThemeSchema };
