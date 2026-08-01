#include "utilityBeam.h"

#include "main.h"
#include "textureManager.h"
#include "glObjects.h"
#include "shaderRegistry.h"
#include "tween.h"
#include "random.h"
#include "multiplayer_server.h"
#include "playerInfo.h"
#include "ecs/query.h"

#include "components/scanning.h"
#include "components/utilityBeam.h"
#include "components/mounts.h"
#include "components/collision.h"
#include "components/docking.h"
#include "components/reactor.h"
#include "components/warpdrive.h"
#include "components/target.h"
#include "components/impulse.h"
#include "components/missile.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/faction.h"
#include "components/coolant.h"
#include "components/sfx.h"

#include "systems/beamweapon.h"
#include "systems/docking.h"
#include "systems/collision.h"

#include "menus/luaConsole.h"

#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <graphics/opengl.h>

void UtilityBeamSystem::update(float delta)
{
    if (!game_server.isAlive()) return;
    if (delta <= 0.0f) return;

    for (auto [this_entity, utility_beam, mounts, transform] : sp::ecs::Query<UtilityBeam, Mounts, sp::Transform>())
    {
        // Find the utility beam mount
        Mount* utility_mount = nullptr;
        for (auto& m : mounts.mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                utility_mount = &m;
                break;
            }
        }
        if (!utility_mount) continue;

        // Turreted utility beams rotate their direction toward a target within
        // the turret arc, and return to their default direction when there is
        // no target or the target is outside of the turret arc.
        if (utility_mount->turret_arc > 0.0f && utility_mount->turret_rotation_rate > 0.0f && !utility_mount->turret_locked)
        {
            auto position = transform.getPosition();
            auto rotation = transform.getRotation();
            float rotation_rate = utility_mount->turret_rotation_rate * utility_beam.getSystemEffectiveness();

            sp::ecs::Entity aim_target;
            float aim_angle_diff = 0.0f;
            bool found = false;
            if (utility_mount->active && utility_mount->range > 0.0f)
            {
                for (auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(utility_mount->range, utility_mount->range), position + glm::vec2(utility_mount->range, utility_mount->range)))
                {
                    // Don't match ourselves.
                    if (entity_in_range == this_entity) continue;

                    if (auto target_transform = entity_in_range.getComponent<sp::Transform>())
                    {
                        auto diff = target_transform->getPosition() - position;
                        if (glm::length(diff) > utility_mount->range) continue;
                        float angle = vec2ToAngle(diff);
                        float turret_angle_diff = angleDifference(utility_mount->turret_direction + rotation, angle);
                        if (fabsf(turret_angle_diff) >= utility_mount->turret_arc * 0.5f) continue;

                        // Prefer the target closest to the turret's direction.
                        if (!found || fabsf(turret_angle_diff) < aim_angle_diff)
                        {
                            found = true;
                            aim_angle_diff = fabsf(turret_angle_diff);
                            aim_target = entity_in_range;
                        }
                    }
                }
            }

            if (found)
            {
                if (auto aim_transform = aim_target.getComponent<sp::Transform>())
                {
                    float target_angle = vec2ToAngle(aim_transform->getPosition() - position);
                    utility_mount->direction = utility_mount->rotateMountTurretTowards(utility_mount->direction, rotation, target_angle, utility_mount->turret_direction, utility_mount->turret_arc, rotation_rate);
                }
                else
                {
                    utility_mount->direction = utility_mount->resetMountTurret(utility_mount->direction, utility_mount->turret_direction, rotation_rate);
                }
            }
            else
            {
                utility_mount->direction = utility_mount->resetMountTurret(utility_mount->direction, utility_mount->turret_direction, rotation_rate);
            }
        }

        // Ensure effect_target_entity is valid, recreate if it was deleted
        if (!utility_beam.effect_target_entity)
            utility_beam.effect_target_entity = sp::ecs::Entity::create();

        if (utility_mount->active)
        {
            // TODO: Skip logic if cooldown is active
            // The beam is active. Reset its cooldown period and tick its
            // activity time.
            utility_mount->cooldown = utility_mount->cycle_time;
            utility_mount->is_firing = false;

            // If the beam's range or arc are 0, beam is no-op.
            if (utility_mount->range <= 0.0f) continue;
            if (utility_mount->arc <= 0.0f) continue;

            auto position = transform.getPosition();
            auto rotation = transform.getRotation();

            for (auto beam_mode : utility_mount->custom_beam_modes)
            {
                if (utility_mount->custom_beam_mode == beam_mode.name)
                {
                    if (beam_mode.requires_target)
                    {
                        // Remove transform from effect_target_entity when in targeted mode
                        utility_beam.effect_target_entity.removeComponent<sp::Transform>();

                        // Get a list of all entities with transforms within range.
                        for (auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(utility_mount->range, utility_mount->range), position + glm::vec2(utility_mount->range, utility_mount->range)))
                        {
                            // Don't match ourselves.
                            if (entity_in_range == this_entity) continue;

                            // Get the angle to the target, if it has a transform.
                            // If it doesn't have a transform, skip it.
                            if (auto target_transform = entity_in_range.getComponent<sp::Transform>())
                            {
                                auto diff = target_transform->getPosition() - (position + rotateVec2(glm::vec2(utility_mount->position.x, utility_mount->position.y), rotation));
                                float angle_diff = angleDifference(utility_mount->direction + rotation, vec2ToAngle(diff));

                                // If the entity is in the beam's arc and range, calculate the distance between us and
                                // the entity.
                                if (fabsf(angle_diff) < utility_mount->arc * 0.5f)
                                {
                                    float distance = glm::length(diff);

                                    // If the target entity has a physics body, factor
                                    // its size into the distance between us.
                                    auto target_physics = entity_in_range.getComponent<sp::Physics>();
                                    if (target_physics)
                                        distance -= std::max(target_physics->getSize().x, target_physics->getSize().y);

                                    // If we have a physics body, factor its size into the
                                    // distance between us.
                                    if (auto my_physics = this_entity.getComponent<sp::Physics>())
                                        distance -= std::max(my_physics->getSize().x, my_physics->getSize().y);

                                    // Narrow the group to entities that are also within
                                    // the beam's range. These are the only entities that
                                    // we'll potentially affect.
                                    if (distance <= utility_mount->range)
                                        fire(this_entity, *utility_mount, beam_mode, transform, entity_in_range, distance, angle_diff);
                                    // else LOG(Debug, "[utilitybeam] Beam is active but target is not in the beam's range.");
                                }
                                // else LOG(Debug, "[utilitybeam] Beam is active but target is not in the beam's arc.");
                            }
                        }
                    }
                    else
                    {
                        // A utility beam that doesn't require a target to exist
                        // within the arc instead creates an entity to serve
                        // as its "target" and gives that target a transform.
                        // The script can add other components to that entity
                        // as required. This entity is positioned at the end of
                        // the arc on the beam's direction and moves with the arc.
                        auto& effect_target_transform = utility_beam.effect_target_entity.getOrAddComponent<sp::Transform>();

                        glm::vec2 offset = vec2FromAngle(utility_mount->direction + rotation) * utility_mount->range;
                        effect_target_transform.setPosition(position + offset);
                        auto diff = effect_target_transform.getPosition() - (position + rotateVec2(glm::vec2(utility_mount->position.x, utility_mount->position.y), rotation));
                        float angle_diff = angleDifference(utility_mount->direction + rotation, vec2ToAngle(diff));

                        fire(this_entity, *utility_mount, beam_mode, transform, utility_beam.effect_target_entity, utility_mount->range, angle_diff);
                    }

                    break;
                }
            }
        }
        else
        {
            // The beam is off. Tick its cooldown toward 0 and reset its
            // activity timer if necessary.
            if (utility_beam.was_active)
            {
                auto position = transform.getPosition();

                for (auto& beam_mode : utility_mount->custom_beam_modes)
                {
                    if (utility_mount->custom_beam_mode == beam_mode.name && beam_mode.deactivate_callback)
                    {
                        if (beam_mode.requires_target)
                        {
                            // Remove transform from effect_target_entity when in targeted mode
                            utility_beam.effect_target_entity.removeComponent<sp::Transform>();

                            // Get a list of all entities with transforms within range.
                            for (auto entity_in_range : sp::CollisionSystem::queryArea(position - glm::vec2(utility_mount->range, utility_mount->range), position + glm::vec2(utility_mount->range, utility_mount->range)))
                            {
                                // Don't match ourselves.
                                if (entity_in_range == this_entity) continue;
                                LuaConsole::checkResult(beam_mode.deactivate_callback.call<void>(this_entity, entity_in_range));
                            }
                        }
                        else
                        {
                            LuaConsole::checkResult(beam_mode.deactivate_callback.call<void>(this_entity, utility_beam.effect_target_entity));
                        }
                    }
                }
            }

            if (utility_mount->cooldown > 0.0f) utility_mount->cooldown -= delta;
            utility_mount->is_firing = false;
            // Remove the transform from the targetless beam's spoofed entity
            // to prevent it from showing up (i.e. if assigned a trace) when
            // the beam is inactive.
            utility_beam.effect_target_entity.removeComponent<sp::Transform>();
        }
        utility_beam.was_active = utility_mount->active;

        // Prune stale entries from beam_effect_entities map.
        for (auto it = utility_beam.beam_effect_entities.begin(); it != utility_beam.beam_effect_entities.end(); )
        {
            if (!it->first || !it->second)
                it = utility_beam.beam_effect_entities.erase(it);
            else
                ++it;
        }

        mounts.mounts_dirty = true;
    }
}

