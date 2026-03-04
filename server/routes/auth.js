const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// Basic validation helpers
const isValidEmail = (e) => typeof e === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e.trim());
const isValidPassword = (p) => typeof p === 'string' && p.length >= 8;

// POST /api/auth/signup - create account
router.post('/signup', (req, res) => {
  try {
    const { email, password, business_name } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (!isValidPassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (existing) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    const password_hash = bcrypt.hashSync(password.trim(), 10);
    const result = db.prepare(
      'INSERT INTO users (email, password_hash, business_name, role) VALUES (?, ?, ?, ?)'
    ).run(email.toLowerCase().trim(), password_hash, business_name?.trim() || null, 'admin');
    const user = db.prepare('SELECT id, email, business_name, role, created_at FROM users WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// POST /api/auth/login - verify and return user
router.post('/login', (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    const user = db.prepare('SELECT id, email, password_hash, business_name, role, created_at FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    if (!bcrypt.compareSync(password.trim(), user.password_hash)) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const { password_hash: _, ...safe } = user;
    res.json(safe);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/auth/users - list accounts (no passwords)
router.get('/users', (req, res) => {
  try {
    const users = db.prepare('SELECT id, email, business_name, role, created_at FROM users ORDER BY created_at DESC').all();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

module.exports = router;
