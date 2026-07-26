#pragma once

#include "hardware/hardwareOutputDevice.h"

#include <stdint.h>
#include <thread>

// The DMX512SerialDevice can talk to Open DMX USB hardware, and just about any
// hardware which is just a serial port connected to a line driver.
class SerialPort;

class DMX512SerialDevice : public HardwareOutputDevice
{
private:
    SerialPort* port = nullptr;
    std::thread update_thread;

    bool run_thread = false;
    int channel_count = 512;
    int resend_delay = 25;
    uint8_t data_stream[512 + 1];
public:
    DMX512SerialDevice();
    virtual ~DMX512SerialDevice();

    // Configure the device.
    // Parameter: port: name of the serial port to connect to.
    virtual bool configure(std::unordered_map<string, string> settings) override;

    // Set a hardware channel output. Value is 0.0 to 1.0 for no to max output.
    virtual void setChannelData(int channel, float value) override;

    // Return the number of output channels supported by this device.
    virtual int getChannelCount() override;
private:
    void updateLoop();
};
