#include "philipsHueV2Device.h"
#include "hardware/serialDriver.h"
#include "logging.h"
#ifdef _MSC_VER
#include <io.h>
#else
#include <unistd.h>
#endif
#include "io/json.h"

#include "io/http/request.h"

PhilipsHueV2Device::PhilipsHueV2Device()
{
    keyfile = "philips_hue_v2.key";
    run_thread = false;
}

PhilipsHueV2Device::~PhilipsHueV2Device()
{
    if (run_thread)
    {
        run_thread = false;
        update_thread.join();
    }
}

bool PhilipsHueV2Device::configure(std::unordered_map<string, string> settings)
{
    if (settings.find("ip") != settings.end())
        ip_address = settings["ip"];

    if (settings.find("apikey") != settings.end())
    {
        api_key = settings["apikey"];
        keyfile = "";
    }
    else if (settings.find("keyfile") != settings.end())
        keyfile = settings["keyfile"];

    if (settings.find("port") != settings.end())
        port = settings["port"].toInt();

    std::vector<string> requested_lights;
    if (settings.find("lights") != settings.end())
    {
        for (const auto& id : settings["lights"].split(","))
        {
            auto stripped = id.strip();
            if (stripped.length() > 0)
                requested_lights.push_back(stripped);
        }
    }

    if (api_key == "")
    {
        FILE* f = fopen(keyfile.c_str(), "rt");
        if (f)
        {
            char buffer[128];
            if (fgets(buffer, sizeof(buffer), f))
                api_key = string(buffer).strip();
            fclose(f);
        }
    }

    if (api_key == "")
    {
        LOG(Error, "No Philips Hue v2 API key configured. Set 'apikey' or 'keyfile' in the device config.");
        return false;
    }

    LOG(Info, "Attempting to connect to Philips Hue V2 bridge ", ip_address, " on port ", port, " (HTTPS)");

    sp::io::http::Request http(ip_address, port, sp::io::http::Request::Scheme::Https);
    http.setHeader("hue-application-key", api_key);
    http.setHeader("Content-Type", "application/json");
    http.setSSLVerify(false);

    auto response = http.get("/clip/v2/resource/light");
    if (response.status == 200)
    {
        const auto& body = response.body;
        std::string err;
        if (auto json = sp::json::parse(body, err); json)
        {
            auto root = json.value();
            auto& data = root["data"];
            if (data.is_array())
            {
                std::vector<LightInfo> discovered;
                for (const auto& light : data)
                {
                    LightInfo info;
                    info.light_id = light["id"].get<std::string>();
                    discovered.push_back(info);
                    LOG(Info, "Discovered light: ", info.light_id);
                }

                if (!requested_lights.empty())
                {
                    lights.clear();
                    for (const auto& req_id : requested_lights)
                    {
                        bool found = false;
                        for (const auto& d : discovered)
                        {
                            if (d.light_id == req_id)
                            {
                                lights.push_back(d);
                                found = true;
                                break;
                            }
                        }
                        if (!found)
                            LOG(Warning, "Requested light not found on bridge: ", req_id);
                    }
                }
                else
                {
                    lights = std::move(discovered);
                }
                light_count = static_cast<int>(lights.size());
            }
        }
        else
        {
            LOG(Error, "JSON parsing failed: ", err);
            return false;
        }

        run_thread = true;
        update_thread = std::thread(&PhilipsHueV2Device::updateLoop, this);
        return true;
    }

    LOG(Error, "Failed to connect to Philips Hue V2 bridge: ", response.status);
    if (response.body.length() > 0) LOG(Warning, response.body);
    return false;
}

void PhilipsHueV2Device::setChannelData(int channel, float value)
{
    int light_idx = channel / 4;
    if (light_idx < 0 || light_idx >= light_count) return;

    std::lock_guard<std::mutex> lock(mutex);
    switch(channel % 4)
    {
    case 0: if (lights[light_idx].brightness != value) lights[light_idx].dirty = true; lights[light_idx].brightness = value; break;
    case 1: if (lights[light_idx].saturation != value) lights[light_idx].dirty = true; lights[light_idx].saturation = value; break;
    case 2: if (lights[light_idx].hue != value) lights[light_idx].dirty = true; lights[light_idx].hue = value; break;
    case 3: if (lights[light_idx].transitiontime != static_cast<int>(value)) lights[light_idx].dirty = true; lights[light_idx].transitiontime = static_cast<int>(value); break;
    }
}

int PhilipsHueV2Device::getChannelCount()
{
    return light_count * 4;
}

void PhilipsHueV2Device::updateLoop()
{
    sp::io::http::Request http(ip_address, port, sp::io::http::Request::Scheme::Https);
    http.setHeader("hue-application-key", api_key);
    http.setHeader("Content-Type", "application/json");
    http.setSSLVerify(false);

    while (run_thread)
    {
        for (int n = 0; n < light_count; n++)
        {
            if (lights[n].dirty)
            {
                LightInfo info;
                {
                    std::lock_guard<std::mutex> lock(mutex);
                    lights[n].dirty = false;
                    info = lights[n];
                }

                string state_key = "bri-" + string(static_cast<int>(info.brightness * 100.0f)) + "-sat-" + string(static_cast<int>(info.saturation * 100.0f)) + "-hue-" + string(static_cast<int>(info.hue * 360.0f)) + "-transition-" + string(info.transitiontime);
                if (info.laststate != state_key)
                {
                    lights[n].laststate = state_key;
                    string post_data;
                    if (info.brightness > 0.0f)
                    {
                        float hue_val = info.hue * 360.0f;
                        float sat_val = info.saturation * 100.0f;
                        float bri_val = info.brightness * 100.0f;
                        post_data = "{\"on\":{\"on\":true},\"dimming\":{\"brightness\":" + string(bri_val) + "},\"color\":{\"hue\":" + string(hue_val) + ",\"saturation\":" + string(sat_val) + "},\"dynamics\":{\"duration\":" + string(info.transitiontime * 100) + "}}";
                    }
                    else post_data = "{\"on\":{\"on\":false}}";

                    auto response = http.request("put", string{ "/clip/v2/resource/light/" } + info.light_id, post_data);
                    if (response.status != 200)
                    {
                        LOG(Warning, "Failed to set light [", info.light_id, "] philips hue v2 bridge: ", response.status);
                        LOG(Warning, response.body);
                    }
                }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}
