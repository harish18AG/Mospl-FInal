const cors = require('cors');
const express = require('express');
const path = require('path');

const routes = require('./routes');
const { errorHandler, notFoundHandler } = require('./middleware/errorMiddleware');

const app = express();

app.use(
  cors({
    origin: process.env.CLIENT_ORIGIN ? process.env.CLIENT_ORIGIN.split(',') : true,
    credentials: true,
  }),
);
app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));
app.use('/static/products', express.static(path.resolve(__dirname, '..', '..', 'assets', 'products')));

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    app: 'MOSPL',
    timestamp: new Date().toISOString(),
    mode: process.env.NODE_ENV || 'development',
  });
});

app.use('/api', routes);
app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
