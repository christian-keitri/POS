const express = require('express');
const router = express.Router();
const db = require('../db');

router.get('/', (req, res) => {
  try {
    const categories = db.prepare('SELECT * FROM categories ORDER BY sort_order, name').all();
    res.json(categories);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', (req, res) => {
  try {
    const { name, description, sort_order } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });
    const result = db.prepare(
      'INSERT INTO categories (name, description, sort_order) VALUES (?, ?, ?)'
    ).run(name, description?.trim() || null, sort_order != null ? Number(sort_order) : 0);
    const category = db.prepare('SELECT * FROM categories WHERE id = ?').get(result.lastInsertRowid);
    res.status(201).json(category);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', (req, res) => {
  try {
    const { name, description, sort_order } = req.body;
    if (!name) return res.status(400).json({ error: 'name is required' });
    const existing = db.prepare('SELECT * FROM categories WHERE id = ?').get(req.params.id);
    if (!existing) return res.status(404).json({ error: 'Category not found' });
    const desc = description !== undefined ? (description?.trim() || null) : existing.description;
    const sort = sort_order != null ? Number(sort_order) : (existing.sort_order ?? 0);
    const result = db.prepare(
      'UPDATE categories SET name = ?, description = ?, sort_order = ? WHERE id = ?'
    ).run(name, desc, sort, req.params.id);
    if (result.changes === 0) return res.status(404).json({ error: 'Category not found' });
    const category = db.prepare('SELECT * FROM categories WHERE id = ?').get(req.params.id);
    res.json(category);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', (req, res) => {
  try {
    const result = db.prepare('DELETE FROM categories WHERE id = ?').run(req.params.id);
    if (result.changes === 0) return res.status(404).json({ error: 'Category not found' });
    res.status(204).send();
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
