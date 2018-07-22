import { Response, NextFunction } from 'express';

import { AccessDeniedError, VenzraRequest } from '../models';

export class IdentityService {

    validate(req: VenzraRequest, res: Response, next: NextFunction) {
        if(req.venzra.customer && req.venzra.customer._id) {
            next();
        } else {
            next(new AccessDeniedError());
        }
    }

}
