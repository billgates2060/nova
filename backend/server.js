import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import fs from 'node:fs';
import path from 'node:path';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const DB_PATH = process.env.DB_PATH || './data/nova.db';
const DATA_DIR = path.dirname(DB_PATH);
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-me';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@nova.local';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';

async function createDb() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  const db = await open({ filename: DB_PATH, driver: sqlite3.Database });
  await db.exec(`
    PRAGMA foreign_keys = ON;
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      status TEXT NOT NULL DEFAULT 'active',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      account_id INTEGER,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      total_price REAL NOT NULL,
      sale_date TEXT NOT NULL,
      account_id INTEGER,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY(product_id) REFERENCES products(id)
    );
  `);

  const safeAlter = async (sql) => { try { await db.exec(sql); } catch (_) {} };
  await safeAlter("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user'");
  await safeAlter("ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'active'");
  await safeAlter('ALTER TABLE products ADD COLUMN account_id INTEGER');
  await safeAlter('ALTER TABLE sales ADD COLUMN account_id INTEGER');

  // Seed default admin
  const existingAdmin = await db.get('SELECT id FROM users WHERE email = ?', [ADMIN_EMAIL]);
  if (!existingAdmin) {
    const hash = await bcrypt.hash(ADMIN_PASSWORD, 10);
    await db.run("INSERT INTO users (email, password, role, status) VALUES (?, ?, 'admin', 'active')", [ADMIN_EMAIL, hash]);
    console.log(`Created default admin: ${ADMIN_EMAIL}`);
  }
  return db;
}

let dbPromise = createDb();

// Health
app.get('/health', (_req, res) => res.json({ ok: true }));

// Auth (demo only, no hashing here; replace in prod)
app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });
    const db = await dbPromise;
    const user = await db.get('SELECT id, email, password, role, status FROM users WHERE email = ?', [email]);
    if (!user) return res.status(401).json({ error: 'invalid_credentials' });
    if (user.status !== 'active') return res.status(403).json({ error: 'account_blocked' });
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'invalid_credentials' });
    const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, email: user.email, role: user.role } });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'missing_token' });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload; // { id, email, role }
    next();
  } catch {
    return res.status(401).json({ error: 'invalid_token' });
  }
}

function requireAdmin(req, res, next) {
  if (req?.user?.role !== 'admin') return res.status(403).json({ error: 'forbidden' });
  next();
}

// Admin user management
app.get('/users', auth, requireAdmin, async (_req, res) => {
  const db = await dbPromise;
  const users = await db.all('SELECT id, email, role, status, created_at FROM users ORDER BY id DESC');
  res.json(users);
});

app.post('/users', auth, requireAdmin, async (req, res) => {
  try {
    const { email, password, role = 'user' } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });
    if (!['user', 'admin'].includes(role)) return res.status(400).json({ error: 'invalid_role' });
    const db = await dbPromise;
    const hash = await bcrypt.hash(password, 10);
    const result = await db.run('INSERT INTO users (email, password, role, status) VALUES (?, ?, ?, "active")', [email, hash, role]);
    const created = await db.get('SELECT id, email, role, status, created_at FROM users WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch (e) {
    if (String(e).includes('UNIQUE')) return res.status(409).json({ error: 'email_exists' });
    res.status(500).json({ error: 'internal_error' });
  }
});

app.patch('/users/:id/block', auth, requireAdmin, async (req, res) => {
  const db = await dbPromise;
  await db.run('UPDATE users SET status = "blocked" WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});

app.patch('/users/:id/unblock', auth, requireAdmin, async (req, res) => {
  const db = await dbPromise;
  await db.run('UPDATE users SET status = "active" WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});

// Products
app.get('/products', auth, async (req, res) => {
  const db = await dbPromise;
  const rows = await db.all('SELECT * FROM products WHERE account_id = ? OR account_id IS NULL ORDER BY id DESC', [req.user.id]);
  res.json(rows);
});

app.post('/products', auth, async (req, res) => {
  try {
    const { name, price, stock } = req.body;
    if (!name || price == null) return res.status(400).json({ error: 'name and price required' });
    const db = await dbPromise;
    const result = await db.run('INSERT INTO products (name, price, stock, account_id) VALUES (?, ?, ?, ?)', [name, price, stock ?? 0, req.user.id]);
    const created = await db.get('SELECT * FROM products WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Update product
app.put('/products/:id', auth, async (req, res) => {
  try {
    const { name, price, stock } = req.body;
    const db = await dbPromise;
    await db.run(
      'UPDATE products SET name = ?, price = ?, stock = ? WHERE id = ? AND (account_id = ? OR account_id IS NULL)',
      [name, price, stock ?? 0, req.params.id, req.user.id]
    );
    const updated = await db.get('SELECT * FROM products WHERE id = ?', [req.params.id]);
    if (!updated) return res.status(404).json({ error: 'not_found' });
    res.json(updated);
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Delete product
app.delete('/products/:id', auth, async (req, res) => {
  try {
    const db = await dbPromise;
    await db.run('DELETE FROM products WHERE id = ? AND (account_id = ? OR account_id IS NULL)', [req.params.id, req.user.id]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Sales
app.get('/sales', auth, async (req, res) => {
  const db = await dbPromise;
  const rows = await db.all('SELECT * FROM sales WHERE account_id = ? ORDER BY sale_date DESC', [req.user.id]);
  res.json(rows);
});

app.post('/sales', auth, async (req, res) => {
  try {
    const { product_id, product_name, quantity, unit_price, sale_date } = req.body;
    if (!product_id || !product_name || !quantity || unit_price == null || !sale_date) {
      return res.status(400).json({ error: 'missing fields' });
    }
    const total_price = Number(unit_price) * Number(quantity);
    const db = await dbPromise;
    const result = await db.run(
      `INSERT INTO sales (product_id, product_name, quantity, unit_price, total_price, sale_date, account_id)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [product_id, product_name, quantity, unit_price, total_price, sale_date, req.user.id]
    );
    const created = await db.get('SELECT * FROM sales WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Daily summary
app.get('/summary/daily', auth, async (req, res) => {
  const { date } = req.query; // yyyy-mm-dd
  if (!date) return res.status(400).json({ error: 'date required (yyyy-mm-dd)' });
  const db = await dbPromise;
  const rows = await db.all(
    `SELECT * FROM sales WHERE account_id = ? AND substr(sale_date, 1, 10) = ? ORDER BY sale_date DESC`,
    [req.user.id, String(date)]
  );
  const totalSales = rows.reduce((sum, r) => sum + (r.total_price ?? 0), 0);
  const totalProductsSold = rows.reduce((sum, r) => sum + (r.quantity ?? 0), 0);
  res.json({ date, totalSales, totalProductsSold, sales: rows });
});

// Admin global stats
app.get('/admin/stats', auth, requireAdmin, async (_req, res) => {
  const db = await dbPromise;
  const totals = await db.get('SELECT COUNT(*) as users, SUM(CASE WHEN status="active" THEN 1 ELSE 0 END) as active_users FROM users');
  const sales = await db.get('SELECT COUNT(*) as sales_count, COALESCE(SUM(total_price),0) as revenue FROM sales');
  res.json({ users: totals.users, activeUsers: totals.active_users, salesCount: sales.sales_count, revenue: sales.revenue });
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(`NOVA backend listening on http://localhost:${PORT}`);
});


