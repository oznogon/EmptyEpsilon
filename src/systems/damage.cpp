#include "systems/damage.h"
#include "gameGlobalInfo.h"
#include <glm/geometric.hpp>
#include "random.h"
#include "prometheusMetrics.h"
#include "ecs/query.h"

#include "components/collision.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/beamweapon.h"
#include "components/radar.h"
#include "components/rendering.h"
#include "components/name.h"

#include "systems/collision.h"

#include "menus/luaConsole.h"

void DamageSystem::update(float delta)
{
    for(auto [entity, hull] : sp::ecs::Query<Hull>()) {
        if (hull.damage_indicator > 0.0f)
            hull.damage_indicator -= delta;
    }
}

void DamageSystem::damageArea(glm::vec2 position, float blast_range, float min_damage, float max_damage, const DamageInfo& info, float min_range)
{
    for(auto entity : sp::CollisionSystem::queryArea(position - glm::vec2(blast_range, blast_range), position + glm::vec2(blast_range, blast_range)))
    {
        auto transform = entity.getComponent<sp::Transform>();
        if (!transform) continue;

        auto physics = entity.getComponent<sp::Physics>();
        if (!physics) continue;

        float dist = glm::length(position - transform->getPosition()) - physics->getSize().x - min_range;
        if (dist < 0) dist = 0;
        if (dist < blast_range - min_range)
            applyDamage(entity, max_damage - (max_damage - min_damage) * dist / (blast_range - min_range), info);
    }
}

void DamageSystem::applyDamage(sp::ecs::Entity entity, float amount, const DamageInfo& info)
{
    auto shields = entity.getComponent<Shields>();
    if (shields
        && shields->active
        && !shields->entries.empty()
    ) {
        float angle = 0.0f;

        // If the entity has a Transform, determine the angle of the incoming
        // damage.
        if (auto transform = entity.getComponent<sp::Transform>())
        {
            angle = angleDifference(transform->getRotation(), vec2ToAngle(info.location - transform->getPosition()));
            if (angle < 0) angle += 360.0f;
        }

        // Determine the shield segment that takes damage.
        float arc = 360.0f / static_cast<float>(shields->entries.size());
        int shield_index = static_cast<int>((angle + arc * 0.5f) / arc);
        shield_index %= shields->entries.size();
        auto& shield = shields->entries[shield_index];

        // Apply shield damage reduction curve. Beam-to-shield frequency
        // alignment affects the damage factor, and overpowering the shield
        // systems exponentially (but slightly) reduces damage to shields.
        float frequency_damage_factor = 1.0f;
        if (info.type == DamageType::Energy && gameGlobalInfo->use_beam_shield_frequencies)
            frequency_damage_factor = frequencyVsFrequencyDamageFactor(info.frequency, shields->frequency);

        float shield_damage_factor = shields->getDamageFactor(shield_index);
        float shield_damage = amount * shield_damage_factor * frequency_damage_factor;
        amount -= shield.level;
        shield.level -= shield_damage;

        // Either clamp shield level or trigger the visual shield hit effect
        // (and execute the callback on shield damage, if defined).
        if (shield.level < 0.0f) shield.level = 0.0f;
        else
        {
            shield.hit_effect = 1.0f;
            if (shields->on_taking_damage)
            {
                if (info.instigator)
                    LuaConsole::checkResult(shields->on_taking_damage.call<void>(entity, info.instigator));
                else
                    LuaConsole::checkResult(shields->on_taking_damage.call<void>(entity));
            }
        }

        // Clamp the amount.
        if (amount < 0.0f) amount = 0.0f;
    }

    // If any amount of damage got through the shields, take hull damage.
    if (amount > 0.0f)
    {
        takeHullDamage(entity, amount, info);

        // If an entity has the DestroyedByAreaDamage component, it might not
        // have a hull but should still trigger the destruction effect if the
        // damage type is compatible.
        if (auto dbad = entity.getComponent<DestroyedByAreaDamage>())
        {
            if (dbad->damaged_by_flags & (1 << static_cast<int>(info.type)))
                entity.destroy();
        }
    }
}

