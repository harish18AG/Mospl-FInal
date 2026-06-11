const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');
const { httpError } = require('../utils/httpError');

const list = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const snapshot = req.user.role === 'admin'
      ? await db.collection('support_tickets').get()
      : await db.collection('support_tickets').where('userId', '==', req.user.uid).get();
    const tickets = snapshot.docs
      .map((doc) => ({ ticketId: doc.id, ...doc.data() }))
      .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    res.json({ ok: true, tickets });
    return;
  }
  const tickets = req.user.role === 'admin'
    ? store.supportTickets
    : store.supportTickets.filter((ticket) => ticket.userId === req.user.uid);
  res.json({ ok: true, tickets });
});

const create = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('support_tickets').doc();
    const ticket = {
      ticketId: ref.id,
      userId: req.user.uid,
      subject: req.body.subject,
      message: req.body.message,
      status: 'open',
      createdAt: new Date().toISOString(),
    };
    await ref.set(ticket);
    res.status(201).json({ ok: true, ticket });
    return;
  }
  const ticket = {
    ticketId: `TICKET-${Date.now()}`,
    userId: req.user.uid,
    subject: req.body.subject,
    message: req.body.message,
    status: 'open',
    createdAt: new Date().toISOString(),
  };
  store.supportTickets.unshift(ticket);
  res.status(201).json({ ok: true, ticket });
});

const update = asyncHandler(async (req, res) => {
  if (isFirebaseConfigured && db) {
    const ref = db.collection('support_tickets').doc(req.params.ticketId);
    const doc = await ref.get();
    if (!doc.exists) throw httpError(404, 'Support ticket not found.');
    await ref.set({
      status: req.body.status || doc.data().status,
      reply: req.body.reply || doc.data().reply || null,
      updatedAt: new Date().toISOString(),
    }, { merge: true });
    const updated = await ref.get();
    res.json({ ok: true, ticket: { ticketId: updated.id, ...updated.data() } });
    return;
  }
  const ticket = store.supportTickets.find((item) => item.ticketId === req.params.ticketId);
  if (!ticket) throw httpError(404, 'Support ticket not found.');
  ticket.status = req.body.status || ticket.status;
  ticket.reply = req.body.reply || ticket.reply;
  ticket.updatedAt = new Date().toISOString();
  res.json({ ok: true, ticket });
});

module.exports = { list, create, update };
