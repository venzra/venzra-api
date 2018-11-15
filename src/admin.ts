import * as express from 'express';
import * as cookieParser from 'cookie-parser';
import * as cors from 'cors';
import * as helmet from 'helmet';

import { CorsOptions } from 'cors';

import IdentityController from './controllers/admin/identity';

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

app.use(ErrorService);

module.exports = app;
