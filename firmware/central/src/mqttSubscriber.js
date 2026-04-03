const mqtt    = require('mqtt');
const config  = require('./config');
const db      = require('./database');
const nilm    = require('./nilmDetector');

class MQTTSubscriber {
  constructor() {
    this.client = null;
  }

  connect() {
    this.client = mqtt.connect(config.mqtt.broker, {
      port:      config.mqtt.port,
      clientId:  'wattguard-central',
      reconnectPeriod: 3000,
    });

    this.client.on('connect', () => {
      console.log('[MQTT] Conectado al broker');
      config.mqtt.topics.forEach(t => {
        this.client.subscribe(t, err => {
          if (!err) console.log(`[MQTT] Suscrito a ${t}`);
        });
      });
    });

    this.client.on('message', (topic, payload) => {
      this._onMessage(topic, payload.toString());
    });

    this.client.on('error', err => {
      console.error('[MQTT] Error:', err.message);
    });

    this.client.on('reconnect', () => {
      console.log('[MQTT] Reconectando...');
    });
  }

  _onMessage(topic, payload) {
    let data;
    try {
      data = JSON.parse(payload);
    } catch {
      console.warn('[MQTT] Payload inválido en', topic);
      return;
    }

    console.log(`[MQTT] ${topic} → ${payload}`);

    //determinación de nodo_id según el topic
    const isSwitch  = topic.includes('switch');
    const isGemeloA = topic.includes('gemelo/a');
    const isGemeloB = topic.includes('gemelo/b');

    const nodoSwitch = db.getNodoByTipo('switch');
    const nodoGemelo = db.getNodoByTipo('twin outlet');

    if (isSwitch && nodoSwitch) {
      db.saveReading({
        nodo_id:     nodoSwitch.id,
        corriente_a: data.amps   ?? 0,
        watts_a:     data.watts  ?? 0,
        corriente_b: null,
        watts_b:     null,
        temperatura: data.temp   ?? null,
        relay_a:     data.relay  ? 1 : 0,
        relay_b:     0,
      });
      nilm.updateCache('switch', data.watts ?? 0);
    }

    if (isGemeloA && nodoGemelo) {
      db.saveReading({
        nodo_id:     nodoGemelo.id,
        corriente_a: data.amps   ?? 0,
        watts_a:     data.watts  ?? 0,
        corriente_b: null,
        watts_b:     null,
        temperatura: data.temp   ?? null,
        relay_a:     data.relay  ? 1 : 0,
        relay_b:     0,
      });
      nilm.updateCache('gemelo_a', data.watts ?? 0);
    }

    if (isGemeloB && nodoGemelo) {
      //actualización de la última fila del nodo gemelo para el switch b
      db.saveReading({
        nodo_id:     nodoGemelo.id,
        corriente_a: null,
        watts_a:     null,
        corriente_b: data.amps  ?? 0,
        watts_b:     data.watts ?? 0,
        temperatura: data.temp  ?? null,
        relay_a:     0,
        relay_b:     data.relay ? 1 : 0,
      });
      nilm.updateCache('gemelo_b', data.watts ?? 0);
    }

    //analiza el NILM después de cada lectura
    nilm.detectAndAlert();
  }

  //publica un comando de vuelta al esp32-c3
  publish(topic, payload) {
    if (!this.client) return;
    this.client.publish(topic, JSON.stringify(payload));
    console.log(`[MQTT] CMD → ${topic}:`, payload);
  }
}

module.exports = new MQTTSubscriber();
