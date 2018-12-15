export interface VenzraError {
    name: string;
    code: number;
    message: string;
    detail: Array<{ path: string, kind: string, errors: any }>;
    errors: { [key: string]: { path: string, kind: string, errors: any } };
    limit: number;
    length: number;
}

export class BaseError extends Error {
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

export class AcceptedError extends BaseError {
    constructor(message: string) {
        super(message);
    }
}

export class ValidationError extends BaseError {
    constructor(detail: Array<{ path: string, kind: string }>) {
        super('Validation failed', detail);
    }
}

export class AuthenticationError extends BaseError {
    constructor(reason: string) {
        super(reason);
    }
}

export class AccessDeniedError extends BaseError {
    constructor(reason?: string) {
        super(reason || 'Access Denied');
    }
}

export class StripeError extends BaseError {
    constructor(reason: string) {
        super(reason);
    }
}

export class GatewayError extends BaseError {
    constructor(reason: string) {
        super(reason);
    }
}

export class WebhookError extends BaseError {
    constructor(reason: string) {
        super(reason);
    }
}

export class NotFoundError extends BaseError {}
