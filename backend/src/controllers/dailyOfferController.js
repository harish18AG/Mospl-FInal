const asyncHandler = require('../utils/asyncHandler');
const { db, isFirebaseConfigured } = require('../config/firebase');
const store = require('../services/store');

async function getDailyOffers() {
  if (isFirebaseConfigured && db) {
    try {
      const doc = await db.collection('settings').doc('daily_offers').get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
  }
  return store.dailyOffers;
}

const getOffers = asyncHandler(async (req, res) => {
  const offers = await getDailyOffers();
  res.json({ ok: true, dailyOffers: offers });
});

const updateOffers = asyncHandler(async (req, res) => {
  const payload = req.body || {};
  const updated = {
    monday: Number(payload.monday !== undefined ? payload.monday : 10),
    tuesday: Number(payload.tuesday !== undefined ? payload.tuesday : 15),
    wednesday: Number(payload.wednesday !== undefined ? payload.wednesday : 20),
    thursday: Number(payload.thursday !== undefined ? payload.thursday : 25),
    friday: Number(payload.friday !== undefined ? payload.friday : 30),
    saturday: Number(payload.saturday !== undefined ? payload.saturday : 35),
    sunday: Number(payload.sunday !== undefined ? payload.sunday : 40),
  };

  store.dailyOffers = updated;

  if (isFirebaseConfigured && db) {
    try {
      await db.collection('settings').doc('daily_offers').set(updated);
    } catch (_) {}
  }
  res.json({ ok: true, dailyOffers: updated });
});

module.exports = { getOffers, updateOffers, getDailyOffers };
