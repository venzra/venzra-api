import * as express from 'express';
import * as cookieParser from 'cookie-parser';
import * as cors from 'cors';
import * as helmet from 'helmet';

import { CorsOptions } from 'cors';

import IdentityController from './controllers/admin/identity';
import CareersController from './controllers/admin/careers';
import CategoryController from './controllers/admin/category';
import ContentController from './controllers/admin/content';
import ImageController from './controllers/admin/images';
import LocationController from './controllers/admin/locations';

import VenzraSession from './services/session.service';
import VenzraDatabase from './services/database.service';
import ErrorService from './services/error.service';

/*
 * Load up the App
 */
const app: express.Application = express();

/*
 * Database connection
 */
app.use(VenzraDatabase);

/*
 * Configure security elements
 */
const corsOpts: CorsOptions = {
    origin: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'HEAD'],
    allowedHeaders: ['Content-Type'],
    credentials: true,
    optionsSuccessStatus: 200
};

app.enable('trust proxy');
app.use(helmet());
app.options('*', cors(corsOpts));
app.use(cors(corsOpts));
app.use(cookieParser());

/*
 * Register routing endpoints
 */
app.use(VenzraSession);

app.use('/admin/identity', IdentityController);
app.use('/admin/careers', CareersController);
app.use('/admin/categories', CategoryController);
app.use('/admin/content', ContentController);
app.use('/admin/images', ImageController);
app.use('/admin/locations', LocationController);

app.use(ErrorService);

module.exports = app;
