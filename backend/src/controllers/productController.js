const asyncHandler = require('../utils/asyncHandler');
const productService = require('../services/productService');
const { httpError } = require('../utils/httpError');

const getProducts = asyncHandler(async (req, res) => {
  const products = await productService.getAllProducts(req.query);
  res.json({ ok: true, count: products.length, products });
});

const getProduct = asyncHandler(async (req, res) => {
  const product = await productService.getProductById(req.params.productId);
  if (!product) throw httpError(404, 'Product not found.');
  res.json({ ok: true, product });
});

const createProduct = asyncHandler(async (req, res) => {
  const product = await productService.createProduct(req.body);
  res.status(201).json({ ok: true, product });
});

const updateProduct = asyncHandler(async (req, res) => {
  const product = await productService.updateProduct(req.params.productId, req.body);
  if (!product) throw httpError(404, 'Product not found.');
  res.json({ ok: true, product });
});

const deleteProduct = asyncHandler(async (req, res) => {
  await productService.deleteProduct(req.params.productId);
  res.json({ ok: true, message: 'Product deleted.' });
});

module.exports = { getProducts, getProduct, createProduct, updateProduct, deleteProduct };
