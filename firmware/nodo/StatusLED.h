#pragma once
#include <Arduino.h>
#include "Config.h"

enum NodeState {
    //Led azul parpadea rápido para el pairing
    STATE_PAIRING,
    //Led amarillo parpadea lento por desconexión con el nodo central
    STATE_WIFI_ONLY,
    //Led verde para todo ok
    STATE_CONNECTED,
};

class StatusLED {
public:
    void begin() {
        pinMode(PIN_LED_GREEN,  OUTPUT);
        pinMode(PIN_LED_YELLOW, OUTPUT);
        pinMode(PIN_LED_BLUE,   OUTPUT);
        pinMode(PIN_BTN_PAIR,   INPUT_PULLUP);
        _allOff();
    }

    void update() {
        unsigned long now = millis();
        switch (_state) {
            case STATE_PAIRING:
                if (now - _lastBlink >= 200) {
                    _lastBlink  = now;
                    _blinkState = !_blinkState;
                    digitalWrite(PIN_LED_BLUE, _blinkState ? HIGH : LOW);
                }
                break;
            case STATE_WIFI_ONLY:
                if (now - _lastBlink >= 800) {
                    _lastBlink  = now;
                    _blinkState = !_blinkState;
                    digitalWrite(PIN_LED_YELLOW, _blinkState ? HIGH : LOW);
                }
                break;
            case STATE_CONNECTED:
                break;
        }
    }

    void setState(NodeState s) {
        if (_state == s) return;
        _state      = s;
        _lastBlink  = millis();
        _blinkState = false;
        _allOff();
        if (s == STATE_CONNECTED) digitalWrite(PIN_LED_GREEN, HIGH);
    }

    bool isPairingRequested() {
        if (digitalRead(PIN_BTN_PAIR) == LOW) {
            if (_btnPressStart == 0) _btnPressStart = millis();
            if (millis() - _btnPressStart >= BTN_HOLD_MS) {
                _btnPressStart = 0;
                return true;
            }
        } else {
            _btnPressStart = 0;
        }
        return false;
    }

    NodeState getState() const { return _state; }

private:
    NodeState     _state         = STATE_WIFI_ONLY;
    unsigned long _lastBlink     = 0;
    unsigned long _btnPressStart = 0;
    bool          _blinkState    = false;

    void _allOff() {
        digitalWrite(PIN_LED_GREEN,  LOW);
        digitalWrite(PIN_LED_YELLOW, LOW);
        digitalWrite(PIN_LED_BLUE,   LOW);
    }
};
