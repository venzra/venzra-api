import { Response, NextFunction } from 'express';

import { VenzraRequest } from '../models';

export class VenzraSession {

    static start(req: VenzraRequest, res: Response, next: NextFunction): void {
        req.venzra = req.venzra || {};
        next();
    }

}

export default VenzraSession.start;
