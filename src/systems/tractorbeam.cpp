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
#include "systems/docking.h"
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
    if (!game_server) return;
    if (delta <= 0.0f) return;

    for(auto [entity, tractorsys, transform, reactor, docking_port] : sp::ecs::Query<TractorBeamSys, sp::Transform, sp::ecs::optional<Reactor>, sp::ecs::optional<DockingPort>>()) {
        if (tractorsys.active) {
            // The tractor is active. Reset its cooldown period.
            tractorsys.cooldown = tractorsys.cycle_time;
            LOG(WARNING) << "Tractor is on. tractorsys.cooldown: " << tractorsys.cooldown << " tractorsys.cycle_time: " << tractorsys.cycle_time;

            // If the tractor's range or arc are 0, or if we're docked, don't
            // tractor anything.
            LOG(WARNING) << "- passed tractor beam active check";
            if (tractorsys.range <= 0.0f) continue;
            LOG(WARNING) << "- passed tractor beam range check";
            if (tractorsys.arc <= 0.0f) continue;
            LOG(WARNING) << "- passed tractor beam arc check";
            if (docking_port && docking_port->state != DockingPort::State::NotDocking) continue;
            LOG(WARNING) << "- passed docking check";
            /*
            auto warp = entity.getComponent<WarpDrive>();
            if (warp || warp->current != 0.0f) continue;
            LOG(WARNING) << "- passed warp check";
            */
            auto position = transform.getPosition();
            auto rotation = transform.getRotation();
            float drag_capability = (delta * tractorsys.strength * 100.0f) * tractorsys.getSystemEffectiveness();
            float heat_generated = 0.0f;

            // Get a list of all collisonable entities possibly within range to
            // reduce to those we'll tractor.
            for(auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(tractorsys.range, tractorsys.range), position + glm::vec2(tractorsys.range, tractorsys.range)))
            {
                // Don't match ourselves or we'll tractor ourselves to NaN.
                if (entity_in_range == entity) continue;

                auto target_size = 1.0f;
                auto target_physics = entity_in_range.getComponent<sp::Physics>();

                if (target_physics)
                {
                    // Don't bother tractoring entities with static physics.
                    if (target_physics->getType() == sp::Physics::Type::Static) continue;

                    // Get the size of the target entity.
                    target_size = target_physics->getSize().x;
                }

                // If the target is too big to move, skip it.
                LOG(WARNING) << "target_size * delta > drag_capability: " << (target_size * delta > drag_capability) << " target_size * delta: " << target_size * delta << " drag_capability: " << drag_capability;
                if (target_size * delta > drag_capability) continue;

                // Get the angle to the target, if it has a transform.
                // If not, skip it.
                if (auto target_transform = entity_in_range.getComponent<sp::Transform>())
                {
                    auto diff = target_transform->getPosition() - (position + rotateVec2(glm::vec2(tractorsys.position.x, tractorsys.position.y), rotation));
                    float angle = vec2ToAngle(diff);
                    float angle_diff = angleDifference(tractorsys.bearing + rotation, angle);

                    LOG(WARNING) << "fabsf(angle_diff) < tractorsys.arc: " << (fabsf(angle_diff) < tractorsys.arc) << " tractorsys.cooldown: " << tractorsys.cooldown;
                    // If the entity is in the beam's arc and range, and if the
                    // beam has cooled down, calculate the distance between us and
                    // the entity. If we have a reactor, also consume additional
                    // energy per matching entity.
                    if (fabsf(angle_diff) < tractorsys.arc / 2.0f && (!reactor || reactor->useEnergy(delta * tractorsys.energy_use_per_second)))
                    {
                        float distance = glm::length(diff);

                        // If we or the entity have a physics body, factor its size
                        // into the distance between us.
                        if (target_physics)
                        {
                            auto target_size = target_physics->getSize().x;
                            distance -= target_size;
                        }
                        if (auto my_physics = entity.getComponent<sp::Physics>())
                        {
                            distance -= my_physics->getSize().x;
                        }

                        // Narrow the group to entities that are also within
                        // tractor range. These are the only entities that we'll
                        // tractor.
                        if (distance <= tractorsys.range)
                        {
                            LOG(WARNING) << "float distance: " << distance << " float angle: " << angle << " float angle_diff: " << angle_diff;
                            
                            // If we're an entity that uses coolant, generate heat per
                            // tractored entity.
                            if (entity.hasComponent<Coolant>()) heat_generated += tractorsys.heat_per_second;

                            // Determine the destination point for the tractored entity
                            // based on the tractor mode.
                            glm::vec2 destination;
                            auto target_position = target_transform->getPosition();
                            switch (tractorsys.mode)
                            {
                                // Pull mode tractors entities toward us.
                                case TractorMode::Pull:
                                    destination = position;
                                    break;
                                // Push mode tractors entities away from us.
                                case TractorMode::Push:
                                    destination = position + glm::normalize(target_position - position) * tractorsys.range * 2.0f;
                                    break;
                                // Hold mode tractors entities to a point halfway
                                // between us and the tractor's range limit.
                                case TractorMode::Hold:
                                    destination = position + glm::normalize(target_position - position) * (tractorsys.range / 2.0f);
                                    break;
                                default:
                                    break;
                            }

                            // Define the vector and distance of tractor influence.
                            auto drag_diff = target_position - destination;
                            float drag_distance = std::min(distance, drag_capability);

                            if (distance <= 1.1f * drag_distance &&
                                entity.hasComponent<DockingBay>() &&
                                entity_in_range.hasComponent<DockingPort>() &&
                                tractorsys.mode == TractorMode::Pull)
                            {
                                // If we've tractored a dockable entity into
                                // contact with us, force it to dock with us.
                                DockingSystem::requestDock(entity_in_range, entity);
                            }
                            else
                            {
                                // Move the tractored object to the destination.
                                target_transform->setPosition(target_position - (drag_distance * glm::normalize(drag_diff)));
                            }
                        }
                    }
                }
            }

            tractorsys.addHeat(delta * heat_generated);
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
        else
        {
            // The tractor is off. Tick its cooldown toward 0.
            if (tractorsys.cooldown > 0.0f) tractorsys.cooldown -= delta;
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

    // Set the beam's origin on radar to its relative position on the mesh.
    auto beam_offset = rotateVec2(glm::vec2(tractor_system.position.x, tractor_system.position.y) * scale, rotation);
    auto arc_center = beam_offset + screen_position;

    drawArc(renderer, arc_center, rotation + (tractor_system.bearing - tractor_system.arc / 2.0f), tractor_system.arc, tractor_system.range * scale, color);
}