const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const db = require('../db');
const { safeErrorMessage } = require('../lib/safeError');

// Basic validation helpers
const isValidEmail = (e) => typeof e === 'string' && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(e.trim());
const isValidPassword = (p) => typeof p === 'string' && p.length >= 8;
const validRoles = ['admin', 'manager', 'cashier'];

// POST /api/auth/signup - create account
router.post('/signup', (req, res) => {
  try {
    const { email, password, business_name, role: requestedRole } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (!isValidPassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    const role = requestedRole && validRoles.includes(requestedRole) ? requestedRole : 'cashier';
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (existing) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    const password_hash = bcrypt.hashSync(password.trim(), 10);
    const result = db.prepare(
      'INSERT INTO users (email, password_hash, business_name, role) VALUES (?, ?, ?, ?)'
    ).run(email.toLowerCase().trim(), password_hash, business_name?.trim() || null, role);
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
    const { role, is_active } = req.query;
    let sql = 'SELECT id, email, business_name, display_name, role, is_active, created_at, updated_at FROM users WHERE 1=1';
    const params = [];
    
    if (role) {
      sql += ' AND role = ?';
      params.push(role);
    }
    
    if (is_active !== undefined) {
      sql += ' AND is_active = ?';
      params.push(is_active === '1' || is_active === 'true' ? 1 : 0);
    }
    
    sql += ' ORDER BY created_at DESC';
    
    const users = db.prepare(sql).all(...params);
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// GET /api/auth/users/:id - get single user
router.get('/users/:id', (req, res) => {
  try {
    const user = db.prepare('SELECT id, email, business_name, display_name, role, is_active, created_at, updated_at FROM users WHERE id = ?').get(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// PUT /api/auth/users/:id - update user (admin only)
router.put('/users/:id', (req, res) => {
  try {
    const { email, business_name, display_name, role, is_active, password } = req.body;
    const id = req.params.id;
    
    const existing = db.prepare('SELECT * FROM users WHERE id = ?').get(id);
    if (!existing) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Validate role if provided
    const validRoles = ['admin', 'manager', 'cashier'];
    if (role && !validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role. Must be: admin, manager, or cashier' });
    }

    const updates = {};
    if (email !== undefined) {
      if (!isValidEmail(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
      }
      // Check if email is already taken by another user
      const emailTaken = db.prepare('SELECT id FROM users WHERE email = ? AND id != ?').get(email.toLowerCase().trim(), id);
      if (emailTaken) {
        return res.status(400).json({ error: 'Email already taken' });
      }
      updates.email = email.toLowerCase().trim();
    }
    
    if (business_name !== undefined) updates.business_name = business_name?.trim() || null;
    if (display_name !== undefined) updates.display_name = display_name?.trim() || null;
    if (role !== undefined) updates.role = role;
    if (is_active !== undefined) updates.is_active = is_active ? 1 : 0;
    
    // Handle password update separately
    if (password) {
      if (!isValidPassword(password)) {
        return res.status(400).json({ error: 'Password must be at least 8 characters' });
      }
      updates.password_hash = bcrypt.hashSync(password.trim(), 10);
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    // Build update query
    const fields = Object.keys(updates).map(key => `${key} = ?`).join(', ');
    const values = Object.values(updates);
    
    db.prepare(`UPDATE users SET ${fields}, updated_at = datetime('now') WHERE id = ?`).run(...values, id);
    
    const user = db.prepare('SELECT id, email, business_name, display_name, role, is_active, created_at, updated_at FROM users WHERE id = ?').get(id);
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// DELETE /api/auth/users/:id - deactivate user (admin only)
router.delete('/users/:id', (req, res) => {
  try {
    const id = req.params.id;
    const existing = db.prepare('SELECT id FROM users WHERE id = ?').get(id);
    if (!existing) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Soft delete by setting is_active to 0
    db.prepare('UPDATE users SET is_active = 0, updated_at = datetime(\'now\') WHERE id = ?').run(id);
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

// POST /api/auth/users - create new user (admin only)
router.post('/users', (req, res) => {
  try {
    const { email, password, business_name, display_name, role = 'cashier' } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }
    if (!isValidEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    if (!isValidPassword(password)) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }
    
    const validRoles = ['admin', 'manager', 'cashier'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({ error: 'Invalid role. Must be: admin, manager, or cashier' });
    }
    
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email.toLowerCase().trim());
    if (existing) {
      return res.status(400).json({ error: 'Email already registered' });
    }
    
    const password_hash = bcrypt.hashSync(password.trim(), 10);
    const result = db.prepare(
      'INSERT INTO users (email, password_hash, business_name, display_name, role) VALUES (?, ?, ?, ?, ?)'
    ).run(
      email.toLowerCase().trim(),
      password_hash,
      business_name?.trim() || null,
      display_name?.trim() || null,
      role
    );
    
    const user = db.prepare('SELECT id, email, business_name, display_name, role, is_active, created_at FROM users WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(user);
  } catch (err) {
    res.status(500).json({ error: safeErrorMessage(err) });
  }
});

module.exports = router;
