import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import dotenv from 'dotenv';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';

dotenv.config();

const app = express();
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

// Centralized CORS configuration with explicit preflight handling
const corsOptions = {
  origin: (origin, callback) => {
    // Allow all origins by default; tighten if you need to restrict
    callback(null, true);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  optionsSuccessStatus: 204,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// Ensure proxies/CDNs vary cache by Origin
app.use((req, res, next) => {
  res.header('Vary', 'Origin');
  next();
});
app.disable('x-powered-by');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);
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
      name TEXT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      status TEXT NOT NULL DEFAULT 'active',
      blocked_until TEXT,
      store_id TEXT,
      store_name TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      sku TEXT,
      cost REAL DEFAULT 0,
      price REAL NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      low_stock_threshold INTEGER NOT NULL DEFAULT 0,
      store_id TEXT,
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
      client_id INTEGER,
      store_id TEXT,
      account_id INTEGER,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY(product_id) REFERENCES products(id),
      FOREIGN KEY(client_id) REFERENCES clients(id)
    );
    CREATE TABLE IF NOT EXISTS clients (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT,
      store_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS refresh_tokens (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      token TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      revoked_at TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    );
    CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
  `);

  const safeAlter = async (sql) => { try { await db.exec(sql); } catch (_) {} };
  await safeAlter("ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT 'user'");
  await safeAlter("ALTER TABLE users ADD COLUMN status TEXT NOT NULL DEFAULT 'active'");
  await safeAlter('ALTER TABLE users ADD COLUMN store_id TEXT');
  await safeAlter('ALTER TABLE users ADD COLUMN name TEXT');
  await safeAlter('ALTER TABLE users ADD COLUMN blocked_until TEXT');
  await safeAlter('ALTER TABLE users ADD COLUMN store_name TEXT');
  await safeAlter('ALTER TABLE products ADD COLUMN sku TEXT');
  await safeAlter('ALTER TABLE products ADD COLUMN cost REAL DEFAULT 0');
  await safeAlter('ALTER TABLE products ADD COLUMN low_stock_threshold INTEGER NOT NULL DEFAULT 0');
  await safeAlter('ALTER TABLE products ADD COLUMN store_id TEXT');
  await safeAlter('ALTER TABLE products ADD COLUMN account_id INTEGER');
  await safeAlter('ALTER TABLE sales ADD COLUMN store_id TEXT');
  await safeAlter('ALTER TABLE sales ADD COLUMN account_id INTEGER');
  await safeAlter('ALTER TABLE sales ADD COLUMN client_id INTEGER');

  // Seed default admin
  const existingAdmin = await db.get('SELECT id FROM users WHERE email = ?', [ADMIN_EMAIL]);
  if (!existingAdmin) {
    const hash = await bcrypt.hash(ADMIN_PASSWORD, 10);
    await db.run("INSERT INTO users (name, email, password, role, status) VALUES (?, ?, ?, 'admin', 'active')", ['Admin', ADMIN_EMAIL, hash]);
    console.log(`Created default admin: ${ADMIN_EMAIL}`);
  }
  return db;
}

let dbPromise = createDb();

// Utilities
function slugify(value) {
  return String(value || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)+/g, '')
    .slice(0, 32);
}

function generateStoreIdentifiers(preferredName) {
  const baseName = preferredName && String(preferredName).trim().length > 0
    ? preferredName.trim()
    : 'Loja';
  const slug = slugify(baseName) || 'loja';
  const rand = Math.random().toString(36).slice(2, 8);
  const storeId = `store_${slug}_${rand}`;
  const storeName = baseName;
  return { storeId, storeName };
}

// Health
app.get('/health', (_req, res) => res.json({ ok: true }));

// Auth
function randomTokenString(size = 48) {
  return crypto.randomBytes(size).toString('hex');
}

app.post('/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'email and password required' });
    const db = await dbPromise;
    let user = await db.get('SELECT id, email, password, role, status, blocked_until, store_id, store_name, name FROM users WHERE email = ?', [email]);
    if (!user) return res.status(401).json({ error: 'invalid_credentials' });
    if (user.status !== 'active') return res.status(403).json({ error: 'account_blocked' });
    if (user.blocked_until) {
      const until = new Date(user.blocked_until);
      const now = new Date();
      if (until.getTime() > now.getTime()) {
        return res.status(403).json({ error: 'account_blocked_until', blockedUntil: user.blocked_until });
      }
    }
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ error: 'invalid_credentials' });
    // Auto-provision store for users without one (e.g., default admin)
    if (!user.store_id || !user.store_name) {
      const generated = generateStoreIdentifiers(user.name || 'Loja');
      await db.run('UPDATE users SET store_id = ?, store_name = ? WHERE id = ?', [generated.storeId, generated.storeName, user.id]);
      user = await db.get('SELECT id, email, password, role, status, blocked_until, store_id, store_name, name FROM users WHERE id = ?', [user.id]);
    }
    const token = jwt.sign({ id: user.id, email: user.email, role: user.role, storeId: user.store_id }, JWT_SECRET, { expiresIn: '1h' });
    // issue refresh token (30 days)
    const refreshToken = randomTokenString(32);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    await db.run('INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)', [user.id, refreshToken, expiresAt]);
    res.json({ token, refreshToken, user: { id: user.id, email: user.email, role: user.role, storeId: user.store_id, storeName: user.store_name, name: user.name } });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Refresh access token using refresh token (rotation)
app.post('/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body || {};
    if (!refreshToken) return res.status(400).json({ error: 'refreshToken required' });
    const db = await dbPromise;
    const row = await db.get('SELECT rt.id, rt.user_id as userId, rt.token, rt.expires_at as expiresAt, rt.revoked_at as revokedAt, u.email, u.role, u.store_id as storeId FROM refresh_tokens rt JOIN users u ON u.id = rt.user_id WHERE rt.token = ?', [refreshToken]);
    if (!row) return res.status(401).json({ error: 'invalid_refresh' });
    if (row.revokedAt) return res.status(401).json({ error: 'revoked_refresh' });
    if (new Date(row.expiresAt).getTime() < Date.now()) return res.status(401).json({ error: 'expired_refresh' });
    // rotate
    await db.run('UPDATE refresh_tokens SET revoked_at = datetime("now") WHERE id = ?', [row.id]);
    const newRefresh = randomTokenString(32);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
    await db.run('INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES (?, ?, ?)', [row.userId, newRefresh, expiresAt]);
    const token = jwt.sign({ id: row.userId, email: row.email, role: row.role, storeId: row.storeId }, JWT_SECRET, { expiresIn: '1h' });
    res.json({ token, refreshToken: newRefresh });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Logout: revoke refresh token
app.post('/auth/logout', auth, async (req, res) => {
  try {
    const { refreshToken } = req.body || {};
    if (!refreshToken) return res.status(400).json({ error: 'refreshToken required' });
    const db = await dbPromise;
    await db.run('UPDATE refresh_tokens SET revoked_at = datetime("now") WHERE token = ? AND user_id = ?', [refreshToken, req.user.id]);
    res.json({ ok: true });
  } catch {
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

// Ensure user is active and not beyond blocked_until on every request
async function ensureActiveUser(req, res, next) {
  try {
    const db = await dbPromise;
    const row = await db.get('SELECT id, status, blocked_until FROM users WHERE id = ?', [req.user.id]);
    if (!row) return res.status(401).json({ error: 'invalid_token_user' });
    // If already blocked, deny
    if (row.status !== 'active') return res.status(403).json({ error: 'account_blocked' });
    // If has a block date
    if (row.blocked_until) {
      const until = new Date(row.blocked_until);
      const now = new Date();
      if (until.getTime() > now.getTime()) {
        return res.status(403).json({ error: 'account_blocked_until', blockedUntil: row.blocked_until });
      }
      // If past due, permanently block and clear date, require manual admin unblock
      if (until.getTime() <= now.getTime()) {
        await db.run('UPDATE users SET status = "blocked", blocked_until = NULL WHERE id = ?', [req.user.id]);
        return res.status(403).json({ error: 'account_blocked' });
      }
    }
    next();
  } catch {
    return res.status(500).json({ error: 'internal_error' });
  }
}

// Admin user management
app.get('/users', auth, ensureActiveUser, requireAdmin, async (_req, res) => {
  const db = await dbPromise;
  const users = await db.all('SELECT id, name, email, role, status, blocked_until as blockedUntil, store_id as storeId, store_name as storeName, created_at FROM users ORDER BY id DESC');
  res.json(users);
});

app.post('/users', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  try {
    const { name, email, password, role = 'user', store_id, storeId, store_name, storeName, blockedUntil } = req.body;
    let normalizedStoreId = store_id || storeId;
    let normalizedStoreName = store_name || storeName;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'name, email and password are required' });
    }

    // Auto-generate store when missing
    if (!normalizedStoreId || !normalizedStoreName) {
      const generated = generateStoreIdentifiers(normalizedStoreName || name);
      normalizedStoreId = generated.storeId;
      normalizedStoreName = generated.storeName;
    }
    if (!['user', 'admin'].includes(role)) return res.status(400).json({ error: 'invalid_role' });
    const db = await dbPromise;
    const hash = await bcrypt.hash(password, 10);
    const result = await db.run('INSERT INTO users (name, email, password, role, status, blocked_until, store_id, store_name) VALUES (?, ?, ?, ?, "active", ?, ?, ?)', [name, email, hash, role, blockedUntil || null, normalizedStoreId, normalizedStoreName]);
    const created = await db.get('SELECT id, name, email, role, status, blocked_until as blockedUntil, store_id as storeId, store_name as storeName, created_at FROM users WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch (e) {
    if (String(e).includes('UNIQUE')) return res.status(409).json({ error: 'email_exists' });
    res.status(500).json({ error: 'internal_error' });
  }
});

app.patch('/users/:id/block', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  // Prevent admin from blocking themselves
  if (req.params.id == req.user.id) {
    return res.status(400).json({ error: 'cannot_block_self' });
  }
  
  const db = await dbPromise;
  await db.run('UPDATE users SET status = "blocked" WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});

app.patch('/users/:id/unblock', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  const db = await dbPromise;
  await db.run('UPDATE users SET status = "active" WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});

// Optional: update user (role/storeId)
app.patch('/users/:id', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  const { role, storeId, status, blockedUntil } = req.body;
  const fields = [];
  const args = [];
  if (role) { fields.push('role = ?'); args.push(role); }
  if (storeId) { fields.push('store_id = ?'); args.push(storeId); }
  if (status) { fields.push('status = ?'); args.push(status); }
  if (typeof blockedUntil !== 'undefined') { fields.push('blocked_until = ?'); args.push(blockedUntil || null); }
  if (!fields.length) return res.status(400).json({ error: 'no_fields' });
  args.push(req.params.id);
  const db = await dbPromise;
  await db.run(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`, args);
  const row = await db.get('SELECT id, name, email, role, status, blocked_until as blockedUntil, store_id as storeId, store_name as storeName, created_at FROM users WHERE id = ?', [req.params.id]);
  res.json(row);
});

