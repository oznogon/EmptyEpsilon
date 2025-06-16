#include "tractorbeam.h"
#include "multiplayer_server.h"
#include "components/scanning.h"
#include "components/tractorbeam.h"
#include "components/collision.h"
#include "components/docking.h"
#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/target.h"
#include "components/hull.h"
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

    for(auto [entity, tractorsys, transform, reactor, docking_port, warp] : sp::ecs::Query<TractorBeamSys, sp::Transform, sp::ecs::optional<Reactor>, sp::ecs::optional<DockingPort>, sp::ecs::optional<WarpDrive>>()) {
        if (tractorsys.active) {
            // The tractor is active. Reset its cooldown period.
            tractorsys.cooldown = tractorsys.cycle_time;

            // If the tractor's range or arc are 0, or if we're docked, don't
            // tractor anything.
            if (tractorsys.range <= 0.0f) continue;
            if (tractorsys.arc <= 0.0f) continue;
            if (docking_port && docking_port->state != DockingPort::State::NotDocking) continue;
            if (warp && warp->current != 0.0f) continue;

            auto position = transform.getPosition();
            auto rotation = transform.getRotation();
            float drag_capability = tractorsys.strength * tractorsys.getSystemEffectiveness();
            float heat_generated = 0.0f;

            // Get a list of all collisonable entities possibly within range to
            // reduce to those we'll tractor.
            for (auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(tractorsys.range, tractorsys.range), position + glm::vec2(tractorsys.range, tractorsys.range)))
            {
                // Don't match ourselves or we'll tractor ourselves to NaN.
                if (entity_in_range == entity) continue;

                auto target_physics = entity_in_range.getComponent<sp::Physics>();
                auto target_size = 1.0f;

                if (target_physics)
                {
                    // Don't bother tractoring entities with static physics.
                    if (target_physics->getType() == sp::Physics::Type::Static) continue;

                    // In lieu of mass, get the entity's physics engine size.
                    // If the entity is larger than the tractor's drag capability,
                    // skip it.
                    target_size = target_physics->getSize().x;
                    if (target_size > drag_capability) continue;
                }

                // Get the angle to the target, if it has a transform.
                // If not, skip it.
                if (auto target_transform = entity_in_range.getComponent<sp::Transform>())
                {
                    auto target_position = target_transform->getPosition();
                    auto diff = target_position - (position + rotateVec2(glm::vec2(tractorsys.position.x, tractorsys.position.y), rotation));
                    float angle = vec2ToAngle(diff);
                    float angle_diff = angleDifference(tractorsys.bearing + rotation, angle);

                    // If the entity is in the beam's arc and range, and if the
                    // beam has cooled down, calculate the distance between us and
                    // the entity. If we have a reactor, also consume additional
                    // energy per matching entity.
                    if (fabsf(angle_diff) < tractorsys.arc / 2.0f && (!reactor || reactor->useEnergy(delta * tractorsys.energy_use_per_second)))
                    {
                        float distance = glm::length(diff);
                        float target_force, target_velocity, target_mass = 1.0f;

                        // In lieu of mass, get the entity's size and velocity.
                        target_velocity = glm::length(target_physics->getVelocity());
                        target_mass = target_size;

                        // If we or the entity have a physics body, factor its size
                        // into the distance between us.
                        if (target_physics)
                            distance -= target_size;

                        if (auto my_physics = entity.getComponent<sp::Physics>())
                            distance -= my_physics->getSize().x;

                        // Narrow the group to entities that are also within
                        // tractor range. These are the only entities that we'll
                        // potentially tractor.
                        if (distance <= tractorsys.range)
                        {
                            // Shielded entities are harder to tractor.
                            auto shields = entity_in_range.getComponent<Shields>();
                            float shield_angle = 0.0f;

                            if (shields && shields->active && !shields->entries.empty())
                            {
                                auto hit_location = target_position;

                                if (target_physics)
                                    hit_location -= glm::normalize(target_position - position) * target_physics->getSize().x;

                                shield_angle = angleDifference(target_transform->getRotation(), vec2ToAngle(hit_location - target_position));
                                while (shield_angle < 0.0f) shield_angle += 360.0f;

                                float shield_arc = 360.0f / float(shields->entries.size());
                                int shield_index = int((shield_angle + shield_arc / 2.0f) / shield_arc);
                                shield_index %= shields->entries.size();
                                auto& shield = shields->entries[shield_index];
                                target_mass += shield.level;
                            }

                            // Hulled entities are harder to tractor.
                            // Hulls get a multiplier because they represent
                            // dense mass.
                            auto hull = entity_in_range.getComponent<Hull>();

                            if (hull && hull->current > 0.0f)
                                target_mass += hull->current * 5.0f;

                            // If we're an entity that uses coolant, generate heat per
                            // tractored entity.
                            if (entity.hasComponent<Coolant>()) heat_generated += tractorsys.heat_per_second;

                            // Determine the destination point for the tractored entity
                            // based on the tractor mode.
                            glm::vec2 destination = position;
                            auto tractor_heading = tractorsys.bearing + rotation;
                            while (tractor_heading > 360.0f) tractor_heading -= 360.0f;
                            while (tractor_heading < 0.0f) tractor_heading += 360.0f;
                            auto tractor_vector = vec2FromAngle(tractor_heading);
                            auto destination_coordinates = position + tractor_vector * (tractorsys.range * 0.5f);

                            switch (tractorsys.mode)
                            {
                                // Pull mode tractors entities toward us.
                                case TractorMode::Pull:
                                {
                                    destination = position;
                                    break;
                                }
                                // Push mode tractors entities away from us.
                                case TractorMode::Push:
                                {
                                    destination = position + glm::normalize(target_position - position) * tractorsys.range * 1.2f;
                                    break;
                                }
                                // Hold mode tractors entities to a point
                                // halfway between us and the tractor's range,
                                // without changing its relative angle to us.
                                case TractorMode::Hold:
                                {
                                    destination = position + glm::normalize(target_position - position) * (tractorsys.range * 0.5f);
                                    break;
                                }
                                // Reposition mode tractors all entities in the
                                // arc to its center point.
                                case TractorMode::Reposition:
                                {
                                    destination = destination_coordinates;
                                    break;
                                }
                                default:
                                    break;
                            }

                            // Define the vector and distance of tractor influence.
                            auto drag_diff = target_position - destination;
                            // Determine effective drag capability by factoring
                            // in target's shields, hull, and velocity.
                            target_force = target_mass * target_velocity;
                            float effective_drag_capability = drag_capability - target_force == 0.0f ? 0.0f : (drag_capability - target_force) / drag_capability;
                            if (effective_drag_capability <= 0.0f) continue;
                            float drag_distance = std::min(distance, (effective_drag_capability * effective_drag_capability * effective_drag_capability) * drag_capability);

                            LOG(INFO) << "drag_capability: " << drag_capability
                                << ", target_force: " << target_force
                                << ", effective_drag_capability: " << effective_drag_capability
                                << ", distance: " << distance
                                << ", drag_distance: " << drag_distance
                                << ", drag_distance * delta: " << drag_distance * delta;

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
                                target_transform->setPosition(target_position - ((drag_distance * delta) * glm::normalize(drag_diff)));
                            }
                        }
                    }
                }
            }

            tractorsys.addHeat(delta * heat_generated);
            /* TODO: Beam 3D drawing and sound effects.

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
            */
        }
        else
        {
            // The tractor is off. Tick its cooldown toward 0.
            if (tractorsys.cooldown > 0.0f) tractorsys.cooldown -= delta;
        }
        /* TODO: Beam 3D drawing effects.
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
    /* TODO: Beam 3D drawing effects. */
}

void TractorBeamSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, TractorBeamSys& tractor_system)
{
    // Render other ships' tractor beams only if they're fully scanned.
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
