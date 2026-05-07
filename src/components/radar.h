#pragma once

#include "io/dataBuffer.h"
#include "script/callback.h"


class RadarTrace
{
public:
    static constexpr uint32_t Rotate = 1 << 0;
    static constexpr uint32_t ColorByFaction = 1 << 1;
    static constexpr uint32_t ArrowIfNotScanned = 1 << 2;
    static constexpr uint32_t BlendAdd = 1 << 3;
    static constexpr uint32_t LongRange = 1 << 4;

    string icon;
    float min_size = 16.0;   //Size in screen "pixels"
    float max_size = 256.0; //Size in screen "pixels"
    float radius = 0.0;     // Size in world "units"
    glm::u8vec4 color{255,255,255,255};

    uint32_t flags = Rotate | LongRange;
};


// Radar signature data, used by rawScannerDataOverlay.
class RawRadarSignatureInfo
{
public:
    float gravitational;
    float electrical;
    float thermal;

    RawRadarSignatureInfo()
    : gravitational(0), electrical(0), thermal(0) {}

    RawRadarSignatureInfo(float gravitational, float electrical, float thermal)
    : gravitational(gravitational), electrical(electrical), thermal(thermal) {}

    RawRadarSignatureInfo& operator+=(const RawRadarSignatureInfo& o)
    {
        gravitational += o.gravitational;
        electrical += o.electrical;
        thermal += o.thermal;
        return *this;
    }

    RawRadarSignatureInfo operator*(const float f) const
    {
        return RawRadarSignatureInfo(gravitational * f, electrical * f, thermal * f);
    }
};

// Dynamic radar signature is added to entities that
//  generate additional radar signature info by live systems (impulse engine, etc...)
class DynamicRadarSignatureInfo
{
public:
    float gravitational = 0.0f;
    float electrical = 0.0f;
    float thermal = 0.0f;
};

class LongRangeRadar
{
public:
    float short_range = 5000.0f;
    float long_range = 30000.0f;
};

class ShareShortRangeRadar
{
};

class RadarLink
{
public:
    sp::ecs::Entity linked_entity;

    sp::script::Callback on_link;
    sp::script::Callback on_unlink;
};

class AllowRadarLink
{
public:
    sp::ecs::Entity owner;
};
