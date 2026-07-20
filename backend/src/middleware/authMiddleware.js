const jwt = require('jsonwebtoken');

const { httpError } = require('../utils/httpError');

function signApiToken(user) {
  return jwt.sign(
    {
      uid: user.uid,
      email: user.email,
      role: user.role || 'customer',
    },
    process.env.JWT_SECRET || 'mospl-dev-secret',
    { expiresIn: '7d' },
  );
}

function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next(httpError(401, 'Authentication token required.'));
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || 'mospl-dev-secret');
    return next();
  } catch (error) {
    return next(httpError(401, 'Invalid or expired authentication token.'));
  }
}

function requireAdmin(req, res, next) {
  if (!req.user) return next(httpError(401, 'Authentication token required.'));
  if (req.user.role !== 'admin') return next(httpError(403, 'Admin role required.'));
  return next();
}

function optionalAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    req.user = null;
    return next();
  }
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET || 'mospl-dev-secret');
    return next();
  } catch (error) {
    req.user = null;
    return next();
  }
}

module.exports = { signApiToken, requireAuth, requireAdmin, optionalAuth };

