class HttpError extends Error {
  constructor(status, message, details = null) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

function httpError(status, message, details) {
  return new HttpError(status, message, details);
}

module.exports = { HttpError, httpError };
