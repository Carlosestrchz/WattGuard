const Database = require('better-sqlite3');
const path     = require('path');
const fs       = require('fs');
const config   = require('./config');

class DatabaseModule {
  constructor() {
    //crea el directorio de la db si no existe
    const dir = path.dirname(config.db.path);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

    this.db = new Database(config.db.path);
    //fix de mejor rendimiento en escrituras concurrentes ;D
    this.db.pragma('journal_mode = WAL');
    this._init();
    console.log('[DB] SQLite inicializado en', config.db.path);
  }

  //inicializa tablas
  _init() {
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS nodos (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT NOT NULL,
        tipo        TEXT NOT NULL,
        mac_address TEXT UNIQUE,
        activo      INTEGER DEFAULT 1,
        created_at  INTEGER DEFAULT (strftime('%s','now'))
      );

      CREATE TABLE IF NOT EXISTS lecturas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nodo_id     INTEGER NOT NULL,
        corriente_a REAL,
        watts_a     REAL,
        corriente_b REAL,
        watts_b     REAL,
        temperatura REAL,
        relay_a     INTEGER DEFAULT 0,
        relay_b     INTEGER DEFAULT 0,
        timestamp   INTEGER DEFAULT (strftime('%s','now')),
        FOREIGN KEY (nodo_id) REFERENCES nodos(id)
      );

      CREATE TABLE IF NOT EXISTS alertas (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nodo_id     INTEGER,
        tipo        TEXT NOT NULL,
        descripcion TEXT,
        resuelta    INTEGER DEFAULT 0,
        timestamp   INTEGER DEFAULT (strftime('%s','now')),
        FOREIGN KEY (nodo_id) REFERENCES nodos(id)
      );

      CREATE TABLE IF NOT EXISTS config (
        clave TEXT PRIMARY KEY,
        valor TEXT NOT NULL
      );

      -- Valores por defecto en config
      INSERT OR IGNORE INTO config (clave, valor) VALUES
        ('voltaje_v',        '127'),
        ('nilm_threshold',   '20'),
        ('version',          '1.0.0');

      -- Nodos iniciales
      INSERT OR IGNORE INTO nodos (id, nombre, tipo, mac_address) VALUES
        (1, 'Switch principal', 'switch',       'switch-001'),
        (2, 'Nodo gemelo',      'twin outlet',  'gemelo-001');
    `);
  }

  //lecturas
  saveReading(data) {
    const stmt = this.db.prepare(`
      INSERT INTO lecturas
        (nodo_id, corriente_a, watts_a, corriente_b, watts_b, temperatura, relay_a, relay_b)
      VALUES
        (@nodo_id, @corriente_a, @watts_a, @corriente_b, @watts_b, @temperatura, @relay_a, @relay_b)
    `);
    return stmt.run(data);
  }

  getLatestReadings() {
    return this.db.prepare(`
      SELECT n.nombre, n.tipo, l.*
      FROM lecturas l
      JOIN nodos n ON n.id = l.nodo_id
      WHERE l.id IN (
        SELECT MAX(id) FROM lecturas GROUP BY nodo_id
      )
      ORDER BY l.timestamp DESC
    `).all();
  }

  getReadings({ nodo_id, desde, hasta, limit = 100 } = {}) {
    let sql = 'SELECT * FROM lecturas WHERE 1=1';
    const params = {};

    if (nodo_id) { sql += ' AND nodo_id = @nodo_id'; params.nodo_id = nodo_id; }
    if (desde)   { sql += ' AND timestamp >= @desde';  params.desde   = desde;   }
    if (hasta)   { sql += ' AND timestamp <= @hasta';  params.hasta   = hasta;   }

    sql += ' ORDER BY timestamp DESC LIMIT @limit';
    params.limit = limit;

    return this.db.prepare(sql).all(params);
  }

  //nodos
  getNodos() {
    return this.db.prepare('SELECT * FROM nodos WHERE activo = 1').all();
  }

  getNodoByTipo(tipo) {
    return this.db.prepare('SELECT * FROM nodos WHERE tipo = ?').get(tipo);
  }

  createNodo(data) {
    return this.db.prepare(`
      INSERT OR IGNORE INTO nodos (nombre, tipo, mac_address)
      VALUES (@nombre, @tipo, @mac_address)
    `).run(data);
  }

  //alertas
  saveAlert({ nodo_id, tipo, descripcion }) {
    return this.db.prepare(`
      INSERT INTO alertas (nodo_id, tipo, descripcion)
      VALUES (?, ?, ?)
    `).run(nodo_id, tipo, descripcion);
  }

  getAlerts({ resuelta = 0 } = {}) {
    return this.db.prepare(`
      SELECT a.*, n.nombre as nodo_nombre
      FROM alertas a
      LEFT JOIN nodos n ON n.id = a.nodo_id
      WHERE a.resuelta = ?
      ORDER BY a.timestamp DESC
    `).all(resuelta);
  }

  resolveAlert(id) {
    return this.db.prepare(
      'UPDATE alertas SET resuelta = 1 WHERE id = ?'
    ).run(id);
  }

  //configuraciones
  getConfig(clave) {
    const row = this.db.prepare('SELECT valor FROM config WHERE clave = ?').get(clave);
    return row ? row.valor : null;
  }

  setConfig(clave, valor) {
    return this.db.prepare(
      'INSERT OR REPLACE INTO config (clave, valor) VALUES (?, ?)'
    ).run(clave, String(valor));
  }

  getAllConfig() {
    return this.db.prepare('SELECT * FROM config').all();
  }
}

module.exports = new DatabaseModule();
