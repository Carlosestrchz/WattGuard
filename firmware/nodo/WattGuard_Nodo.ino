#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#include "Config.h"
#include "CurrentSensor.h"
#include "TempSensor.h"
#include "RelayController.h"
#include "StatusLED.h"

// Instancias
CurrentSensor   sensorA(PIN_ADC_A, SCT_A_FACTOR);
CurrentSensor   sensorB(PIN_ADC_B, SCT_B_FACTOR);
TempSensor      tempSensor(PIN_DS18B20);
RelayController relayA(PIN_RELAY_A);
RelayController relayB(PIN_RELAY_B);
StatusLED       status;

WiFiClient   wifiClient;
PubSubClient mqtt(wifiClient);

unsigned long lastPublish = 0;

//Callback MQTT — comandos entrantes desde el UNO Q
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
    String msg;
    for (unsigned int i = 0; i < length; i++) msg += (char)payload[i];

    JsonDocument doc;
    if (deserializeJson(doc, msg)) {
        Serial.println("[MQTT] JSON invalido");
        return;
    }

    const char* canal  = doc["canal"];
    bool        estado = doc["estado"];

    if (String(canal) == "a") {
        relayA.setRelay(estado);
        Serial.printf("[CMD] Relay A -> %s\n", estado ? "ON" : "OFF");
    } else if (String(canal) == "b") {
        relayB.setRelay(estado);
        Serial.printf("[CMD] Relay B -> %s\n", estado ? "ON" : "OFF");
    }
}

bool connectWifi() {
    Serial.printf("[WiFi] Conectando a %s", WIFI_SSID);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - start > 10000) {
            Serial.println("\n[WiFi] Timeout");
            return false;
        }
        status.update();
        delay(200);
        Serial.print(".");
    }
    Serial.printf("\n[WiFi] IP: %s\n", WiFi.localIP().toString().c_str());
    return true;
}

bool connectMqtt() {
    mqtt.setServer(MQTT_BROKER, MQTT_PORT);
    mqtt.setCallback(onMqttMessage);
    String clientId = String("wg-") + NODE_ID + "-" + String(random(0xffff), HEX);
    if (mqtt.connect(clientId.c_str())) {
        mqtt.subscribe(MQTT_CMD);
        Serial.printf("[MQTT] Conectado · suscrito a %s\n", MQTT_CMD);
        return true;
    }
    Serial.printf("[MQTT] Fallo rc=%d\n", mqtt.state());
    return false;
}

void publishReading(const char* topic, float watts, float amps,
                    float temp, const char* canal, bool relayState) {
    JsonDocument doc;
    doc["nodeId"] = NODE_ID;
    doc["canal"]  = canal;
    doc["watts"]  = round(watts * 10.0f) / 10.0f;
    doc["amps"]   = round(amps  * 100.0f) / 100.0f;
    doc["temp"]   = round(temp  * 10.0f) / 10.0f;
    doc["relay"]  = relayState;
    doc["ts"]     = millis();

    char buffer[256];
    serializeJson(doc, buffer);
    mqtt.publish(topic, buffer);
    Serial.printf("[PUB] %s -> %s\n", topic, buffer);
}

void setup() {
    Serial.begin(115200);
    //arreglo temporal. retraso para que el monitor serial se conecte
    delay(3000);
    Serial.printf("\nWattGuard. \nID de nodo: [%s]\n Tipo de nodo: [%s]\n", NODE_ID, NODE_TYPE);

    status.begin();
    status.setState(STATE_WIFI_ONLY);

    sensorA.begin();
    sensorB.begin();
    tempSensor.begin();
    relayA.begin();
    relayB.begin();

    if (connectWifi() && connectMqtt()) {
        status.setState(STATE_CONNECTED);
    }
}

void loop() {
    status.update();

    //Botón presionado 3 segundos reconecta
    if (status.isPairingRequested()) {
        Serial.println("[BTN] Reconectando...");
        status.setState(STATE_PAIRING);
        WiFi.disconnect();
        delay(500);
        if (connectWifi() && connectMqtt()) {
            status.setState(STATE_CONNECTED);
        } else {
            status.setState(STATE_WIFI_ONLY);
        }
    }

    //Mantener conexión MQTT
    if (WiFi.status() == WL_CONNECTED) {
        if (!mqtt.connected()) {
            status.setState(STATE_WIFI_ONLY);
            if (connectMqtt()) status.setState(STATE_CONNECTED);
        } else {
            mqtt.loop();
            status.setState(STATE_CONNECTED);
        }
    } else {
        status.setState(STATE_WIFI_ONLY);
    }

    //Publicar lecturas cada 2 segundos
    unsigned long now = millis();
    if (mqtt.connected() && now - lastPublish >= PUBLISH_INTERVAL_MS) {
        lastPublish = now;

        float ampsA = sensorA.readRMS();
        float ampsB = sensorB.readRMS();
        float temp  = tempSensor.readCelsius();

        publishReading(MQTT_TOPIC_A, sensorA.toWatts(ampsA), ampsA,
                       temp, "a", relayA.getState());

        if (String(NODE_TYPE) == "twin") {
            publishReading(MQTT_TOPIC_B, sensorB.toWatts(ampsB), ampsB,
                           temp, "b", relayB.getState());
        }
    }
}
