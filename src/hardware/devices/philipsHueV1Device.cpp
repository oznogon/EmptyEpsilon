#include "philipsHueV1Device.h"
#include "hardware/serialDriver.h"
#include "logging.h"
#ifdef _MSC_VER
#include <io.h>
#else
#include <unistd.h>
#endif
#include "io/json.h"

#include "io/http/request.h"

PhilipsHueV1Device::PhilipsHueV1Device()
{
    userfile = "philips_hue.name";
    run_thread = false;
}

PhilipsHueV1Device::~PhilipsHueV1Device()
{
    if (run_thread)
    {
        run_thread = false;
        update_thread.join();
    }
}

bool PhilipsHueV1Device::configure(std::unordered_map<string, string> settings)
{
    if (settings.find("ip") != settings.end())
        ip_address = settings["ip"];

    if (settings.find("username") != settings.end())
    {
        username = settings["username"];
        userfile = "";
    }
    else if (settings.find("userfile") != settings.end())
        userfile = settings["userfile"];

    if (settings.find("port") != settings.end())
        port = settings["port"].toInt();

    if (username == "")
    {
        FILE* f = fopen(userfile.c_str(), "rt");
        if (f)
        {
            char buffer[128];
            if (fgets(buffer, sizeof(buffer), f))
                username = string(buffer).strip();
            fclose(f);
        }
    }

    LOG(Info, "[huev1] Attempting to connect to Hue V1 bridge ", ip_address, " on port ", port);

    int retry_counter = 24; // 120 / 5; every 5 seconds for 2 minutes

    while (username == "")
    {
        sp::io::http::Request http(ip_address, port);
        http.setHeader("Content-Type", "application/json");

        LOG(Info, "[huev1] No Philips Hue username provided. Going to request one. Press the link button on the Philips Hue V1 bridge.");
        auto response = http.post("/api", "{\"devicetype\":\"EmptyEpsilon#EmptyEpsilon\"}");

        if (response.status == 200)
        {
            const auto& body = response.body;

            int idx = body.find("\"username\"");
            if (idx > 0)
            {
                idx = body.find(":", idx);
                if (idx > 0)
                {
                    idx = body.find("\"", idx);
                    if (idx > 0)
                    {
                        int end_idx = body.find("\"", idx + 1);
                        if (end_idx > 0)
                        {
                            username = body.substr(idx + 1, end_idx);
                            LOG(Info, "[huev1] ", body);
                            LOG(Info, "[huev1] Got username from Philips Hue V1 bridge: ", username);
                            break;
                        }
                    }
                }
            }
        }
        else
        {
            LOG(Warning, "[huev1] Failed to contact Philips Hue V1 bridge: ", response.status);
            LOG(Warning, "[huev1] ", response.body);

            if (response.status < 0 || response.status == 404) return false;
        }

        if (retry_counter > 0) retry_counter--;
        else
        {
            LOG(Warning, "[huev1] Philips Hue V1 retry count exceeded. Not connecting to the bridge.");
            return false;
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(5000));
    }

    if (username != "")
    {
        sp::io::http::Request http(ip_address,port);
        auto response = http.get(string{ "/api/" } + username + "/lights");

        if (response.status != 200)
        {
            LOG(Warning, "[huev1] Failed to validate username on Philips Hue V1 bridge: ", response.status);
            LOG(Warning, "[huev1] ", response.body);
            username = "";

            if (response.status < 0 || response.status == 404) return false;

            if (userfile != "")
#ifdef _MSC_VER
                _unlink(userfile.c_str());
#else
                unlink(userfile.c_str());
#endif
        }
        else
        {
            const auto& body = response.body;
            std::string err;

            if (auto json = sp::json::parse(body, err); json)
            {
                auto hue_json = json.value();
                light_count = 0;

                for (const auto& entry : hue_json.items())
                {
                    auto currentInt = string(entry.key()).toInt();
                    LOG(Debug, "[huev1] Got key from Hue API: ", currentInt);
                    if (currentInt >= light_count) light_count = currentInt;
                }

                lights.resize(light_count);

                FILE* f = fopen(userfile.c_str(), "wt");
                if (f)
                {
                    fprintf(f, "%s\n", username.c_str());
                    fclose(f);
                }
            }
            else LOG(Error, "[huev1] JSON parsing failed: ", err);
        }
    }

    if (username != "")
    {
        run_thread = true;
        update_thread = std::thread(&PhilipsHueV1Device::updateLoop, this);
        return true;
    }
    return false;
}

void PhilipsHueV1Device::setChannelData(int channel, float value)
{
    int light_idx = channel / 4;
    if (light_idx < 0 || light_idx >= light_count) return;

    auto light = lights[light_idx];
    std::lock_guard<std::mutex> lock(mutex);

    switch (channel % 4)
    {
    case 0:
        {
            const int new_brightness = static_cast<int>(value * 254);
            if (light.brightness != new_brightness) light.dirty = true;
            light.brightness = new_brightness;
        }
        break;
    case 1:
        {
            const int new_saturation = static_cast<int>(value * 254);
            if (light.saturation != new_saturation) light.dirty = true;
            light.saturation = new_saturation;
        }
        break;
    case 2:
        {
            const int new_hue = static_cast<int>(value * 65535);
            if (light.hue != new_hue) light.dirty = true;
            light.hue = new_hue;
        }
        break;
    case 3:
        {
            const int new_transitiontime = static_cast<int>(value);
            if (light.transitiontime != new_transitiontime) light.dirty = true;
            light.transitiontime = new_transitiontime;
        }
        break;
    }
}

int PhilipsHueV1Device::getChannelCount()
{
    return light_count * 4;
}

void PhilipsHueV1Device::updateLoop()
{
    sp::io::http::Request http(ip_address,port);

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

                string post_data;
                if (info.laststate != "sat-" + string(info.saturation) + "-bri-" + string(info.brightness) + "-hue-" + string(info.hue) + "-transition-" + string(info.transitiontime))
                {
                    lights[n].laststate = "sat-" + string(info.saturation) + "-bri-" + string(info.brightness) + "-hue-" + string(info.hue) + "-transition-" + string(info.transitiontime);

                    if (info.brightness > 0)
                        post_data = "{\"on\":true, \"sat\":"+string(info.saturation)+", \"bri\":"+string(info.brightness)+",\"hue\":"+string(info.hue)+", \"transitiontime\": "+string(info.transitiontime)+"}";
                    else
                        post_data = "{\"on\":false, \"transitiontime\": "+string(info.transitiontime)+"}";

                    auto response = http.request("PUT", string{ "/api/" } + username + "/lights/" + string(n + 1) + "/state", post_data);
                    if (response.status != 200)
                    {
                        LOG(Warning, "[huev1] Failed to set light [", (n + 1), "] on Philips Hue V1 bridge: ", response.status);
                        LOG(Warning, "[huev1] ", response.body);
                    }
                }
            }
        }

        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}
