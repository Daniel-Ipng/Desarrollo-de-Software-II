'use strict';
/**
 * API REST de tareas con autenticación JWT (access + refresh token).
 *   POST   /auth/register   {name, email, password}
 *   POST   /auth/login      {email, password}
 *   POST   /auth/refresh    {refreshToken}
 *   POST   /auth/logout     {refreshToken}
 *   GET    /auth/me
 *   GET    /tasks?page=1&limit=15
 *   POST   /tasks           {title, description}
 *   PUT    /tasks/:id       {title, description, completed}
 *   DELETE /tasks/:id
 * Variables opcionales: PORT, ACCESS_TTL (ej. 20s para probar el refresh), REFRESH_TTL.
 */
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;
const ACCESS_SECRET = process.env.ACCESS_SECRET || 'dev-access-secret-cambiame';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'dev-refresh-secret-cambiame';
const ACCESS_TTL = process.env.ACCESS_TTL || '5m';
const REFRESH_TTL = process.env.REFRESH_TTL || '7d';
const DB_FILE = path.join(__dirname, 'db.json');

// ---------- "Base de datos" en archivo JSON ----------
function loadDb() {
  try {
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf8'));
  } catch {
    return { users: [], tasks: [], refreshTokens: [], nextTaskId: 1 };
  }
}
const db = loadDb();
const saveDb = () => fs.writeFileSync(DB_FILE, JSON.stringify(db, null, 2));

// ---------- Utilidades ----------
function hashPassword(password) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}
function verifyPassword(password, stored) {
  const [salt, hash] = stored.split(':');
  const candidate = crypto.scryptSync(password, salt, 64);
  return crypto.timingSafeEqual(candidate, Buffer.from(hash, 'hex'));
}
const publicUser = (u) => ({ id: u.id, name: u.name, email: u.email });

function issueTokens(user) {
  const accessToken = jwt.sign({ sub: user.id, email: user.email }, ACCESS_SECRET, { expiresIn: ACCESS_TTL });
  const refreshToken = jwt.sign({ sub: user.id, jti: crypto.randomUUID() }, REFRESH_SECRET, { expiresIn: REFRESH_TTL });
  db.refreshTokens.push(refreshToken);
  saveDb();
  return { accessToken, refreshToken };
}
const fail = (res, status, message) => res.status(status).json({ message });

function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return fail(res, 401, 'Token requerido');
  try {
    req.userId = jwt.verify(token, ACCESS_SECRET).sub;
    next();
  } catch {
    fail(res, 401, 'Token inválido o expirado');
  }
}

// ---------- App ----------
const app = express();
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  res.on('finish', () => console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode}`));
  next();
});

// ----- Auth -----
app.post('/auth/register', (req, res) => {
  const { name, email, password } = req.body || {};
  if (!name || String(name).trim().length < 2) return fail(res, 400, 'El nombre debe tener al menos 2 caracteres');
  if (!email || !/^\S+@\S+\.\S+$/.test(email)) return fail(res, 400, 'Correo electrónico inválido');
  if (!password || String(password).length < 6) return fail(res, 400, 'La contraseña debe tener al menos 6 caracteres');
  const normalized = String(email).trim().toLowerCase();
  if (db.users.some((u) => u.email === normalized)) return fail(res, 409, 'El correo ya está registrado');

  const user = { id: crypto.randomUUID(), name: String(name).trim(), email: normalized, passwordHash: hashPassword(String(password)) };
  db.users.push(user);
  res.status(201).json({ ...issueTokens(user), user: publicUser(user) });
});

app.post('/auth/login', (req, res) => {
  const { email, password } = req.body || {};
  const user = db.users.find((u) => u.email === String(email || '').trim().toLowerCase());
  if (!user || !verifyPassword(String(password || ''), user.passwordHash)) {
    return fail(res, 401, 'Correo o contraseña incorrectos');
  }
  res.json({ ...issueTokens(user), user: publicUser(user) });
});

app.post('/auth/refresh', (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken || !db.refreshTokens.includes(refreshToken)) return fail(res, 401, 'Refresh token inválido');
  try {
    const payload = jwt.verify(refreshToken, REFRESH_SECRET);
    const user = db.users.find((u) => u.id === payload.sub);
    if (!user) return fail(res, 401, 'Usuario no encontrado');
    db.refreshTokens = db.refreshTokens.filter((t) => t !== refreshToken); // rotación
    res.json(issueTokens(user));
  } catch {
    db.refreshTokens = db.refreshTokens.filter((t) => t !== refreshToken);
    saveDb();
    fail(res, 401, 'Refresh token expirado');
  }
});

app.post('/auth/logout', (req, res) => {
  const { refreshToken } = req.body || {};
  db.refreshTokens = db.refreshTokens.filter((t) => t !== refreshToken);
  saveDb();
  res.status(204).end();
});

app.get('/auth/me', auth, (req, res) => {
  const user = db.users.find((u) => u.id === req.userId);
  if (!user) return fail(res, 401, 'Usuario no encontrado');
  res.json(publicUser(user));
});

// ----- Tareas -----
app.get('/tasks', auth, (req, res) => {
  const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 15, 1), 50);
  const mine = db.tasks.filter((t) => t.userId === req.userId).sort((a, b) => b.id - a.id);
  const total = mine.length;
  const totalPages = Math.max(Math.ceil(total / limit), 1);
  const data = mine.slice((page - 1) * limit, page * limit).map(taskJson);
  res.json({ page, totalPages, total, data });
});

app.post('/tasks', auth, (req, res) => {
  const { title, description } = req.body || {};
  if (!title || !String(title).trim()) return fail(res, 400, 'El título es obligatorio');
  const task = {
    id: db.nextTaskId++, userId: req.userId, title: String(title).trim(),
    description: String(description || '').trim(), completed: false, createdAt: new Date().toISOString(),
  };
  db.tasks.push(task);
  saveDb();
  res.status(201).json(taskJson(task));
});

app.put('/tasks/:id', auth, (req, res) => {
  const task = db.tasks.find((t) => t.id === Number(req.params.id) && t.userId === req.userId);
  if (!task) return fail(res, 404, 'Tarea no encontrada');
  const { title, description, completed } = req.body || {};
  if (!title || !String(title).trim()) return fail(res, 400, 'El título es obligatorio');
  task.title = String(title).trim();
  task.description = String(description || '').trim();
  task.completed = Boolean(completed);
  saveDb();
  res.json(taskJson(task));
});

app.delete('/tasks/:id', auth, (req, res) => {
  const index = db.tasks.findIndex((t) => t.id === Number(req.params.id) && t.userId === req.userId);
  if (index === -1) return fail(res, 404, 'Tarea no encontrada');
  db.tasks.splice(index, 1);
  saveDb();
  res.status(204).end();
});

const taskJson = ({ id, title, description, completed, createdAt }) => ({ id, title, description, completed, createdAt });

app.use((err, req, res, next) => fail(res, 400, 'Solicitud inválida (JSON mal formado)'));
app.listen(PORT, '0.0.0.0', () => console.log(`API lista en http://0.0.0.0:${PORT}  (access token: ${ACCESS_TTL})`));
