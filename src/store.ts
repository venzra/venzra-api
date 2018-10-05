import * as express from 'express';
import * as cookieParser from 'cookie-parser';
import * as cors from 'cors';
import * as helmet from 'helmet';
import * as http from 'http';

import { AddressInfo } from 'net';
import { CorsOptions } from 'cors';

import CareerController from './controllers/store/careers';
import CartController from './controllers/store/cart';
import CategoryController from './controllers/store/category';
import ContactController from './controllers/store/contact';
import ContentController from './controllers/store/content';
import CustomerController from './controllers/store/customer';
import IdentityController from './controllers/store/identity';
import ImagesController from './controllers/store/images';
import LocationController from './controllers/store/locations';
import OrdersController from './controllers/store/orders';
import ProductController from './controllers/store/products';
import ShippingController from './controllers/store/shipping';
import SubscriptionController from './controllers/store/subscription';

import VenzraDatabase from './services/database.service';
import VenzraSession from './services/venzra.service';
import VenzraCustomer from './services/customer.service';
import VenzraSubscription from './services/subscription.service';
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
app.use(VenzraSubscription);
app.use(VenzraCustomer);
app.use(VenzraSession);

app.use('/store/careers', CareerController);
app.use('/store/cart', CartController);
app.use('/store/categories', CategoryController);
app.use('/store/contact', ContactController);
app.use('/store/content', ContentController);
app.use('/store/customer', CustomerController);
app.use('/store/identity', IdentityController);
app.use('/store/images', ImagesController);
app.use('/store/locations', LocationController);
app.use('/store/orders', OrdersController);
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
