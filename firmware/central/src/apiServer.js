const express = require('express');
const config  = require('./config');
const db      = require('./database');
const mqtt    = require('./mqttSubscriber');

class APIServer {
  constructor() {
    this.app = express();
    this.app.use(express.json());
    this._registerRoutes();
  }

  _registerRoutes() {
    const r = this.app;

    //GET /api/nodos
    r.get('/api/nodos', (req, res) => {
      res.json(db.getNodos());
    });

    //POST /api/nodos
    r.post('/api/nodos', (req, res) => {
      const { nombre, tipo, mac_address } = req.body;
      if (!nombre || !tipo) return res.status(400).json({ error: 'nombre y tipo requeridos' });
      const result = db.createNodo({ nombre, tipo, mac_address });
      res.status(201).json({ id: result.lastInsertRowid });
    });

    /*GET /api/estado
    Última lectura de cada canal
    endpoint más frecuente desde la app */
    r.get('/api/estado', (req, res) => {
      res.json(db.getLatestReadings());
    });

    //GET /api/lecturas
    r.get('/api/lecturas', (req, res) => {
      const { nodo_id, desde, hasta, limit } = req.query;
      res.json(db.getReadings({
        nodo_id: nodo_id ? parseInt(nodo_id) : undefined,
        desde:   desde   ? parseInt(desde)   : undefined,
        hasta:   hasta   ? parseInt(hasta)   : undefined,
        limit:   limit   ? parseInt(limit)   : 100,
      }));
    });

    //GET /api/alertas
    r.get('/api/alertas', (req, res) => {
      const resuelta = req.query.resuelta !== undefined
        ? parseInt(req.query.resuelta) : 0;
      res.json(db.getAlerts({ resuelta }));
    });

    //POST /api/alertas/:id/resolver
    r.post('/api/alertas/:id/resolver', (req, res) => {
      const result = db.resolveAlert(parseInt(req.params.id));
      if (result.changes === 0) return res.status(404).json({ error: 'Alerta no encontrada' });
      res.json({ ok: true });
    });

    //POST /api/relay/:nodo_id
    r.post('/api/relay/:nodo_id', (req, res) => {
      const { canal, estado } = req.body;
      if (canal === undefined || estado === undefined)
        return res.status(400).json({ error: 'canal y estado requeridos' });

      const nodoId = parseInt(req.params.nodo_id);
      const nodos  = db.getNodos();
      const nodo   = nodos.find(n => n.id === nodoId);
      if (!nodo) return res.status(404).json({ error: 'Nodo no encontrado' });

      //topic de comando al esp32-c3
      const topicCmd = `wattguard/${nodo.tipo === 'switch' ? 'switch' : 'gemelo'}/cmd`;
      mqtt.publish(topicCmd, { canal, estado: Boolean(estado) });

      res.json({ ok: true, nodo: nodo.nombre, canal, estado });
    });

    //GET /api/config
    r.get('/api/config', (req, res) => {
      res.json(db.getAllConfig());
    });

    //PUT /api/config
    r.put('/api/config', (req, res) => {
      const { clave, valor } = req.body;
      if (!clave || valor === undefined)
        return res.status(400).json({ error: 'clave y valor requeridos' });
      db.setConfig(clave, valor);
      res.json({ ok: true, clave, valor });
    });

    //health check
    r.get('/health', (req, res) => {
      res.json({ status: 'ok', uptime: process.uptime() });
    });
  }

  start() {
    this.app.listen(config.api.port, () => {
      console.log(`[API] Servidor en http://localhost:${config.api.port}`);
    });
  }
}

module.exports = new APIServer();
