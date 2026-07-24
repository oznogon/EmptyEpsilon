#pragma once

#include "hardware/hardwareOutputDevice.h"

#include <thread>
#include <mutex>
#include <vector>
#include <string>

class PhilipsHueV2Device : public HardwareOutputDevice
{
public:
    PhilipsHueV2Device();
    virtual ~PhilipsHueV2Device();

    virtual bool configure(std::unordered_map<string, string> settings) override;

    virtual void setChannelData(int channel, float value) override;

    virtual int getChannelCount() override;
private:
    class LightInfo
    {
    public:
        LightInfo() : dirty(true), brightness(0.0f), saturation(0.0f), hue(0.0f), transitiontime(0), laststate(0) {}

        bool dirty;
        float brightness;
        float saturation;
        float hue;
        int transitiontime;
        string laststate;
        string light_id;
    };

    std::thread update_thread;
    std::mutex mutex;
    std::vector<LightInfo> lights;

    bool run_thread;

    void updateLoop();

    string ip_address;
    int port = 443;
    string api_key;
    string keyfile;
    int light_count;
};
