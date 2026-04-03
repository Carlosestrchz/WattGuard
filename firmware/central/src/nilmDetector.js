const config = require('./config');
const db     = require('./database');

class NILMDetector {
  constructor() {
    this.threshold = config.nilm.threshold;
    //cache de última lectura de nodo para comparar entre ellas
    this._cache = {
      switch: null,
      gemelo_a: null,
      gemelo_b: null,
    };
  }

  //actualiza el cache con la lectura más reciente de cada canal
  updateCache(canal, watts) {
    this._cache[canal] = { watts, ts: Date.now() };
  }

  //compara switch vs suma de nodos individuales (nilm hibrido)
  analyze() {
    const { switch: sw, gemelo_a: a, gemelo_b: b } = this._cache;

    //configuración de las ultimas tres lecturas
    //10 segundos — ESP32-C3 publica cada 2 segundos en producción
    const maxAge = 10000;
    const now    = Date.now();
    if (!sw || !a || !b) return null;
    if (now - sw.ts > maxAge || now - a.ts > maxAge || now - b.ts > maxAge) return null;

    const switchW  = sw.watts;
    const sumNodesW = a.watts + b.watts;
    const diff      = switchW - sumNodesW;

    console.log(`[NILM] Switch: ${switchW.toFixed(1)}W | Nodos: ${sumNodesW.toFixed(1)}W | Diff: ${diff.toFixed(1)}W`);

    if (diff > this.threshold) {
      return {
        tipo:        'consumo_no_registrado',
        descripcion: `Consumo sin nodo: ${diff.toFixed(1)}W (switch=${switchW.toFixed(1)}W, nodos=${sumNodesW.toFixed(1)}W)`,
        diff,
      };
    }

    return null;
  }

  //dispara alerta si detecta anomalía
  //evita duplicados en ventana de 60 segundos
  detectAndAlert(nodo_id = null) {
    const anomaly = this.analyze();
    if (!anomaly) return;

    //evita spam de alertas.
    //crea una si no hay otra activa del mismo tipo
    const existing = db.getAlerts({ resuelta: 0 });
    const duplicate = existing.find(a => a.tipo === anomaly.tipo);
    if (duplicate) return;

    db.saveAlert({
      nodo_id,
      tipo:        anomaly.tipo,
      descripcion: anomaly.descripcion,
    });

    console.log(`[NILM] Alerta creada: ${anomaly.descripcion}`);
  }
}

module.exports = new NILMDetector();
