# WattGuard — Firmware ESP32-C3

## Estructura
```
firmware/nodo/
├── platformio.ini     # Configuración PlatformIO
├── wokwi.toml         # Simulación Wokwi
├── diagram.json       # Circuito Wokwi
├── include/
│   ├── Config.h       # Parámetros del nodo (WiFi, MQTT, pines)
│   ├── CurrentSensor.h
│   ├── TempSensor.h
│   └── RelayController.h
└── src/
    └── main.cpp
```

## Configurar para cada nodo

Editar `include/Config.h`:

| Variable | Caja 1 (switch) | Caja 2 (gemelo) |
|---|---|---|
| `NODE_ID` | `"switch"` | `"gemelo"` |
| `NODE_TYPE` | `"switch"` | `"twin"` |
| `MQTT_TOPIC_A` | `"wattguard/switch/a"` | `"wattguard/gemelo/a"` |
| `MQTT_TOPIC_B` | (no aplica) | `"wattguard/gemelo/b"` |

## Simulación en Wokwi

En caso de no contar con el dispositivo fisico, se puede simular en Wokwi (https://wokwi.com/projects/new/esp32-c3), adaptando el codigo fuente al flujo de trabajo establecido en la plataforma.

> NOTA: En Wokwi los SCT-013 no existen como componente. Los ADC0/ADC1 leerán 0A
> hasta que ajustes un potenciómetro simulado en su lugar para probar el flujo.

## Calibración del SCT-013 (con hardware real)

1. Conecta una carga conocida (ej. foco de 100W = ~0.79A)
2. Ajusta `SCT_A_FACTOR` o `SCT_B_FACTOR` hasta que el serial muestre ~0.79A
3. Fórmula: `nuevo_factor = factor_actual × (corriente_real / corriente_medida)`

## Dependencias PlatformIO

```
knolleary/PubSubClient
milesburton/DallasTemperature
paulstoffregen/OneWire
bblanchon/ArduinoJson
```