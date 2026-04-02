#pragma once

// Identificación del nodo, proto.v1 porque es la primera versión ;(
// hay tres tipos: twin-proto.V1, switch-proto.V1, y outlet-proto.v1
#define NODE_ID       "switch-proto.V1"
//tipo de nodo: outlet, twin outlet o switch para diferenciar sus caracteristicas
#define NODE_TYPE     "switch"

//Red local statica solo para fines del prototipo. En una implementación
//real usariamos aprovisionamiento individual como minimo
#define WIFI_SSID     "WattGuard-Net"
#define WIFI_PASS     "wattguard2026"

//MQTT
// IP estática del Arduino UNO Q, para simplificar el proceso de conexión
#define MQTT_BROKER   "192.168.4.1"
#define MQTT_PORT     1883

//logica de MQTT para un noto de tipo twin outlet
//#define MQTT_TOPIC_A  "wattguard/twin-proto.V1/a"
//#define MQTT_TOPIC_B  "wattguard/twin-proto.V1/b"
//#define MQTT_CMD      "wattguard/twin-proto.V1/cmd"

//logica MQTT para un nodo de tipo switch
#define MQTT_TOPIC_A  "wattguard/switch-proto.V1/a"
#define MQTT_TOPIC_B  "wattguard/switch-proto.V1/a"
#define MQTT_CMD      "wattguard/switch-proto.V1/cmd"

//logica MQTT para un nodo de tipo outlet
//#define MQTT_TOPIC_A  "wattguard/outlet-proto.V1/a"
//#define MQTT_TOPIC_B  "wattguard/outlet-proto.V1/a"
//#define MQTT_CMD      "wattguard/outlet-proto.V1/cmd"

//Sensores y actuadores
//GPIO2 = SCT-013 canal A
#define PIN_ADC_A     2
//GPIO4 = SCT-013 canal B
#define PIN_ADC_B     4
//GPIO5 = relay canal A
#define PIN_RELAY_A   5
//GPIO6 = relay canal B
#define PIN_RELAY_B   6
//GPIO7 = DS18B20 OneWire
#define PIN_DS18B20   7

//indicadores led y botón de emparejamiento (aunque falta ver si omitimos ese botón al final)
//GPIO8 = conectado al broker
#define PIN_LED_GREEN  8
//GPIO9 = WiFi OK pero sin broker
#define PIN_LED_YELLOW 9
//GPIO10 = modo emparejamiento
#define PIN_LED_BLUE   10
//GPIO3 = botón emparejamiento (pull-up, activo LOW)
#define PIN_BTN_PAIR   3

// Eléctrico
//Voltaje fijo México, ya que para MVP no integraremos sensor de voltaje por cuestión de tiempo :(
#define VOLTAGE_V      127.0f
//Calibración SCT 50A (ajustar en banco)
#define SCT_A_FACTOR   30.0f
//Calibración SCT 30A (ajustar en banco)
#define SCT_B_FACTOR   15.0f
#define ADC_VREF       3.3f
#define ADC_RESOLUTION 4095.0f
//Muestras para cálculo RMS
#define SAMPLES        1000

// Intervalos
#define PUBLISH_INTERVAL_MS  2000
//Pulsación para emparejamiento
#define BTN_HOLD_MS          3000  
