import { createLogger, format, transports } from 'winston';

import { Request, Response, NextFunction } from 'express';

import { VenzraError } from '../models';

export class ErrorService {

    requiredFields(body: any, fields: Array<string>): Array<{ path: string, kind: string}> {
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

        switch(exception.name) {
            case 'AuthenticationError':
                logger.info(`[${exception.name}] ${exception.code} - ${exception.message}`);
                message = 'Invalid credentials';
                break;
            case 'AccessDeniedError':
            case 'BadRequestError':
                message = exception.message;
                break;
            case 'AcceptedError':
                logger.info(`[${exception.name}] ${exception.code} - ${exception.message}`);
                break;
            case 'ValidationError':
                message = exception.message;

                exception.detail.forEach((error) => {
                    detail.add(`${error.path} ${error.kind}`.trim());
                });

                logger.debug(`[${exception.name}] ${exception.message} - ${exception.detail.join(', ')}`);
                break;
            case 'NotFoundError':
                logger.warn(`[${exception.name}] ${exception.code} - ${req.url}`);
                break;
            case 'GatewayError':
                message = 'Third party error';
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
