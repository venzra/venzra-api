import { createLogger, format, transports } from 'winston';

import { Request, Response, NextFunction } from 'express';

import { VenzraError } from '../models';

export class ErrorService {

    requiredFields(body: any, fields: Array<string>): Array<{ path: string, kind: string }> {
        return fields.filter((key) => !body[key]).map((key) => ({ path: key, kind: 'required' }));
    }

    static handleError(exception: VenzraError, req: Request, res: Response, next: NextFunction): void {
        const logger = createLogger({
            level: 'warn',
            format: format.combine(
                format.timestamp(),
                format.ms(),
                format.json()
            ),
            transports: [
                new transports.Console()
            ]
        });

        let message = 'Resource not found';
        const detail = new Set();

        switch (exception.name) {
            case 'AcceptedError':
                exception.code = 202;
                logger.info(`[${exception.name}] ${exception.code} - ${exception.message}`);
                break;
            case 'AuthenticationError':
                logger.info(`[${exception.name}] ${exception.code} - ${exception.message}`);
                exception.message = 'Invalid credentials';
                exception.code = 400;
                message = exception.message;
                break;
            case 'ValidationError':
                message = 'Validation failed';
                exception.code = 400;

                if (exception.errors) {
                    exception.detail = Object.values(exception.errors);
                }

                exception.detail.forEach((error) => {
                    if (error.path && error.kind) {
                        detail.add(`${error.path} ${error.kind}`.trim());
                    }
                });

                logger.debug(`[${exception.name}] ${exception.message} - ${exception.detail.join(', ')}`);
                break;
            case 'MongoError':
                exception.code = 400;
                message = 'Record already exists';
                logger.error(`[${exception.name}] ${exception.message}`);
                break;
            case 'AccessDeniedError':
                exception.code = 401;
                message = exception.message;
                break;
            case 'CastError':
            case 'NotFound':
            case 'NotFoundError':
                exception.code = 404;
                logger.warn(`[${exception.name}] ${exception.code} - ${req.url}`);
                break;
            case 'PayloadTooLargeError':
                exception.code = 413;
                message = `Request limit is: ${Math.floor(exception.limit / 1024)} KiB`;
                detail.add(`Received: ${Math.ceil(exception.length / 1024)} KiB`);
                break;
            case 'GatewayError':
                message = 'Third party error';
                exception.code = 503;
                logger.error(`[${exception.name}] ${exception.message}`);
                break;
            case 'StripeError':
                message = 'Payment gateway error';
                exception.code = 503;
                logger.error(`[${exception.name}] ${exception.message}`);
                break;
            case 'MongoNetworkError':
                message = 'Database temporarily unavailable';
                exception.code = 503;
                logger.error(`[${exception.name}] ${exception.message}`);
                break;
            default:
                message = 'Internal server error';
                exception.code = 500;
                logger.warn(`[${exception.name}] ${exception.code} - ${exception.message}`);
        }

        res.status(exception.code).send({ message, detail: [...detail] });
    }

}

export default ErrorService.handleError;
