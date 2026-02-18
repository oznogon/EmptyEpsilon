#pragma once

#include <glm/vec2.hpp>
#include <glm/vec3.hpp>
#include <glm/common.hpp>
#include <glm/exponential.hpp>
#include <glm/gtx/compatibility.hpp>
#include <cmath>

// Frame-rate independent damping using linear interpolation
// https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/

// Power-based, where speed is between 0 and 1
static inline float powerDamp(const float& source, const float& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::pow(speed, delta));
}

static inline glm::vec2 powerDamp(const glm::vec2& source, const glm::vec2& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::pow(speed, delta));
}

static inline glm::vec3 powerDamp(const glm::vec3& source, const glm::vec3& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::pow(speed, delta));
}

static inline float powerAngleDamp(const float& source, const float& target, float speed, float time_delta)
{
    float angle_delta = std::fmod((target - source), 360.0f);
    if (angle_delta > 180.0f) angle_delta -= 360.0f;
    else if (angle_delta < -180.0f) angle_delta += 360.0f;
    return glm::lerp(source, source + angle_delta, 1.0f - std::pow(speed, time_delta));
}

// Exponential decay-based, where speed influences convergence rate
static inline float exponentialDamp(const float& source, const float& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::exp(-speed * delta));
}

static inline glm::vec2 exponentialDamp(const glm::vec2& source, const glm::vec2& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::exp(-speed * delta));
}

static inline glm::vec3 exponentialDamp(const glm::vec3& source, const glm::vec3& target, float speed, float delta)
{
    return glm::lerp(source, target, 1.0f - std::exp(-speed * delta));
}

static inline float exponentialAngleDamp(const float& source, const float& target, float speed, float time_delta)
{
    float angle_delta = std::fmod((target - source), 360.0f);
    if (angle_delta > 180.0f) angle_delta -= 360.0f;
    else if (angle_delta < -180.0f) angle_delta += 360.0f;
    return glm::lerp(source, source + angle_delta, 1.0f - std::exp(-speed * time_delta));
}
