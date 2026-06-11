const { httpError } = require('../utils/httpError');

function requireFields(fields) {
  return (req, res, next) => {
    const missing = fields.filter((field) => req.body[field] === undefined || req.body[field] === '');
    if (missing.length) {
      return next(httpError(400, `Missing required fields: ${missing.join(', ')}`));
    }
    return next();
  };
}

module.exports = { requireFields };
