#pragma once

#include "hardware/hardwareOutputDevice.h"

#include <thread>
#include <mutex>

class PhilipsHueV1Device : public HardwareOutputDevice
{
public:
    PhilipsHueV1Device();
    virtual ~PhilipsHueV1Device();

    virtual bool configure(std::unordered_map<string, string> settings) override;

    virtual void setChannelData(int channel, float value) override;

    virtual int getChannelCount() override;
private:
    class LightInfo
    {
    public:
        LightInfo() : dirty(true), brightness(0), saturation(0), hue(0), transitiontime(0), laststate(0) {}

        bool dirty;
        int brightness;
        int saturation;
        int hue;
        int transitiontime;
        string laststate;
    };

    std::thread update_thread;
    std::mutex mutex;
    std::vector<LightInfo> lights;

    bool run_thread;

    void updateLoop();

    string ip_address;
    int port = 80;
    string username;
    string userfile;
    int light_count;
};
