export class VenzraError extends Error {
    constructor(
        public message: string = 'Resource not found',
        public code: number = 404,
        public detail: Array<string> = []
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

export class ValidationError extends VenzraError {
    constructor(detail: Array<string>) {
        super('Validation failed', 400, detail);
    }
}

export class NotFoundError extends VenzraError {}
