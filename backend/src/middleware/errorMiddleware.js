const { HttpError } = require('../utils/httpError');

function notFoundHandler(req, res, next) {
  next(new HttpError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

function errorHandler(error, req, res, next) {
  if (res.headersSent) return next(error);
  const status = error.status || 500;
  res.status(status).json({
    ok: false,
    message: error.message || 'Internal server error',
    details: error.details || null,
  });
}

module.exports = { notFoundHandler, errorHandler };
