class ApiError extends Error {
    statusCode: number;
    isOperational: boolean;
    success: boolean;

    constructor(
        statusCode: number,
        message: string,
        isOperational: boolean = true,
        stack: string = ""
    ) {
        super(message);
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        this.success = false;

        if (stack) {
            this.stack = stack;
        } else {
            Error.captureStackTrace(this, this.constructor);
        }
    }
}

export default ApiError;