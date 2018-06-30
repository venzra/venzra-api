import * as express from 'express';
import * as cors from 'cors';
import * as helmet from 'helmet';
import * as http from 'http';

import { AddressInfo } from 'net';
import { CorsOptions } from 'cors';

import IdentityController from './controllers/admin/identity';

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
const whitelist = [process.env['MARKETING_URL'], process.env['ADMIN_URL']];
const corsOpts: CorsOptions = {
    origin: (origin, callback) => callback(null, whitelist.includes(origin))
};

app.enable('trust proxy');
app.use(helmet());
app.use(cors(corsOpts));

/*
 * Register routing endpoints
 */
app.use('/admin/identity', IdentityController);

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