void DamageSystem::takeHullDamage(sp::ecs::Entity entity, float amount, const DamageInfo& info)
{
    // If there's no hull, don't bother.
    auto hull = entity.getComponent<Hull>();
    if (!hull) return;

    // If flagged as invulnerable to this damage type, don't bother.
    if (!(hull->damaged_by_flags & (1 << static_cast<int>(info.type)))) return;

    // If taking non-EMP damage, light up the hull damage overlay.
    hull->damage_indicator = 1.5f;

    // If ship system damage is enabled, deal it.
    if (gameGlobalInfo->use_system_damage)
    {
        // Damage the targeted ship system relative to the amount of hull
        // damage dealt. If the target entity has less hull strength, the
        // targeted system takes more damage.
        if (auto sys = ShipSystem::get(entity, info.system_target))
        {
            float system_damage = (amount / hull->max) * 2.0f;

            // Beam weapons penetrate the hull easier, so they do more system damage.
            if (info.type == DamageType::Energy) system_damage *= 3.0f;

            sys->health -= system_damage;
            if (sys->health < -1.0f) sys->health = -1.0f;

            for (int n = 0; n < 2; n++)
            {
                auto random_system = ShipSystem::Type(irandom(0, ShipSystem::COUNT - 1));
                float system_damage = (amount / hull->max) * 1.0f;
                sys = ShipSystem::get(entity, random_system);
                if (sys)
                {
                    sys->health -= system_damage;
                    if (sys->health < -1.0f) sys->health = -1.0f;
                }
            }

            // Pass damage to the hull, but drop the value. If it's targeted
            // energy damage, reduce the value by 98%; targeting a system means
            // explicitly not targeting the hull.
            if (info.type == DamageType::Energy) amount *= 0.02f;
            else amount *= 0.5f;
        }
        // If no system is targeted, damage a random system. Random system
        // damage is higher than targeted system damage.
        else
        {
            float system_damage = (amount / hull->max) * 3.0f;

            // Beam weapons penetrate the hull easier, so they do more system damage.
            if (info.type == DamageType::Energy) system_damage *= 2.5f;

            // Deal the damage to a random system.
            auto random_system = ShipSystem::Type(irandom(0, ShipSystem::COUNT - 1));
            sys = ShipSystem::get(entity, random_system);
            if (sys)
            {
                sys->health -= system_damage;
                if (sys->health < -1.0f) sys->health = -1.0f;
            }
        }
    }

    // Draw damage against the hull from the damage amount.
    // If flagged as indestructible, clamp hull value to a minimum of 1.
    hull->current -= amount;
    if (hull->current <= 0.0f && !hull->allow_destruction) hull->current = 1;

    // If the hull value has dropped to 0 or less, destroy the entity.
    if (hull->current <= 0.0f)
    {
        destroyedByDamage(entity, info);
        return;
    }

    // Otherwise, if a callback's defined for damage, run it.
    if (hull->on_taking_damage)
    {
        if (info.instigator)
            LuaConsole::checkResult(hull->on_taking_damage.call<void>(entity, info.instigator));
        else
            LuaConsole::checkResult(hull->on_taking_damage.call<void>(entity));
    }
}

void DamageSystem::destroyedByDamage(sp::ecs::Entity entity, const DamageInfo& info)
{
    // Generate an ExplosionEffect sized to the destroyed entity.
    if (auto transform = entity.getComponent<sp::Transform>())
    {
        if (auto physics = entity.getComponent<sp::Physics>())
        {
            auto e = sp::ecs::Entity::create();
            auto& ee = e.addComponent<ExplosionEffect>();
            ee.size = std::max(physics->getSize().x, physics->getSize().y) * 1.25f;
            ee.radar = true;
            e.addComponent<sp::Transform>(*transform);
            e.addComponent<RawRadarSignatureInfo>(0.0f, 0.4f, 0.4f);
        }
    }

    // If the damage was caused by another entity, apply rep score and record
    // kill.
    if (info.instigator)
    {
        float points = 0.0f;

        auto hull = entity.getComponent<Hull>();
        if (hull) points += hull->max * 0.1f;

        auto shields = entity.getComponent<Shields>();
        if (shields && !shields->entries.empty())
        {
            for (auto& shield : shields->entries) points += shield.max * 0.1f;
            points /= shields->entries.size();
        }

        if (Faction::getRelation(info.instigator, entity) == FactionRelation::Enemy)
            Faction::getInfo(info.instigator).reputation_points += points;
        else
            Faction::getInfo(info.instigator).reputation_points = std::max(Faction::getInfo(info.instigator).reputation_points - points, 0.0f);

        // Write kill to metrics.
        string instigator_name;
        auto cs = info.instigator.getComponent<CallSign>();
        auto tn = info.instigator.getComponent<TypeName>();

        if (cs && !cs->callsign.empty()) instigator_name = cs->callsign;
        else if (tn && !tn->type_name.empty()) instigator_name = tn->type_name;
        else instigator_name = "entity_" + info.instigator.toString();

        PrometheusMetricsServer::recordKill(instigator_name);
    }

    auto hull = entity.getComponent<Hull>();
    if (hull && hull->on_destruction)
    {
        if (info.instigator)
            LuaConsole::checkResult(hull->on_destruction.call<void>(entity, info.instigator));
        else LuaConsole::checkResult(hull->on_destruction.call<void>(entity));
    }

    // Finally, destroy the entity.
    entity.destroy();
}
