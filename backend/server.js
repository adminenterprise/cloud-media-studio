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
});

app.get('/health', (_, res) => res.json({ status: 'ok' }));

// Hiện hostname để demo Self-Healing: F5 thấy đổi container/instance
app.get('/api/info', (_, res) => res.json({ hostname: os.hostname() }));

app.get('/api/items', async (_, res) => {
  const [rows] = await pool.query('SELECT * FROM items ORDER BY id DESC');
  res.json(rows);
});

app.post('/api/items', async (req, res) => {
  await pool.query('INSERT INTO items (name) VALUES (?)', [req.body.name]);
  res.status(201).json({ ok: true });
});

app.get('/api/search', async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM items WHERE name LIKE ?', [`%${req.query.q || ''}%`]);
  res.json(rows);
});

app.listen(process.env.PORT || 3000, '0.0.0.0', () => console.log('API up'));