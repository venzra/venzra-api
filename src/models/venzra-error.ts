export class VenzraError extends Error {
    constructor(
        public message: string = 'Resource not found',
        public detail: Array<{ path: string, kind: string }> = [],
        public errors?: { [key: string]: { path: string, kind: string } },
        public code: number = 404
    ) {
        super(message);
        this.name = this.constructor.name;
    }
}

export class AcceptedError extends VenzraError {
    constructor(message: string) {
        super(message);
    }
}

export class ValidationError extends VenzraError {
    constructor(detail: Array<{ path: string, kind: string }>) {
        super('Validation failed', detail);
    }
}

export class AuthenticationError extends VenzraError {
    constructor(reason: string) {
        super(reason);
    }
}

export class AccessDeniedError extends VenzraError {
    constructor() {
        super('Access Denied');
    }
}

export class GatewayError extends VenzraError {
    constructor(reason: string) {
        super(reason);
    }
}

export class NotFoundError extends VenzraError {}
