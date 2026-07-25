#include "threatLevelEstimate.h"
#include "gameGlobalInfo.h"
#include "ecs/query.h"

#include "components/hull.h"
#include "components/collision.h"
#include "components/shields.h"
#include "components/beamweapon.h"
#include "components/missiletubes.h"
#include "components/missile.h"
#include "components/player.h"

#include "systems/collision.h"

float ThreatLevelEstimate::DEBUG_MAX_THREAT = 0.0f;
float ThreatLevelEstimate::DEBUG_SMOOTHED_THREAD = 0.0f;
bool ThreatLevelEstimate::DEBUG_THREAT_HIGH = false;

ThreatLevelEstimate::ThreatLevelEstimate()
{
}

void ThreatLevelEstimate::update(float delta)
{
    if (!gameGlobalInfo) return;

    float max_threat = 0.0f;
    for (auto [entity, pc] : sp::ecs::Query<PlayerControl>())
        max_threat = std::max(max_threat, getThreatFor(entity));
    float f = delta / THREAT_DROP_OFF_TIME;
    smoothed_threat_level = ((1.0f - f) * smoothed_threat_level) + (max_threat * f);

    DEBUG_MAX_THREAT = max_threat;
    DEBUG_SMOOTHED_THREAD = smoothed_threat_level;
    DEBUG_THREAT_HIGH = threat_high;

    if (!threat_high && smoothed_threat_level > THREAT_HIGH_LEVEL)
    {
        threat_high = true;
        if (threat_high_func) threat_high_func();
    }

    if (threat_high && smoothed_threat_level < THREAT_LOW_LEVEL)
    {
        threat_high = false;
        if (threat_low_func) threat_low_func();
    }
}

float ThreatLevelEstimate::getThreatFor(sp::ecs::Entity ship)
{
    if (!ship) return 0.0f;

    float threat = 0.0f;

    if (auto hull = ship.getComponent<Hull>())
        threat += hull->max - hull->current;
    if (auto shields = ship.getComponent<Shields>())
    {
        if (shields->active) threat += 200;
        for (auto& shield : shields->entries)
            threat += shield.max - shield.level;
    }

    float radius = 7000.0f;

    if (auto transform = ship.getComponent<sp::Transform>())
    {
        auto ship_position = transform->getPosition();
        for (auto entity : sp::CollisionSystem::queryArea(ship_position - glm::vec2(radius, radius), ship_position + glm::vec2(radius, radius)))
        {
            auto et = entity.getComponent<sp::Transform>();
            if (et && glm::distance2(glm::vec2(et->getPosition()), ship_position) > radius * radius)
                continue;

            if (!entity.hasComponent<BeamWeaponSys>() || entity.hasComponent<MissileTubes>())
            {
                if (entity.hasComponent<MissileFlight>() && entity.hasComponent<ExplodeOnTouch>())
                    threat += 5000.0f;

                if (entity.hasComponent<BeamEffect>()) threat += 5000.0f;

                continue;
            }

            if (Faction::getRelation(ship, entity) != FactionRelation::Enemy)
                continue;

            bool is_being_attacked = false;
            float score = 200.0f;

            if (auto hull = entity.getComponent<Hull>()) score += hull->max;

            if (auto shields = entity.getComponent<Shields>())
            {
                for (auto& shield : shields->entries)
                {
                    score += shield.max * 2.0f / static_cast<float>(shields->entries.size());
                    if (shield.hit_effect > 0.0f) is_being_attacked = true;
                }
            }

            if (is_being_attacked) score += 500.0f;

            threat += score;
        }
    }

    return threat;
}

void ThreatLevelEstimate::setCallbacks(func_t low, func_t high)
{
    threat_low_func = low;
    threat_high_func = high;

    if (threat_high)
    {
        if (threat_high_func) threat_high_func();
    }
    else
    {
        if (threat_low_func) threat_low_func();
    }
}
