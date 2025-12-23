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

// Critical spring damper
// https://theorangeduck.com/page/spring-roll-call#critical
// A second-order damping system that approaches the target as fast as possible
// without overshooting. Requires tracking both position and velocity.
// Pre-computed constants for a fixed halflife of 0.1 seconds.

constexpr float CRITICAL_SPRING_HALFLIFE = 0.1f;
constexpr float CRITICAL_SPRING_Y = (4.0f * 0.693147180559945309417f) / CRITICAL_SPRING_HALFLIFE / 2.0f;  // ln(2) ≈ 0.693147...

static inline void criticalSpringDamp(float& x, float& v, float x_goal, float delta)
{
    constexpr float y = CRITICAL_SPRING_Y;
    float j0 = x - x_goal;
    float j1 = v + j0 * y;
    float eydt = std::exp(-y * delta);

    x = eydt * (j0 + j1 * delta) + x_goal;
    v = eydt * (v - j1 * y * delta);
}

static inline void criticalSpringDamp(glm::vec2& x, glm::vec2& v, const glm::vec2& x_goal, float delta)
{
    constexpr float y = CRITICAL_SPRING_Y;
    glm::vec2 j0 = x - x_goal;
    glm::vec2 j1 = v + j0 * y;
    float eydt = std::exp(-y * delta);

    x = eydt * (j0 + j1 * delta) + x_goal;
    v = eydt * (v - j1 * y * delta);
}

static inline void criticalSpringDamp(glm::vec3& x, glm::vec3& v, const glm::vec3& x_goal, float delta)
{
    constexpr float y = CRITICAL_SPRING_Y;
    glm::vec3 j0 = x - x_goal;
    glm::vec3 j1 = v + j0 * y;
    float eydt = std::exp(-y * delta);

    x = eydt * (j0 + j1 * delta) + x_goal;
    v = eydt * (v - j1 * y * delta);
}

static inline void criticalSpringAngleDamp(float& x, float& v, float x_goal, float delta)
{
    // Normalize angle difference to [-180, 180]
    float angle_delta = std::fmod((x_goal - x), 360.0f);
    if (angle_delta > 180.0f) angle_delta -= 360.0f;
    else if (angle_delta < -180.0f) angle_delta += 360.0f;

    // Apply damping using normalized target
    float normalized_goal = x + angle_delta;
    constexpr float y = CRITICAL_SPRING_Y;
    float j0 = x - normalized_goal;
    float j1 = v + j0 * y;
    float eydt = std::exp(-y * delta);

    x = eydt * (j0 + j1 * delta) + normalized_goal;
    v = eydt * (v - j1 * y * delta);
}
