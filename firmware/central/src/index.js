const api  = require('./apiServer');
const mqtt = require('./mqttSubscriber');

console.log('=== WattGuard · Nodo Central v1.0.0 ===');

//arranca el broker MQTT subscriber
mqtt.connect(); //coemntado para desarrolloo del front end

//arranca API REST
api.start();

//anejo limpio de cierre de conexión
process.on('SIGINT', () => {
  console.log('\n[OK] Cerrando servidor...');
  process.exit(0);
});
