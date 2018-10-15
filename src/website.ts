import * as express from 'express';
import * as cors from 'cors';
import * as helmet from 'helmet';

import { CorsOptions } from 'cors';

import IdentityController from './controllers/website/identity';
import SubscriptionController from './controllers/website/subscription';
import SupportController from './controllers/website/support';
import ValidationController from './controllers/website/validation';

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

/*
 * Register routing endpoints
 */
app.use('/website/identity', IdentityController);
app.use('/website/subscription', SubscriptionController);
app.use('/website/support', SupportController);
app.use('/website/validation', ValidationController);

app.use(ErrorService);

module.exports = app;
