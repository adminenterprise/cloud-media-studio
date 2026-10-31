const express = require('express');
const mysql = require('mysql2/promise');
const os = require('os');

const app = express();
app.use(express.json());

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'app',
  password: process.env.DB_PASSWORD || 'apppass',
  database: process.env.DB_NAME || 'appdb',
  connectionLimit: 5,
  waitForConnections: true,
  queueLimit: 0,
});

app.get('/health', async (_, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'connected' });
  } catch (err) {
    res.json({ status: 'ok', db: 'disconnected', warning: err.message });
  }
});

// Hiện hostname để demo Self-Healing: F5 thấy đổi container/instance
app.get('/api/info', (_, res) => res.json({ hostname: os.hostname() }));

app.get('/api/items', async (_, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM items ORDER BY id DESC');
    res.json(rows);
  } catch (err) {
    console.error('Error in GET /api/items:', err);
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/items', async (req, res) => {
  try {
    if (!req.body || !req.body.name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    await pool.query('INSERT INTO items (name) VALUES (?)', [req.body.name]);
    res.status(201).json({ ok: true });
  } catch (err) {
    console.error('Error in POST /api/items:', err);
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/search', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM items WHERE name LIKE ?', [`%${req.query.q || ''}%`]);
    res.json(rows);
  } catch (err) {
    console.error('Error in GET /api/search:', err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(process.env.PORT || 3000, '0.0.0.0', () => console.log('API up'));