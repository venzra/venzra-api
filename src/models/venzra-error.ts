export class VenzraError extends Error {
    constructor(
        public message: string = 'Resource not found',
        public code: number = 404,
        public detail: Array<{ path: string, kind: string}> = []
    ) {
        super(message);
        this.name = this.constructor.name;
    }
}

export class AcceptedError extends VenzraError {
    constructor(message: string) {
        super(message, 202);
    }
}

export class BadRequestError extends VenzraError {
    constructor(reason: string) {
        super(reason, 400);
    }
}

export class ValidationError extends VenzraError {
    constructor(detail: Array<{ path: string, kind: string}>) {
        super('Validation failed', 400, detail);
    }
}

export class AuthenticationError extends VenzraError {
    constructor(reason: string) {
        super(reason, 400);
    }
}

export class AccessDeniedError extends VenzraError {
    constructor() {
        super('Access Denied', 401);
    }
}

export class GatewayError extends VenzraError {
    constructor(reason: string) {
        super(reason, 503);
    }
}

export class NotFoundError extends VenzraError {}
