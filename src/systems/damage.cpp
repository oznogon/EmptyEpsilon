#include "systems/damage.h"
#include "systems/collision.h"
#include "ecs/query.h"
#include "components/collision.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/beamweapon.h"
#include "components/missile.h"
#include "components/radar.h"
#include "components/rendering.h"
#include "components/sfx.h"
#include "gameGlobalInfo.h"
#include <glm/geometric.hpp>
#include "random.h"
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
        {
            applyDamage(entity, max_damage - (max_damage - min_damage) * dist / (blast_range - min_range), info);
        }
    }
}

void DamageSystem::applyDamage(sp::ecs::Entity entity, float amount, const DamageInfo& info)
{
    // Damage shields first if they're active
    auto shields = entity.getComponent<Shields>();
    if (shields && shields->active && !shields->entries.empty())
    {
        auto transform = entity.getComponent<sp::Transform>();
        float angle = 0;

        if (transform)
        {
            angle = angleDifference(transform->getRotation(), vec2ToAngle(info.location - transform->getPosition()));
            if (angle < 0) angle += 360.0f;
        }

        float arc = 360.0f / float(shields->entries.size());
        int shield_index = int((angle + arc / 2.0f) / arc);
        shield_index %= shields->entries.size();
        auto& shield = shields->entries[shield_index];

        float frequency_damage_factor = 1.f;
        if (info.type == DamageType::Energy && gameGlobalInfo->use_beam_shield_frequencies)
        {
            frequency_damage_factor = frequencyVsFrequencyDamageFactor(info.frequency, shields->frequency);
        }

        //Shield damage reduction curve. Damage reduction gets slightly exponetial effective with power.
        // This also greatly reduces the ineffectiveness at low power situations.
        float shield_damage_factor = shields->getDamageFactor(shield_index);

        float shield_damage = amount * shield_damage_factor * frequency_damage_factor;
        amount -= shield.level;
        shield.level -= shield_damage;
        if (shield.level < 0)
        {
            shield.level = 0.0f;
        }
        else
        {
            shield.hit_effect = 1.0f;
        }

        if (amount < 0.0f)
        {
            amount = 0.0f;
        }
    }

    // Damage hull after shields
    if (amount > 0.0f)
    {
        takeHullDamage(entity, amount, info);
        if (auto dbad = entity.getComponent<DestroyedByAreaDamage>()) {
            if (dbad->damaged_by_flags & (1 << int(info.type))) {
                entity.destroy();
            }
        }
    }
}

void DamageSystem::takeHullDamage(sp::ecs::Entity entity, float amount, const DamageInfo& info)
{
    auto hull = entity.getComponent<Hull>();
    auto eot = entity.getComponent<ExplodeOnTouch>();

    if (!hull && !eot) return;

    if (hull)
    {
        if (!(hull->damaged_by_flags & (1 << int(info.type)))) return;

        // If taking non-EMP damage, light up the hull damage overlay.
        hull->damage_indicator = 1.5f;

        if (gameGlobalInfo->use_system_damage)
        {
            // Target a specific system if one is designated.
            if (auto sys = ShipSystem::get(entity, info.system_target))
            {
                float system_damage = (amount / hull->max) * 2.0f;
                // Beam weapons do more system damage, as they penetrate the hull easier.
                if (info.type == DamageType::Energy) system_damage *= 3.0f;
                sys->health -= system_damage;
                if (sys->health < -1.0f) sys->health = -1.0f;

                // Also damage up to two random systems.
                for (int n=0; n<2; n++)
                {
                    auto random_system = ShipSystem::Type(irandom(0, ShipSystem::COUNT - 1));
                    // Damage the system compared to the amount of hull damage that would be dealt.
                    // If the entity has less hull strength, it takes more system damage.
                    float system_damage = (amount / hull->max) * 1.0f;
                    sys = ShipSystem::get(entity, random_system);

                    if (sys)
                    {
                        sys->health -= system_damage;
                        if (sys->health < -1.0f) sys->health = -1.0f;
                    }
                }
                // After system damage, energy damage deals less to the rest of the ship.
                if (info.type == DamageType::Energy) amount *= 0.02f;
                else amount *= 0.5f;
            }
            // Otherwise, deal damage to a random system.
            // Note that the damage factors are different in this case.
            else
            {
                // Damage the system compared to the amount of hull damage that would be dealt.
                // If the entity has less hull strength, it takes more system damage.
                float system_damage = (amount / hull->max) * 3.0f;
                // Beam weapons do more system damage, as they penetrate the hull easier.
                if (info.type == DamageType::Energy) system_damage *= 2.5f;

                auto random_system = ShipSystem::Type(irandom(0, ShipSystem::COUNT - 1));
                sys = ShipSystem::get(entity, random_system);

                if (sys)
                {
                    sys->health -= system_damage;
                    if (sys->health < -1.0f) sys->health = -1.0f;
                }
            }
        }

        // Deal hull damage and fire on_taking_damage callbacks.
        hull->current -= amount;
        if (hull->current <= 0.0f && !hull->allow_destruction)
            hull->current = 1;

        if (hull->current <= 0.0f)
        {
            destroyedByDamage(entity, info);
            return;
        }

        if (hull->on_taking_damage)
        {
            if (info.instigator)
                LuaConsole::checkResult(hull->on_taking_damage.call<void>(entity, info.instigator));
            else
                LuaConsole::checkResult(hull->on_taking_damage.call<void>(entity));
        }
    }
    // If the entity lacks a hull but has ExplodeOnTouch, explode it.
    else if (eot)
        destroyedByDamage(entity, info);
}

