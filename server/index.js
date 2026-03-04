const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const morgan = require('morgan');

const productsRouter = require('./routes/products');
const ordersRouter = require('./routes/orders');
const categoriesRouter = require('./routes/categories');
const authRouter = require('./routes/auth');

const app = express();
const isProduction = process.env.NODE_ENV === 'production';
const PORT = process.env.PORT || 3000;

// Request logging
app.use(morgan(isProduction ? 'combined' : 'dev'));

// CORS: restrict origin in production
const corsOrigin = process.env.CORS_ORIGIN;
const corsOptions = corsOrigin
  ? { origin: corsOrigin.split(',').map((o) => o.trim()).filter(Boolean), credentials: true }
  : {};
app.use(cors(corsOptions));

// Ensure data directory exists (for SQLite file)
const dataDir = path.dirname(process.env.DB_PATH || path.join(__dirname, 'data', 'pos.db'));
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
  if (!isProduction) console.log('Created data directory. Run "npm run init-db" to create the database.');
}

// Ensure uploads directory exists (for product/profile images)
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(express.json({ limit: '1mb' }));
app.use('/uploads', express.static(uploadsDir));

app.use('/api/products', productsRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/categories', categoriesRouter);
app.use('/api/auth', authRouter);

app.get('/api/health', (req, res) => {
  res.json({ ok: true, message: 'POS API running' });
});

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Global error handler: do not leak internal errors in production
app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);
  console.error(err);
  const message = isProduction ? 'Internal server error' : (err.message || 'Internal server error');
  res.status(500).json({ error: message });
});

app.listen(PORT, () => {
  console.log(`POS API listening on http://localhost:${PORT} (NODE_ENV=${process.env.NODE_ENV || 'development'})`);
  console.log('  GET  /api/health');
  console.log('  GET  /api/products');
  console.log('  GET  /api/orders');
  console.log('  GET  /api/categories');
  console.log('  POST /api/auth/signup');
  console.log('  POST /api/auth/login');
  console.log('  GET  /api/auth/users');
});
