#include "uDMXDevice.h"
#include "logging.h"
#ifdef _WIN32
#include "dynamicLibrary.h"
#include <windows.h>

std::unique_ptr<DynamicLibrary> UDMX_dll;

extern "C" {
    bool (__stdcall *UDMX_Configure)();
    bool (__stdcall *UDMX_Connected)();
    bool (__stdcall *UDMX_ChannelSet)(long Channel, long Value);
    bool (__stdcall *UDMX_ChannelsSet)(long ChannelCnt, long Channel, long* Value);
}
#endif

// Configure the device.
bool UDMXDevice::configure(std::unordered_map<string, string> settings)
{
#ifdef _WIN32
    UDMX_dll = DynamicLibrary::open("uDMX.dll");
    if (UDMX_dll == NULL)
    {
        LOG(Error, "[udmx] Failed to load uDMX.dll for uDMX hardware.");
        return false;
    }
    UDMX_Configure = UDMX_dll->getFunction<decltype(UDMX_Configure)>("Configure");
    if (UDMX_Configure == NULL)
    {
        LOG(Error, "[udmx] Failed to find Configure function in uDMX.dll.");
        return false;
    }
    UDMX_Connected = UDMX_dll->getFunction<decltype(UDMX_Connected)>("Connected");
    if (UDMX_Connected == NULL)
    {
        LOG(Error, "[udmx] Failed to find Connected function in uDMX.dll.");
        return false;
    }
    UDMX_ChannelSet = UDMX_dll->getFunction<decltype(UDMX_ChannelSet)>("ChannelSet");
    if (UDMX_ChannelSet == NULL)
    {
        LOG(Error, "[udmx] Failed to find ChannelSet function in uDMX.dll.");
        return false;
    }
    UDMX_ChannelsSet = UDMX_dll->getFunction<decltype(UDMX_ChannelsSet)>("ChannelsSet");
    if (UDMX_ChannelsSet == NULL)
    {
        LOG(Error, "[udmx] Failed to find ChannelsSet function in uDMX.dll.");
        return false;
    }

    if (!UDMX_Connected())
    {
        LOG(Error, "[udmx] uDMX.dll reported device isn't connected, but resuming use anyway.");
        // return false;
    }

    return true;
#else
    LOG(Error, "[udmx] uDMX hardware isn't supported on this operating system.");
    return false;
#endif
}

//Set a hardware channel output. Value is 0.0 to 1.0 for no to max output.
void UDMXDevice::setChannelData(int channel, float value)
{
#ifdef _WIN32
    UDMX_ChannelSet(channel, static_cast<long>(value * 255));
#endif
}

int UDMXDevice::getChannelCount()
{
    return 512;
}