void UtilityBeamSystem::fire(sp::ecs::Entity firing_entity, Mount& utility_mount, CustomBeamMode& beam_mode, sp::Transform& transform, sp::ecs::Entity target_entity, float distance, float angle_diff)
{
    utility_mount.heat_per_second = beam_mode.heat_per_sec;
    utility_mount.energy_use_per_second = beam_mode.energy_per_sec;

    utility_mount.is_firing = false;
    LuaConsole::checkResult(beam_mode.callback.call<void>(firing_entity, target_entity, distance, angle_diff));

    if (utility_mount.is_firing)
    {
        if (auto target_transform = target_entity.getComponent<sp::Transform>())
        {
            auto hit_location = target_transform->getPosition();
            if (auto target_physics = target_entity.getComponent<sp::Physics>())
            {
                auto direction = target_transform->getPosition() - transform.getPosition();
                if (glm::length(direction) > 0.0f)
                    hit_location -= glm::normalize(direction) * target_physics->getSize().x;
            }

            auto utility_beam = firing_entity.getComponent<UtilityBeam>();
            if (!utility_beam) return;

            auto& effect_entity = utility_beam->beam_effect_entities[target_entity];
            if (!effect_entity || !effect_entity.hasComponent<BeamEffect>())
            {
                effect_entity = sp::ecs::Entity::create();
                effect_entity.addComponent<sp::Transform>(transform);
            }

            auto& beam_effect = effect_entity.getOrAddComponent<BeamEffect>();
            beam_effect.source = firing_entity;
            beam_effect.target = target_entity;
            beam_effect.beam_texture = utility_mount.texture;
            beam_effect.fire_ring = false;
            beam_effect.lifetime = 1.0f;

            auto local_hit = hit_location - target_transform->getPosition();
            beam_effect.target_location = hit_location;
            beam_effect.target_offset = glm::vec3(local_hit.x, local_hit.y, 0.0f);
            if (beam_effect.target_offset != glm::vec3(0.0f))
                beam_effect.hit_normal = glm::normalize(beam_effect.target_offset);
        }
    }
}

