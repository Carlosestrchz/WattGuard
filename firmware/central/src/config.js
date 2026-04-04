//configuración del nodo central
module.exports = {
  // MQTT
  mqtt: {
    //mosquitto corre en el nodo central (Arduino uno q)
    broker:  'mqtt://localhost',
    port:    1883,
    topics: [
      'wattguard/switch-proto.V1/a',
      'wattguard/twin-proto.V1/a',
      'wattguard/twin-proto.V1/b',
    ],
  },

  //API REST
  api: {
    port: 3000,
  },

  //SQLite
  db: {
    path: './db/wattguard.db',
  },

  //NILM
  nilm: {
    // Diferencia en watts entre switch y suma de nodos que dispara alerta
    threshold: 20,
  },

  //eléctrico
  electrical: {
    voltageV: 127,
  },
};
