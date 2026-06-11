const asyncHandler = require('../utils/asyncHandler');
const authService = require('../services/authService');

const register = asyncHandler(async (req, res) => {
  const result = await authService.register(req.body);
  res.status(201).json({ ok: true, ...result });
});

const login = asyncHandler(async (req, res) => {
  const result = await authService.login(req.body);
  res.json({ ok: true, ...result });
});

const firebaseSession = asyncHandler(async (req, res) => {
  const result = await authService.firebaseSession(req.body);
  res.json({ ok: true, ...result });
});

const logout = asyncHandler(async (req, res) => {
  res.json({ ok: true, message: 'Client token cleared. Firebase session should be signed out on device.' });
});

const forgotPassword = asyncHandler(async (req, res) => {
  const result = await authService.forgotPassword(req.body.email);
  res.json({ ok: true, ...result });
});

const currentUser = asyncHandler(async (req, res) => {
  res.json({ ok: true, user: req.user });
});

const updateProfile = asyncHandler(async (req, res) => {
  const user = await authService.updateProfile(req.user.uid, req.body);
  res.json({ ok: true, user });
});

module.exports = { register, login, firebaseSession, logout, forgotPassword, currentUser, updateProfile };
