export class ValidationError extends Error {
  constructor(message) {
    super(message);
    this.name = "ValidationError";
    this.statusCode = 400;
  }
}

export class UpstreamError extends Error {
  constructor(message, options = {}) {
    super(message, options);
    this.name = "UpstreamError";
    this.statusCode = 502;
  }
}
