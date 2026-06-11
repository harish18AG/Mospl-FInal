const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

const getNotifications = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = await db.collection('notifications').get();
    const notifications = snapshot.docs
      .map((doc) => ({ notificationId: doc.id, ...doc.data() }))
      .filter((item) => req.user.role === 'admin' || !item.userId || item.userId === req.user.uid)
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    res.json({ ok: true, notifications });
    return;
  }
  const notifications = req.user.role === 'admin'
    ? store.notifications
    : store.notifications.filter((item) => !item.userId || item.userId === req.user.uid);
  res.json({ ok: true, notifications });
});

const createNotification = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('notifications').doc();
    const notification = {
      notificationId: ref.id,
      userId: req.body.userId || null,
      title: req.body.title,
      body: req.body.body,
      read: false,
      createdAt: new Date().toISOString(),
    };
    await ref.set(notification);
    res.status(201).json({ ok: true, notification });
    return;
  }
  const notification = {
    notificationId: `NOT-${Date.now()}`,
    userId: req.body.userId || null,
    title: req.body.title,
    body: req.body.body,
    read: false,
    createdAt: new Date().toISOString(),
  };
  store.notifications.unshift(notification);
  res.status(201).json({ ok: true, notification });
});

const markRead = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('notifications').doc(req.params.notificationId);
    await ref.set({ read: true, updatedAt: new Date().toISOString() }, { merge: true });
    const doc = await ref.get();
    res.json({ ok: true, notification: doc.exists ? { notificationId: doc.id, ...doc.data() } : null });
    return;
  }
  const notification = store.notifications.find((item) => item.notificationId === req.params.notificationId);
  if (notification) notification.read = true;
  res.json({ ok: true, notification });
});

module.exports = { getNotifications, createNotification, markRead };
