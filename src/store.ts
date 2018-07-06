import * as express from 'express';
import * as cookieParser from 'cookie-parser';
import * as cors from 'cors';
import * as helmet from 'helmet';
import * as http from 'http';

import { AddressInfo } from 'net';
import { CorsOptions } from 'cors';

import ProductController from './controllers/store/products';
import ShippingController from './controllers/store/shipping';
import SubscriptionController from './controllers/store/subscription';

import VenzraDatabase from './services/database.service';
import VenzraSession from './services/venzra.service';
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
    origin: '*',
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

app.use('/store/products', ProductController);
app.use('/store/shipping', ShippingController);
app.use('/store/subscription', SubscriptionController);

app.use(ErrorService);

/*
 * Create the server
 */
const server = http.createServer(app);
const port = process.env['PORT'];

server.listen(port);
server.on('listening', listening);

function listening() {
    const addr = <AddressInfo>server.address();
    console.log(`Listening on ${addr.address}:${addr.port}`);
}

module.exports = app;
