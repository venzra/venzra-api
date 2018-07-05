import { Schema } from 'mongoose';

const ThemeSchema: Schema = new Schema({
    color: {
        type: String,
        required: true
    }
}, { _id: false });

export { ThemeSchema };
