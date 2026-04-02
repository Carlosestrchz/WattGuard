#pragma once
#include <Arduino.h>
#include "Config.h"

class CurrentSensor {
public:
    CurrentSensor(uint8_t adcPin, float calibrationFactor)
        : _pin(adcPin), _cal(calibrationFactor) {}

    void begin() {
        pinMode(_pin, INPUT);
        //Descarta primeras lecturas para estabilización
        for (int i = 0; i < 20; i++) analogRead(_pin);
    }

    float readRMS() {
        double sumSq = 0.0;
        int midpoint = (int)(ADC_RESOLUTION / 2.0f);
        for (int i = 0; i < SAMPLES; i++) {
            int centered = analogRead(_pin) - midpoint;
            sumSq += (double)centered * centered;
        }
        double rms = sqrt(sumSq / SAMPLES);
        float voltage = (rms / ADC_RESOLUTION) * ADC_VREF;
        return voltage * _cal;
    }

    float toWatts(float rmsAmps) {
        return rmsAmps * VOLTAGE_V;
    }

private:
    uint8_t _pin;
    float   _cal;
};