void UtilityBeamSystem::render3D(sp::ecs::Entity entity, sp::Transform& transform, UtilityBeamEffect& beam_effect)
{
    glm::vec3 startPoint(transform.getPosition().x, transform.getPosition().y, beam_effect.source_offset.z);
    glm::vec3 endPoint(beam_effect.target_location.x, beam_effect.target_location.y, beam_effect.target_offset.z);
    glm::vec3 eyeNormal = glm::normalize(glm::cross(camera_position - startPoint, endPoint - startPoint));

    textureManager.getTexture(beam_effect.beam_texture)->bind();

    ShaderRegistry::ScopedShader beamShader(ShaderRegistry::Shaders::Basic);

    auto model_matrix = glm::identity<glm::mat4>();

    glUniform4f(beamShader.get().uniform(ShaderRegistry::Uniforms::Color), beam_effect.lifetime, beam_effect.lifetime, beam_effect.lifetime, 1.0f);
    glUniformMatrix4fv(beamShader.get().uniform(ShaderRegistry::Uniforms::Model), 1, false, glm::value_ptr(model_matrix));

    gl::ScopedVertexAttribArray positions(beamShader.get().attribute(ShaderRegistry::Attributes::Position));
    gl::ScopedVertexAttribArray texcoords(beamShader.get().attribute(ShaderRegistry::Attributes::Texcoords));

    struct VertexAndTexCoords
    {
        glm::vec3 vertex;
        glm::vec2 texcoords;
    };

    std::array<VertexAndTexCoords, 4> quad;
    // Beam
    {
        glm::vec3 v0 = startPoint + eyeNormal * 4.0f;
        glm::vec3 v1 = endPoint + eyeNormal * 4.0f;
        glm::vec3 v2 = endPoint - eyeNormal * 4.0f;
        glm::vec3 v3 = startPoint - eyeNormal * 4.0f;
        quad[0].vertex = v0;
        quad[0].texcoords = { 0.f, 0.f };
        quad[1].vertex = v1;
        quad[1].texcoords = { 0.f, 1.f };
        quad[2].vertex = v2;
        quad[2].texcoords = { 1.f, 1.f };
        quad[3].vertex = v3;
        quad[3].texcoords = { 1.f, 0.f };

        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));
        // Draw the beam
        std::initializer_list<uint16_t> indices = { 0, 1, 2, 2, 3, 0 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));

    }

    // Fire ring
    if (beam_effect.fire_ring)
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        { float fire_val = Tween<float>::easeInCubic(beam_effect.lifetime, 1.0f, 0.0f, 1.0f, 0.0f); glUniform4f(beamShader.get().uniform(ShaderRegistry::Uniforms::Color), fire_val, fire_val, fire_val, fire_val); }

        glm::vec3 side = glm::cross(beam_effect.hit_normal, glm::vec3(0, 0, 1));
        glm::vec3 up = glm::cross(side, beam_effect.hit_normal);

        glm::vec3 v0(beam_effect.target_location.x, beam_effect.target_location.y, beam_effect.target_offset.z);

        float ring_size = Tween<float>::easeOutCubic(beam_effect.lifetime, 1.0, 0.0, 10.0f, 80.0f);
        auto v1 = v0 + side * ring_size + up * ring_size;
        auto v2 = v0 - side * ring_size + up * ring_size;
        auto v3 = v0 - side * ring_size - up * ring_size;
        auto v4 = v0 + side * ring_size - up * ring_size;

        quad[0].vertex = v1;
        quad[0].texcoords = { 0.f, 0.f };
        quad[1].vertex = v2;
        quad[1].texcoords = { 1.f, 0.f };
        quad[2].vertex = v3;
        quad[2].texcoords = { 1.f, 1.f };
        quad[3].vertex = v4;
        quad[3].texcoords = { 0.f, 1.f };

        textureManager.getTexture("texture/fire_ring.png")->bind();
        glVertexAttribPointer(positions.get(), 3, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)quad.data());
        glVertexAttribPointer(texcoords.get(), 2, GL_FLOAT, GL_FALSE, sizeof(VertexAndTexCoords), (GLvoid*)((char*)quad.data() + sizeof(glm::vec3)));
        std::initializer_list<uint16_t> indices = { 0, 1, 2, 2, 3, 0 };
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, std::begin(indices));

        glBlendFunc(GL_ONE, GL_ONE);
    }
}

void UtilityBeamSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, UtilityBeam& utility_beam)
{
    // Render other ships' utility beams only if they're fully scanned.
    if (entity != my_spaceship)
    {
        auto scanstate = entity.getComponent<ScanState>();

        if (scanstate && my_spaceship && scanstate->getStateFor(my_spaceship) != ScanState::State::FullScan)
            return;
    }

    auto mounts = entity.getComponent<Mounts>();
    if (!mounts) return;

    Mount* utility_mount = nullptr;
    for (auto& m : mounts->mounts)
    {
        if (m.type == MountType::UtilityBeam)
        {
            utility_mount = &m;
            break;
        }
    }
    if (!utility_mount) return;

    // Draw beam arcs only if the beam has a range.
    // A beam with range of 0 effectively doesn't exist.
    if (utility_mount->range == 0.0f) return;

    // If the beam is cooling down, flash and fade the arc color.
    glm::u8vec4 color = Tween<glm::u8vec4>::linear(
        std::max(0.0f, utility_mount->cooldown),
        0,
        utility_mount->cycle_time,
        utility_mount->arc_color,
        utility_mount->arc_color_fire
    );

    // Set the beam's origin on radar to its relative position on the mesh.
    auto arc_center = rotateVec2(glm::vec2(utility_mount->position.x, utility_mount->position.y) * scale, rotation) + screen_position;

    drawArc(
        renderer,
        arc_center,
        rotation + (utility_mount->direction - utility_mount->arc * 0.5f),
        utility_mount->arc,
        utility_mount->range * scale,
        color
    );

    // If the beam is turreted, draw the turret's arc.
    if (utility_mount->turret_arc > 0.0f)
    {
        glm::u8vec4 turret_arc_color = utility_mount->arc_color;
        turret_arc_color.a /= 4;

        drawArc(
            renderer,
            arc_center,
            rotation + (utility_mount->turret_direction - utility_mount->turret_arc * 0.5f),
            utility_mount->turret_arc,
            utility_mount->range * scale,
            turret_arc_color
        );
    }
}
