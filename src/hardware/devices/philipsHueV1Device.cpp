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
    {
        ip_address = settings["ip"];
    }
    if (settings.find("username") != settings.end())
    {
        username = settings["username"];
        userfile = "";
    }
    else if (settings.find("userfile") != settings.end())
    {
        userfile = settings["userfile"];
    }

    if (settings.find("port") != settings.end())
    {
        port = settings["port"].toInt();
    }

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

    LOG(INFO) << "Attempting to connect to Hue V1 bridge " << ip_address << " on port " << port;

    int retry_counter = 120 / 5;
    while(username == "")
    {
        sp::io::http::Request http(ip_address,port);

        LOG(INFO) << "No philips hue username. Going to request one. Be sure to press the button on the hue bridge.";
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
                            LOG(INFO) << body;
                            LOG(INFO) << "Got username from philips hue bridge: " << username;
                            break;
                        }
                    }
                }
            }
        }
        else
        {
            LOG(WARNING) << "Failed to contact philips hue bridge: " << response.status;
            LOG(WARNING) << response.body;
            if (response.status < 0)
                return false;
            if (response.status == 404)
                return false;
        }

        if (retry_counter > 0)
            retry_counter--;
        else
        {
            LOG(WARNING) << "Philips hue retry count exceeded.";
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
            LOG(WARNING) << "Failed to validate username on philips hue bridge: " << response.status;
            LOG(WARNING) << response.body;
            username = "";

            if (response.status < 0)
                return false;
            if (response.status == 404)
                return false;

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
                    LOG(DEBUG) << "Got key from Hue API " << currentInt;
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
            else
            {
                LOG(ERROR) << "Json parsing failed: " << err;
            }
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
    if (light_idx < 0 || light_idx >= light_count)
        return;

    std::lock_guard<std::mutex> lock(mutex);
    switch(channel % 4)
    {
    case 0: if (lights[light_idx].brightness != static_cast<int>(value * 254)) lights[light_idx].dirty = true; lights[light_idx].brightness = static_cast<int>(value * 254); break;
    case 1: if (lights[light_idx].saturation != static_cast<int>(value * 254)) lights[light_idx].dirty = true; lights[light_idx].saturation = static_cast<int>(value * 254); break;
    case 2: if (lights[light_idx].hue != static_cast<int>(value * 65535)) lights[light_idx].dirty = true; lights[light_idx].hue = static_cast<int>(value * 65535); break;
    case 3: if (lights[light_idx].transitiontime != static_cast<int>(value)) lights[light_idx].dirty = true; lights[light_idx].transitiontime = static_cast<int>(value); break;
    }
}

int PhilipsHueV1Device::getChannelCount()
{
    return light_count * 4;
}

void PhilipsHueV1Device::updateLoop()
{
    sp::io::http::Request http(ip_address,port);

    while(run_thread)
    {
        for(int n=0; n<light_count; n++)
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
                        LOG(WARNING) << "Failed to set light [" << (n + 1) << "] philips hue bridge: " << response.status;
                        LOG(WARNING) << response.body;
                    }
                }
            }
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
}