// Admin: change user password
app.patch('/users/:id/password', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword || String(newPassword).length < 6) return res.status(400).json({ error: 'password_min_6' });
    const db = await dbPromise;
    const hash = await bcrypt.hash(String(newPassword), 10);
    await db.run('UPDATE users SET password = ? WHERE id = ?', [hash, req.params.id]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Products
app.get('/products', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const q = String(req.query.q || '').trim().toLowerCase();
  const sort = String(req.query.sort || 'id'); // id,name,price,stock
  const order = String(req.query.order || 'desc').toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
  const page = Math.max(1, Number(req.query.page || 1));
  const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize || 20)));
  const offset = (page - 1) * pageSize;
  const allowedSort = new Set(['id','name','price','stock','created_at']);
  const sortCol = allowedSort.has(sort) ? sort : 'id';

  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const params = [storeId];
  let where = 'WHERE store_id = ?';
  if (q) { where += ' AND (lower(name) LIKE ?)'; params.push(`%${q}%`); }
  const countRow = await db.get(`SELECT COUNT(*) as total FROM products ${where}`, params);
  const rows = await db.all(
    `SELECT * FROM products ${where} ORDER BY ${sortCol} ${order} LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );
  res.json({ items: rows, total: countRow.total, page, pageSize });
});

app.post('/products', auth, ensureActiveUser, async (req, res) => {
  try {
    const { name, price, stock, low_stock_threshold } = req.body;
    if (!name || price == null) return res.status(400).json({ error: 'name and price required' });
    const db = await dbPromise;
    const result = await db.run(
      'INSERT INTO products (name, price, stock, low_stock_threshold, store_id, account_id) VALUES (?, ?, ?, ?, ?, ?)',
      [name, price, stock ?? 0, low_stock_threshold ?? 0, req.user.storeId, req.user.id]
    );
    const created = await db.get('SELECT * FROM products WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Update product
app.put('/products/:id', auth, ensureActiveUser, async (req, res) => {
  try {
    const { name, price, stock, low_stock_threshold } = req.body;
    const db = await dbPromise;
    await db.run(
      'UPDATE products SET name = ?, price = ?, stock = ?, low_stock_threshold = ? WHERE id = ? AND store_id = ?',
      [name, price, stock ?? 0, low_stock_threshold ?? 0, req.params.id, req.user.storeId]
    );
    const updated = await db.get('SELECT * FROM products WHERE id = ?', [req.params.id]);
    if (!updated) return res.status(404).json({ error: 'not_found' });
    res.json(updated);
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Delete product
app.delete('/products/:id', auth, ensureActiveUser, async (req, res) => {
  try {
    const db = await dbPromise;
    await db.run('DELETE FROM products WHERE id = ? AND store_id = ?', [req.params.id, req.user.storeId]);
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Low stock
app.get('/products/low_stock', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const rows = await db.all(
    'SELECT * FROM products WHERE store_id = ? AND stock <= low_stock_threshold ORDER BY stock ASC',
    [req.user.storeId]
  );
  res.json(rows);
});

// Sales
app.get('/sales', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const q = String(req.query.q || '').trim().toLowerCase();
  const sort = String(req.query.sort || 'sale_date');
  const order = String(req.query.order || 'desc').toUpperCase() === 'ASC' ? 'ASC' : 'DESC';
  const page = Math.max(1, Number(req.query.page || 1));
  const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize || 20)));
  const offset = (page - 1) * pageSize;
  const allowedSort = new Set(['sale_date','total_price','quantity','id']);
  const sortCol = allowedSort.has(sort) ? sort : 'sale_date';

  const params = [storeId];
  let where = 'WHERE s.store_id = ?';
  if (q) { where += ' AND (lower(s.product_name) LIKE ? OR lower(c.name) LIKE ?)'; params.push(`%${q}%`, `%${q}%`); }
  const countRow = await db.get(
    `SELECT COUNT(*) as total FROM sales s LEFT JOIN clients c ON c.id = s.client_id ${where}`,
    params
  );
  const rows = await db.all(
    `SELECT s.*, c.name AS client_name
     FROM sales s
     LEFT JOIN clients c ON c.id = s.client_id
     ${where}
     ORDER BY s.${sortCol} ${order}
     LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );
  res.json({ items: rows, total: countRow.total, page, pageSize });
});

