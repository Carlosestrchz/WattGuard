#pragma once
#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>

class TempSensor {
public:
    TempSensor(uint8_t pin) : _ow(pin), _dt(&_ow) {}

    void begin() {
        _dt.begin();
    }

    float readCelsius() {
        _dt.requestTemperatures();
        float t = _dt.getTempCByIndex(0);
        if (t == DEVICE_DISCONNECTED_C) return -999.0f;
        return t;
    }

private:
    OneWire          _ow;
    DallasTemperature _dt;
};
