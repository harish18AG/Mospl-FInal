const asyncHandler = require('../utils/asyncHandler');
const store = require('../services/store');

const getCategories = asyncHandler(async (req, res) => {
  res.json({ ok: true, count: store.categories.length, categories: store.categories });
});

const createCategory = asyncHandler(async (req, res) => {
  const { id, name, subtitle, imageUrl } = req.body;
  if (!name) {
    res.status(400);
    throw new Error('Category name is required.');
  }
  const categoryId = id || name.toLowerCase().replace(/\s+/g, '-');
  const newCategory = {
    id: categoryId,
    name,
    subtitle: subtitle || '',
    imageUrl: imageUrl || '',
    productCount: 0,
  };
  
  const existingIndex = store.categories.findIndex((c) => c.name.toLowerCase() === name.toLowerCase());
  if (existingIndex >= 0) {
    store.categories[existingIndex] = { ...store.categories[existingIndex], ...newCategory };
  } else {
    store.categories.push(newCategory);
  }
  
  res.status(201).json({ ok: true, category: newCategory });
});

const deleteCategory = asyncHandler(async (req, res) => {
  const { categoryId } = req.params;
  const index = store.categories.findIndex((c) => c.id === categoryId);
  if (index < 0) {
    res.status(404);
    throw new Error('Category not found.');
  }
  store.categories.splice(index, 1);
  res.json({ ok: true, message: 'Category deleted successfully.' });
});

module.exports = { getCategories, createCategory, deleteCategory };