app.post('/sales', auth, ensureActiveUser, async (req, res) => {
  try {
    const { product_id, product_name, quantity, unit_price, sale_date, client_id } = req.body;
    if (!product_id || !product_name || !quantity || unit_price == null || !sale_date) {
      return res.status(400).json({ error: 'missing fields' });
    }
    const total_price = Number(unit_price) * Number(quantity);
    const db = await dbPromise;
    const result = await db.run(
      `INSERT INTO sales (product_id, product_name, quantity, unit_price, total_price, sale_date, client_id, store_id, account_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [product_id, product_name, quantity, unit_price, total_price, sale_date, client_id || null, req.user.storeId, req.user.id]
    );
    const created = await db.get(
      `SELECT s.*, c.name AS client_name FROM sales s LEFT JOIN clients c ON c.id = s.client_id WHERE s.id = ?`,
      [result.lastID]
    );
    res.status(201).json(created);
  } catch (e) {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Daily summary
app.get('/summary/daily', auth, ensureActiveUser, async (req, res) => {
  const { date } = req.query; // yyyy-mm-dd
  if (!date) return res.status(400).json({ error: 'date required (yyyy-mm-dd)' });
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const rows = await db.all(
    `SELECT * FROM sales WHERE store_id = ? AND substr(sale_date, 1, 10) = ? ORDER BY sale_date DESC`,
    [storeId, String(date)]
  );
  const totalSales = rows.reduce((sum, r) => sum + (r.total_price ?? 0), 0);
  const totalProductsSold = rows.reduce((sum, r) => sum + (r.quantity ?? 0), 0);
  res.json({ date, totalSales, totalProductsSold, sales: rows });
});

// Reports: revenue by date range (inclusive) per store or all (admin)
app.get('/reports/revenue', auth, ensureActiveUser, async (req, res) => {
  const start = String(req.query.start || '');
  const end = String(req.query.end || '');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(start) || !/^\d{4}-\d{2}-\d{2}$/.test(end)) {
    return res.status(400).json({ error: 'start and end required (yyyy-mm-dd)' });
  }
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const params = [storeId, start, end];
  const rows = await db.all(
    `SELECT substr(sale_date, 1, 10) as day, COUNT(*) as salesCount, COALESCE(SUM(total_price),0) as revenue
     FROM sales
     WHERE store_id = ? AND substr(sale_date, 1, 10) BETWEEN ? AND ?
     GROUP BY day
     ORDER BY day ASC`,
    params
  );
  const totalRevenue = rows.reduce((s, r) => s + (r.revenue || 0), 0);
  const totalSales = rows.reduce((s, r) => s + (r.salesCount || 0), 0);
  res.json({ start, end, storeId, totalRevenue, totalSales, byDay: rows });
});

// Password reset: request token and confirm
app.post('/auth/request_reset', async (req, res) => {
  try {
    const { email } = req.body || {};
    if (!email) return res.status(400).json({ error: 'email required' });
    const db = await dbPromise;
    const user = await db.get('SELECT id, email FROM users WHERE email = ?', [email]);
    // Always respond success to avoid user enumeration
    if (!user) return res.json({ ok: true });
    const resetToken = jwt.sign({ purpose: 'password_reset', uid: user.id }, JWT_SECRET, { expiresIn: '15m' });
    // In production you'd email this token; here we return it for manual flow
    res.json({ ok: true, resetToken });
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

app.post('/auth/reset', async (req, res) => {
  try {
    const { token, newPassword } = req.body || {};
    if (!token || !newPassword || String(newPassword).length < 6) {
      return res.status(400).json({ error: 'token and newPassword(min 6) required' });
    }
    const payload = jwt.verify(token, JWT_SECRET);
    if (payload?.purpose !== 'password_reset' || !payload?.uid) {
      return res.status(400).json({ error: 'invalid_token' });
    }
    const db = await dbPromise;
    const hash = await bcrypt.hash(String(newPassword), 10);
    await db.run('UPDATE users SET password = ? WHERE id = ?', [hash, payload.uid]);
    res.json({ ok: true });
  } catch {
    res.status(400).json({ error: 'invalid_or_expired_token' });
  }
});

// Clients (per store)
app.get('/clients', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const q = String(req.query.q || '').trim().toLowerCase();
  const sort = String(req.query.sort || 'name');
  const order = String(req.query.order || 'asc').toUpperCase() === 'DESC' ? 'DESC' : 'ASC';
  const page = Math.max(1, Number(req.query.page || 1));
  const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize || 20)));
  const offset = (page - 1) * pageSize;
  const allowedSort = new Set(['name','id','created_at']);
  const sortCol = allowedSort.has(sort) ? sort : 'name';

  const params = [storeId];
  let where = 'WHERE store_id = ?';
  if (q) { where += ' AND (lower(name) LIKE ? OR phone LIKE ?)'; params.push(`%${q}%`, `%${q}%`); }
  const countRow = await db.get(`SELECT COUNT(*) as total FROM clients ${where}`, params);
  const rows = await db.all(
    `SELECT * FROM clients ${where} ORDER BY ${sortCol} ${order} LIMIT ? OFFSET ?`,
    [...params, pageSize, offset]
  );
  res.json({ items: rows, total: countRow.total, page, pageSize });
});

// CSV exports
function toCsv(rows) {
  if (!rows || rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const escape = (v) => String(v ?? '').replaceAll('"', '""');
  const head = headers.join(',');
  const body = rows.map(r => headers.map(h => `"${escape(r[h])}"`).join(',')).join('\n');
  return `${head}\n${body}`;
}

app.get('/export/products.csv', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const rows = await db.all('SELECT id, name, sku, price, stock, low_stock_threshold, created_at FROM products WHERE store_id = ? ORDER BY id DESC', [storeId]);
  const csv = toCsv(rows);
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="products.csv"');
  res.send(csv);
});

app.get('/export/sales.csv', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const rows = await db.all(
    `SELECT s.id, s.product_name, s.quantity, s.unit_price, s.total_price, s.sale_date, c.name AS client_name
     FROM sales s LEFT JOIN clients c ON c.id = s.client_id
     WHERE s.store_id = ? ORDER BY s.sale_date DESC`,
    [storeId]
  );
  const csv = toCsv(rows);
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="sales.csv"');
  res.send(csv);
});

app.get('/export/clients.csv', auth, ensureActiveUser, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.user.role === 'admin' ? (req.query.storeId || req.user.storeId) : req.user.storeId;
  const rows = await db.all('SELECT id, name, phone, created_at FROM clients WHERE store_id = ? ORDER BY name ASC', [storeId]);
  const csv = toCsv(rows);
  res.setHeader('Content-Type', 'text/csv; charset=utf-8');
  res.setHeader('Content-Disposition', 'attachment; filename="clients.csv"');
  res.send(csv);
});

app.post('/clients', auth, ensureActiveUser, async (req, res) => {
  try {
    const { name, phone, storeId: storeIdBody } = req.body;
    if (!name) return res.status(400).json({ error: 'name required' });
    const storeId = req.user?.role === 'admin' ? (storeIdBody || req.user?.storeId) : req.user?.storeId;
    if (!storeId) return res.status(400).json({ error: 'storeId required' });
    const db = await dbPromise;
    const result = await db.run('INSERT INTO clients (name, phone, store_id) VALUES (?, ?, ?)', [name, phone ?? null, storeId]);
    const created = await db.get('SELECT * FROM clients WHERE id = ?', [result.lastID]);
    res.status(201).json(created);
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

app.put('/clients/:id', auth, ensureActiveUser, async (req, res) => {
  try {
    const { name, phone } = req.body;
    const db = await dbPromise;
    await db.run('UPDATE clients SET name = ?, phone = ? WHERE id = ? AND store_id = ?', [name, phone ?? null, req.params.id, req.user.storeId]);
    const updated = await db.get('SELECT * FROM clients WHERE id = ?', [req.params.id]);
    if (!updated) return res.status(404).json({ error: 'not_found' });
    res.json(updated);
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

app.delete('/clients/:id', auth, ensureActiveUser, async (req, res) => {
  try {
    const db = await dbPromise;
    await db.run('DELETE FROM clients WHERE id = ? AND store_id = ?', [req.params.id, req.user.storeId]);
    res.json({ ok: true });
  } catch {
    res.status(500).json({ error: 'internal_error' });
  }
});

// Admin global stats (all stores combined)
app.get('/admin/stats', auth, ensureActiveUser, requireAdmin, async (_req, res) => {
  const db = await dbPromise;
  const totals = await db.get('SELECT COUNT(*) as users, SUM(CASE WHEN status="active" THEN 1 ELSE 0 END) as active_users FROM users');
  const sales = await db.get('SELECT COUNT(*) as sales_count, COALESCE(SUM(total_price),0) as revenue FROM sales');
  res.json({ users: totals.users, activeUsers: totals.active_users, salesCount: sales.sales_count, revenue: sales.revenue });
});

// Admin stats by store
app.get('/admin/stats/:storeId', auth, ensureActiveUser, requireAdmin, async (req, res) => {
  const db = await dbPromise;
  const storeId = req.params.storeId;
  
  const totals = await db.get('SELECT COUNT(*) as users, SUM(CASE WHEN status="active" THEN 1 ELSE 0 END) as active_users FROM users WHERE store_id = ?', [storeId]);
  const sales = await db.get('SELECT COUNT(*) as sales_count, COALESCE(SUM(total_price),0) as revenue FROM sales WHERE store_id = ?', [storeId]);
  const products = await db.get('SELECT COUNT(*) as products_count FROM products WHERE store_id = ?', [storeId]);
  const clients = await db.get('SELECT COUNT(*) as clients_count FROM clients WHERE store_id = ?', [storeId]);
  
  res.json({ 
    users: totals.users, 
    activeUsers: totals.active_users, 
    salesCount: sales.sales_count, 
    revenue: sales.revenue,
    productsCount: products.products_count,
    clientsCount: clients.clients_count
  });
});

// Get all stores for admin
app.get('/admin/stores', auth, ensureActiveUser, requireAdmin, async (_req, res) => {
  const db = await dbPromise;
  const stores = await db.all('SELECT DISTINCT store_id, store_name FROM users WHERE store_id IS NOT NULL ORDER BY store_name');
  res.json(stores);
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(`NOVA backend listening on http://localhost:${PORT}`);
});


