const asyncHandler = require('../utils/asyncHandler');
const store = require('../services/store');

const getCategories = asyncHandler(async (req, res) => {
  res.json({ ok: true, count: store.categories.length, categories: store.categories });
});

module.exports = { getCategories };
