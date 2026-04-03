# WattGuard - Backend (Node.js)

## Directorio de instalación

```bash
cd firmware/central
npm install
```

## Como ejecutar

```bash
# Producción
npm start

# Desarrollo (recarga automática)
npm run dev
```

## Probar en local (sin nodo/hardware)

### 1. Instala Mosquitto

**Windows:** https://mosquitto.org/download  
**Mac:** `brew install mosquitto`  
**Linux:** `sudo apt install mosquitto mosquitto-clients`

Inicia el broker:
```bash
mosquitto -v
```

### 2. Inicia el backend
```bash
npm start
```
Si todo es correcto, verás los logs:
```
=== WattGuard - Nodo Central v1.0.0 ===
[DB] SQLite inicializado en ./db/wattguard.db
[MQTT] Conectado al broker
[API] Servidor en http://localhost:3000
```

### 3. Simulación de lecturas de un ESP32-C3
Abre una terminal y publica mensajes MQTT de prueba:
```bash
mosquitto_pub -t "wattguard/switch/a" \
  -m '{"nodeId":"switch","canal":"a","watts":85.5,"amps":0.67,"temp":28.3,"relay":true}'

mosquitto_pub -t "wattguard/gemelo/a" \
  -m '{"nodeId":"gemelo","canal":"a","watts":60.0,"amps":0.47,"temp":27.1,"relay":true}'

mosquitto_pub -t "wattguard/gemelo/b" \
  -m '{"nodeId":"gemelo","canal":"b","watts":15.0,"amps":0.12,"temp":27.1,"relay":false}'
```

### 4. Prueba de endpoints REST

```bash
# Estado actual
curl http://localhost:3000/api/estado

# Historial
curl http://localhost:3000/api/lecturas?limit=10

# Alertas activas
curl http://localhost:3000/api/alertas

# Controlar relay
curl -X POST http://localhost:3000/api/relay/2 \
  -H "Content-Type: application/json" \
  -d '{"canal":"a","estado":false}'

# Configuración
curl http://localhost:3000/api/config
```

### 5. Simular detección NILM
La manera mas simple de disparar una alerta NILM, es publicando un switch con más watts que la suma de los nodos:
```bash
# Switch: 150W, nodos: 75W → diferencia 75W > umbral 20W → alerta
mosquitto_pub -t "wattguard/switch/a" \
  -m '{"watts":150,"amps":1.18,"temp":29.0,"relay":true}'
```
Verás en el log: `[NILM] Alerta creada: Consumo sin nodo: 75.0W`

## Estructura de archivos
```
firmware/central/
├── package.json
├── src/
│   ├── index.js          ← Entry point
│   ├── config.js         ← Parámetros centrales
│   ├── database.js       ← SQLite (todas las tablas)
│   ├── mqttSubscriber.js ← Recibe lecturas + publica comandos
│   ├── nilmDetector.js   ← Motor de detección de anomalías
│   └── apiServer.js      ← Endpoints REST
└── db/
    └── wattguard.db      ← Se crea automáticamente al iniciar
```
