#pragma once
#include <Arduino.h>

class RelayController {
public:
    RelayController(uint8_t pin) : _pin(pin), _state(false) {}

    void begin() {
        pinMode(_pin, OUTPUT);
        setRelay(false);
    }

    void setRelay(bool on) {
        _state = on;
        digitalWrite(_pin, on ? HIGH : LOW);
    }

    bool getState() const { return _state; }

private:
    uint8_t _pin;
    bool    _state;
};