void DamageSystem::destroyedByDamage(sp::ecs::Entity entity, const DamageInfo& info)
{
    // If the entity has a Transform and either a Physics or ExplodeOnTouch
    // component, place the explosion effect at its location and emit a radar
    // signature.
    auto transform = entity.getComponent<sp::Transform>();
    auto eot = entity.getComponent<ExplodeOnTouch>();
    auto deot = entity.getComponent<DelayedExplodeOnTouch>();

    if (transform)
    {
        auto physics = entity.getComponent<sp::Physics>();

        if (physics || eot)
        {
            auto e = sp::ecs::Entity::create();
            e.addComponent<sp::Transform>(*transform);
            e.addComponent<RawRadarSignatureInfo>(0.0f, 0.4f, 0.4f);

            auto& ee = e.addComponent<ExplosionEffect>();
            ee.radar = true;

            // Scale the explosion effect to the entity's Physics size or its
            // ExplodeOnTouch size.
            if (physics) ee.size = physics->getSize().x * 1.5f;
            if (eot)
            {
                ee.size = eot->blast_range;
                // If the entity has ExplodeOnTouch, also use its explosion
                // sound effect.
                // Use the electrical explosion effect if it deals EMP damage.
                if (eot->damage_type == DamageType::EMP)
                {
                    e.addComponent<Sfx>().sound = "sfx/emp_explosion.wav";
                    ee.electrical = true;
                }

                // Use the ExplodeOnTouch sound effect if present.
                if (!eot->explosion_sfx.empty())
                {
                    //soundManager->playSound(explosion_sound, getPosition(), size * 2, 0.6);
                    e.addComponent<Sfx>().sound = eot->explosion_sfx;
                }
            }
        }
    }

    // If the damage that caused the entity's destruction is caused by a faction
    // member to that faction's enemy, calculate and reward a number of
    // reputation points based on the target's hull and shield values.
    auto hull = entity.getComponent<Hull>();
    auto shields = entity.getComponent<Shields>();
    if (info.instigator && (hull || shields))
    {
        float points = 0.0f;

        if (hull) points += hull->max * 0.1f;
        if (shields && !shields->entries.empty())
        {
            for (auto& shield : shields->entries)
                points += shield.max * 0.1f;
            points /= shields->entries.size();
        }
        
        if (Faction::getRelation(info.instigator, entity) == FactionRelation::Enemy)
            Faction::getInfo(info.instigator).reputation_points += points;
        else
            Faction::getInfo(info.instigator).reputation_points = std::max(Faction::getInfo(info.instigator).reputation_points - points, 0.0f);
    }

    // Call on_destruction callbacks, passing the instigator if provided.
    if (hull->on_destruction)
    {
        if (info.instigator)
            LuaConsole::checkResult(hull->on_destruction.call<void>(entity, info.instigator));
        else
            LuaConsole::checkResult(hull->on_destruction.call<void>(entity));
    }

    // Finally, destroy the entity.
    // If the entity has ExplodeOnTouch, also deal its area damage after destroying it.
    if (!eot) entity.destroy();
    else if (eot && !deot)
    {
        float blast_range = eot->blast_range;
        float damage_at_edge = eot->damage_at_edge;
        float damage_at_center = eot->damage_at_center;
        glm::vec2 position = transform->getPosition();
        DamageInfo info(eot->owner, eot->damage_type, transform->getPosition());

        entity.destroy();
        DamageSystem::damageArea(position, blast_range, damage_at_edge, damage_at_center, info, blast_range / 2.0f);
    }
    // Mines misbehave.
    else if (deot)
    {
        return;
    }
}
