const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

const productsRouter = require('./routes/products');
const ordersRouter = require('./routes/orders');
const categoriesRouter = require('./routes/categories');
const authRouter = require('./routes/auth');

const app = express();
const PORT = process.env.PORT || 3000;

// Ensure data directory exists (for SQLite file)
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
  console.log('Created data directory. Run "npm run init-db" to create the database.');
}

// Ensure uploads directory exists (for product images)
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(uploadsDir));

app.use('/api/products', productsRouter);
app.use('/api/orders', ordersRouter);
app.use('/api/categories', categoriesRouter);
app.use('/api/auth', authRouter);

app.get('/api/health', (req, res) => {
  res.json({ ok: true, message: 'POS API running' });
});

app.listen(PORT, () => {
  console.log(`POS API listening on http://localhost:${PORT}`);
  console.log('  GET  /api/health');
  console.log('  GET  /api/products');
  console.log('  GET  /api/orders');
  console.log('  GET  /api/categories');
  console.log('  POST /api/auth/signup');
  console.log('  POST /api/auth/login');
  console.log('  GET  /api/auth/users');
});
