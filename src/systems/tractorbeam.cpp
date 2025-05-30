#include "tractorbeam.h"
#include "multiplayer_server.h"
#include "components/scanning.h"
#include "components/tractorbeam.h"
#include "components/collision.h"
#include "components/docking.h"
#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/target.h"
#include "components/shields.h"
#include "components/faction.h"
#include "components/coolant.h"
#include "components/sfx.h"
#include "systems/beamweapon.h"
#include "systems/collision.h"
#include "ecs/query.h"
#include "main.h"
#include "textureManager.h"
#include "glObjects.h"
#include "shaderRegistry.h"
#include "tween.h"
#include "random.h"
#include "playerInfo.h"

void TractorBeamSystem::update(float delta)
{
    LOG(WARNING) << "In TractorBeamSystem update start";
    if (!game_server) return;
    LOG(WARNING) << "-     if (!game_server) return;";
    if (delta <= 0.0f) return;
    LOG(WARNING) << "-     if (delta <= 0.0f) return;";

    for(auto [entity, tractorsys, transform, reactor, docking_port] : sp::ecs::Query<TractorBeamSys, sp::Transform, sp::ecs::optional<Reactor>, sp::ecs::optional<DockingPort>>()) {
        LOG(WARNING) << "In TractorBeamSystem entity for loop";
        if (!tractorsys.active) continue;
        LOG(WARNING) << "- passed tractor beam active check";
        if (tractorsys.range <= 0.0f) continue;
        LOG(WARNING) << "- passed tractor beam range check";
        if (tractorsys.arc <= 0.0f) continue;
        LOG(WARNING) << "- passed tractor beam arc check";
        /*
        if (docking_port || docking_port->state != DockingPort::State::NotDocking) continue;
        LOG(WARNING) << "- passed docking check";
        auto warp = entity.getComponent<WarpDrive>();
        if (warp || warp->current != 0.0f) continue;
        LOG(WARNING) << "- passed warp check";
        */
    
        auto position = transform.getPosition();
        auto rotation = transform.getRotation();
        float drag_capability = delta * tractorsys.strength * 1000.0f;

        for(auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(tractorsys.range, tractorsys.range), position + glm::vec2(tractorsys.range, tractorsys.range)))
        {
            LOG(WARNING) << "In TractorBeamSystem entity_in_range for loop";
            auto target_transform = entity_in_range.getComponent<sp::Transform>();

            // Get the angle to the target.
            auto diff = target_transform->getPosition() - (position + rotateVec2(glm::vec2(tractorsys.position.x, tractorsys.position.y), rotation));
            float distance = glm::length(diff);
            if (auto physics = entity_in_range.getComponent<sp::Physics>())
                distance += physics->getSize().x;
            float angle = vec2ToAngle(diff);
            float angle_diff = angleDifference(tractorsys.bearing + rotation, angle);
            LOG(WARNING) << "float distance: " << distance << "float angle: " << angle << "float angle_diff: " << angle_diff;

            LOG(WARNING) << "In TractorBeamSystem update firing check if statement";
            // If the target is in the beam's arc and range, the beam has cooled
            // down, and the beam can consume enough energy to fire ...
            if (fabsf(angle_diff) < tractorsys.arc / 2.0f && (!reactor || reactor->useEnergy(tractorsys.energy_per_tick)))
            {
                LOG(WARNING) << "In TractorBeamSystem update firing if statement";
                // ... add heat to the beam and zap the target.
                if (entity.hasComponent<Coolant>())
                    tractorsys.addHeat(tractorsys.heat_per_tick);

                glm::vec2 destination;
                auto target_position = target_transform->getPosition();

                switch (tractorsys.mode) {
                    case TractorMode::Pull: 
                        destination = position;
                        break;
                    case TractorMode::Push:
                        destination = position + glm::normalize(target_position - position) * (tractorsys.range * 2);
                        break;
                    case TractorMode::Hold:
                        destination = position + glm::normalize(target_position - position) * (tractorsys.range / 2);
                        break;
                    default:
                        break;
                }

                auto drag_diff = target_position - destination;
                float drag_distance = std::min(distance, drag_capability);
                /*
                if (target_distance < dragCapability && target_ship && mode == TBM_Pull)
                {
                    // if tractor beam is dragging a ship into parent, force docking
                    target_ship->requestDock(parent);
                }
                */
                target_transform->setPosition(target_position - (drag_distance * glm::normalize(drag_diff)));
                
                //When we fire a beam, and we hit an enemy, check if we are not scanned yet, if we are not, and we hit something that we know is an enemy or friendly,
                //  we now know if this ship is an enemy or friend.
                // Faction::didAnOffensiveAction(entity);
                
                tractorsys.cooldown = tractorsys.cycle_time; // Reset time of weapon
            }
            /*
            auto hit_location = target_transform->getPosition();
            auto r = 100.0f;
            if (auto physics = target.entity.getComponent<sp::Physics>()) {
                hit_location -= glm::normalize(target_transform->getPosition() - transform.getPosition()) * physics->getSize().x;
                r = physics->getSize().x;
            }
            auto e = sp::ecs::Entity::create();
            e.addComponent<sp::Transform>(transform);
            auto& be = e.addComponent<TractorBeamEffect>();
            be.source = entity;
            be.target = target.entity;
            be.source_offset = tractorsys.position;
            be.target_location = hit_location;
            be.beam_texture = tractorsys.texture;
            auto& sfx = e.addComponent<Sfx>();
            sfx.sound = "sfx/laser_fire.wav";
            {
                auto local_hit_location = hit_location - target_transform->getPosition();
                be.target_offset = glm::vec3(local_hit_location.x + random(-r/2.0f, r/2.0f), local_hit_location.y + random(-r/2.0f, r/2.0f), random(-r/4.0f, r/4.0f));
                auto shield = target.entity.getComponent<Shields>();
                if (shield && shield->active)
                be.target_offset = glm::normalize(be.target_offset) * r;
                else
                be.target_offset = glm::normalize(be.target_offset) * random(0, r / 2.0f);
                be.hit_normal = glm::normalize(be.target_offset);
            }
            
            DamageInfo info(entity, mount.damage_type, hit_location);
            DamageSystem::applyDamage(target.entity, mount.damage, info);
            */
        }
    }

    /*
    for(auto [entity, be, transform] : sp::ecs::Query<TractorBeamEffect, sp::Transform>()) {
        if (be.source) {
            if (auto st = be.source.getComponent<sp::Transform>())
                transform.setPosition(st->getPosition() + rotateVec2(glm::vec2(be.source_offset.x, be.source_offset.y), st->getRotation()));
        }
        if (be.target) {
            if (auto tt = be.target.getComponent<sp::Transform>())
                be.target_location = tt->getPosition() + glm::vec2(be.target_offset.x, be.target_offset.y);
        }

        be.lifetime -= delta * be.fade_speed;
        if (be.lifetime < 0 && game_server)
            entity.destroy();
    }
    */
}

void TractorBeamSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, TractorBeamEffect& be)
{
    LOG(WARNING) << "In TractorBeamSystem start/end of render3D";
}

void TractorBeamSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, TractorBeamSys& tractor_system)
{
    if (entity != my_spaceship) {
        auto scanstate = entity.getComponent<ScanState>();
        if (scanstate && my_spaceship && scanstate->getStateFor(my_spaceship) != ScanState::State::FullScan)
            return;
    }

    // Draw beam arcs only if the beam has a range. A beam with range 0
    // effectively doesn't exist; exit if that's the case.
    if (tractor_system.range == 0.0f) return;

    // If the beam is cooling down, flash and fade the arc color.
    glm::u8vec4 color = Tween<glm::u8vec4>::linear(std::max(0.0f, tractor_system.cooldown), 0, tractor_system.cycle_time, tractor_system.arc_color, tractor_system.arc_color_fire);
    
    // Initialize variables from the beam's data.
    float beam_direction = tractor_system.bearing;
    float beam_arc = tractor_system.arc;
    float beam_range = tractor_system.range;

    // Set the beam's origin on radar to its relative position on the mesh.
    auto beam_offset = rotateVec2(glm::vec2(tractor_system.position.x, tractor_system.position.y) * scale, rotation);
    auto arc_center = beam_offset + screen_position;

    drawArc(renderer, arc_center, rotation + (beam_direction - beam_arc / 2.0f), beam_arc, beam_range * scale, color);
}