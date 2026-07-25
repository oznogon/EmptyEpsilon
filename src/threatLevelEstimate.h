#pragma once

#include "Updatable.h"
#include <ecs/entity.h>
#include <functional>

class ThreatLevelEstimate : public Updatable
{
private:
    typedef std::function<void()> func_t;

    static constexpr float THREAT_DROP_OFF_TIME = 20.0f;
    static constexpr float THREAT_HIGH_LEVEL = 700.0f;
    static constexpr float THREAT_LOW_LEVEL = 300.0f;

    float smoothed_threat_level = 0.0f;
    bool threat_high = false;

    func_t threat_low_func = nullptr;
    func_t threat_high_func = nullptr;
public:
    ThreatLevelEstimate();
    virtual ~ThreatLevelEstimate() = default;

    float getThreat() { return smoothed_threat_level; }
    void setCallbacks(func_t low, func_t high);

    virtual void update(float delta) override;

    static float DEBUG_MAX_THREAT;
    static float DEBUG_SMOOTHED_THREAD;
    static bool DEBUG_THREAT_HIGH;
private:
    float getThreatFor(sp::ecs::Entity ship);
};
