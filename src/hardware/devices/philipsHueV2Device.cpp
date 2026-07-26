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
            if (stripped.length() > 0) requested_lights.push_back(stripped);
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
        LOG(Error, "[huev2] No Philips Hue V2 API key configured. Set 'apikey' or 'keyfile' in the device config.");
        return false;
    }

    LOG(Info, "[huev2] Attempting to connect to Philips Hue V2 bridge ", ip_address, " on port ", port, " (HTTPS)");

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
                    LOG(Info, "[huev2] Discovered light: ", info.light_id);
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
                            LOG(Warning, "[huev2] Requested light not found on bridge: ", req_id);
                    }
                }
                else lights = std::move(discovered);

                light_count = static_cast<int>(lights.size());
            }
        }
        else
        {
            LOG(Error, "[huev2] JSON parsing failed: ", err);
            return false;
        }

        run_thread = true;
        update_thread = std::thread(&PhilipsHueV2Device::updateLoop, this);
        return true;
    }

    LOG(Error, "[huev2] Failed to connect to Philips Hue V2 bridge: ", response.status);
    if (response.body.length() > 0) LOG(Warning, "[huev2] ", response.body);

    return false;
}

void PhilipsHueV2Device::setChannelData(int channel, float value)
{
    const int light_idx = channel / 4;
    if (light_idx < 0 || light_idx >= light_count) return;

    auto light = lights[light_idx];
    std::lock_guard<std::mutex> lock(mutex);
    switch(channel % 4)
    {
    case 0:
        {
            if (light.brightness != value)
                light.dirty = true;

            light.brightness = value;
        }
        break;
    case 1:
        {
            if (light.saturation != value)
                light.dirty = true;

            light.saturation = value;
        }
        break;
    case 2:
        {
            if (light.hue != value)
                light.dirty = true;

            light.hue = value;
        }
        break;
    case 3:
        {
            if (light.transitiontime != static_cast<int>(value))
                light.dirty = true;

            light.transitiontime = static_cast<int>(value);
        }
        break;
    }
}

int PhilipsHueV2Device::getChannelCount()
{
    return light_count * 4;
}

static void hueSatToXY(float hue_deg, float sat, float& x, float& y)
{
    const float r_x = 0.6915f, r_y = 0.3083f;
    const float g_x = 0.17f, g_y = 0.7f;
    const float b_x = 0.1532f, b_y = 0.0475f;

    if (sat <= 0.0f)
    {
        x = 0.3333f;
        y = 0.3333f;
        return;
    }

    float t;
    float edge_x, edge_y;

    if (hue_deg < 120.0f)
    {
        t = hue_deg / 120.0f;
        edge_x = r_x + t * (g_x - r_x);
        edge_y = r_y + t * (g_y - r_y);
    }
    else if (hue_deg < 240.0f)
    {
        t = (hue_deg - 120.0f) / 120.0f;
        edge_x = g_x + t * (b_x - g_x);
        edge_y = g_y + t * (b_y - g_y);
    }
    else
    {
        t = (hue_deg - 240.0f) / 120.0f;
        edge_x = b_x + t * (r_x - b_x);
        edge_y = b_y + t * (r_y - b_y);
    }

    x = edge_x + (1.0f - sat) * (0.3333f - edge_x);
    y = edge_y + (1.0f - sat) * (0.3333f - edge_y);
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
                        float hue_deg = info.hue * 360.0f;
                        float sat = info.saturation;
                        float cx, cy;
                        hueSatToXY(hue_deg, sat, cx, cy);
                        int bri_int = static_cast<int>(info.brightness * 100.0f);
                        post_data = "{\"on\":{\"on\":true},\"dimming\":{\"brightness\":" + string(bri_int) + "},\"color\":{\"xy\":{\"x\":" + string(cx, 4) + ",\"y\":" + string(cy, 4) + "}},\"dynamics\":{\"duration\":" + string(info.transitiontime * 100) + "}}";
                    }
                    else post_data = "{\"on\":{\"on\":false}}";

                    auto response = http.request("PUT", string{"/clip/v2/resource/light/"} + info.light_id, post_data);
                    if (response.status != 200)
                    {
                        LOG(Warning, "[huev2] Failed to set light [", info.light_id, "] on Philips Hue V2 bridge: ", response.status);
                        LOG(Warning, "[huev2] ", response.body);
                    }
                }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}
