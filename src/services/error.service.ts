import { createLogger, format, transports } from 'winston';

import { Request, Response, NextFunction } from 'express';

import { VenzraError } from '../models';

export class ErrorService {

    requiredFields(body: any, fields: Array<string>): Array<string> {
        return fields.filter((key) => !body[key]).map((key) => `${key} required`);
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
        let detail: Array<string> = [];

        switch(exception.name) {
            case 'AcceptedError':
                logger.info(`${exception.code} - ${exception.message}`);
                break;
            case 'ValidationError':
                message = exception.message;
                detail = exception.detail;
                logger.debug(`${exception.message} - ${exception.detail.join(', ')}`);
                break;
            case 'NotFoundError':
                logger.warn(`${exception.code} - ${req.url}`);
                break;
            case 'MongoNetworkError':
                message = 'Database temporarily unavailable';
                exception.code = 503;
                logger.error(exception.message);
                break;
            default:
                message = 'Internal server error';
                logger.warn(`${exception.name} - ${exception.code} - ${exception.message}`);
                console.log(exception.name, exception.code, exception.message);
        }

        res.status(exception.code).send({ message, detail });
    }

}

export default ErrorService.handleError;
