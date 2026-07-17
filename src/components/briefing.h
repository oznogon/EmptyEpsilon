#pragma once

#include "stringImproved.h"
#include <glm/vec2.hpp>
#include <glm/gtc/type_precision.hpp>
#include <vector>

struct BriefingMapEntity
{
    int32_t id = 0;
    glm::vec2 position{0.0f, 0.0f};
    float rotation = 0.0f;
    float world_size = 1000.0f;
    string radar_trace_image;
    glm::u8vec4 color{255, 255, 255, 255};
    bool visible = true;
    string label;

    bool operator!=(const BriefingMapEntity& other) const
    {
        return id != other.id
            || position != other.position
            || rotation != other.rotation
            || world_size != other.world_size
            || radar_trace_image != other.radar_trace_image
            || color != other.color
            || visible != other.visible
            || label != other.label;
    }
};

struct BriefingMapKeyframe
{
    float timestamp = 0.0f;
    glm::vec2 camera_position{0.0f, 0.0f};
    float zoom = 5000.0f;
    std::vector<BriefingMapEntity> entities;

    bool operator!=(const BriefingMapKeyframe& other) const
    {
        if (timestamp != other.timestamp
            || camera_position != other.camera_position
            || zoom != other.zoom
            || entities.size() != other.entities.size())
            return true;

        for (size_t i = 0; i < entities.size(); i++)
        {
            if (entities[i] != other.entities[i])
                return true;
        }
        return false;
    }
};

struct BriefingMapPage
{
    float duration = 0.0f;
    std::vector<BriefingMapKeyframe> keyframes;

    bool operator!=(const BriefingMapPage& other) const
    {
        if (duration != other.duration
            || keyframes.size() != other.keyframes.size())
            return true;

        for (size_t i = 0; i < keyframes.size(); i++)
        {
            if (keyframes[i] != other.keyframes[i])
                return true;
        }
        return false;
    }
};

// Define a page in a Briefing to display on the BriefingScreen.
// If any of these members are defined, then when a BriefingPage is viewed on the BriefingScreen, the screen displays the page's caption and image. If the BriefingScreen's playback mode is enabled, it also plays audio (defined as a file path relative to the resources directory tree) and advances to the next slide automatically after the duration (in seconds) elapses.
class BriefingPage
{
public:
    string caption;
    string image;
    string audio;
    float duration = 0.0f;
    BriefingMapPage map_data;

    bool operator!=(const BriefingPage& other) const {
        return caption != other.caption || image != other.image || audio != other.audio || duration != other.duration || map_data != other.map_data;
    }
};

// Define a Briefing to display on the BriefingScreen.
// A Briefing is a basic presentation defined as a set of BriefingPages. These pages are viewed sequentially on the BriefingScreen.
class Briefing
{
public:
    std::vector<BriefingPage> pages;
};
