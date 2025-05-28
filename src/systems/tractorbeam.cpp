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
#include "ecs/query.h"
#include "main.h"
#include "textureManager.h"
#include "glObjects.h"
#include "shaderRegistry.h"
#include "tween.h"
#include "random.h"
#include "playerInfo.h"

#include <glm/glm.hpp>
#include <glm/gtc/type_ptr.hpp>
#include <graphics/opengl.h>


void TractorBeamSystem::update(float delta)
{
    LOG(WARNING) << "TractorBeamSystem start of update " << delta;
    if (!game_server) return;
    if (delta <= 0.0f) return;

    for(auto [entity, tractorsys, target, transform, reactor, docking_port] : sp::ecs::Query<TractorBeamSys, Target, sp::Transform, sp::ecs::optional<Reactor>, sp::ecs::optional<DockingPort>>()) {
        LOG(WARNING) << "In TractorBeamSystem update for loop";
        auto warp = entity.getComponent<WarpDrive>();
        auto distance = 0.0f; // TODO
        auto angle_diff = 0.0f; // TODO

        // Check on tractor beam only if we are on the server and aren't
        // paused, and if the beams are cooled down.
        if (tractorsys.range > 0.0f && delta > 0.0f && (!warp || warp->current == 0.0f) && (!docking_port || docking_port->state == DockingPort::State::NotDocking))
        {
            LOG(WARNING) << "In TractorBeamSystem update firing check if statement";
            // If the target is in the beam's arc and range, the beam has cooled
            // down, and the beam can consume enough energy to fire ...
            if (distance < tractorsys.range && tractorsys.cooldown <= 0.0f && fabsf(angle_diff) < tractorsys.arc / 2.0f && (!reactor || reactor->useEnergy(tractorsys.energy_per_tick)))
            {
                LOG(WARNING) << "In TractorBeamSystem update firing if statement";
                // ... add heat to the beam and zap the target.
                if (entity.hasComponent<Coolant>())
                    tractorsys.addHeat(tractorsys.heat_per_tick);

                //When we fire a beam, and we hit an enemy, check if we are not scanned yet, if we are not, and we hit something that we know is an enemy or friendly,
                //  we now know if this ship is an enemy or friend.
                Faction::didAnOffensiveAction(entity);

                tractorsys.cooldown = tractorsys.cycle_time; // Reset time of weapon
                /*
                auto hit_location = target_transform->getPosition();
                auto r = 100.0f;
                if (auto physics = target.entity.getComponent<sp::Physics>()) {
                    hit_location -= glm::normalize(target_transform->getPosition() - transform.getPosition()) * physics->getSize().x;
                    r = physics->getSize().x;
                }
                */
                auto e = sp::ecs::Entity::create();
                e.addComponent<sp::Transform>(transform);
                /*
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
    LOG(WARNING) << "In TractorBeamSystem end of update " << delta;
}

void TractorBeamSystem::render3D(sp::ecs::Entity e, sp::Transform& transform, TractorBeamEffect& be)
{
    LOG(WARNING) << "In TractorBeamSystem start/end of render3D";
}

static void drawArc(sp::RenderTarget& renderer, glm::vec2 arc_center, float angle0, float arc_angle, float arc_radius, glm::u8vec4 color)
{
    LOG(WARNING) << "In TractorBeamSystem start of drawArc";
    // Set the beam's origin on radar to its relative position on the mesh.
    float outline_thickness = std::min(20.0f, arc_radius * 0.2f);
    float beam_arc_curve_length = arc_radius * arc_angle / 180.0f * glm::pi<float>();
    outline_thickness = std::min(outline_thickness, beam_arc_curve_length * 0.25f);

    size_t curve_point_count = 0;
    if (outline_thickness > 0.f)
        curve_point_count = static_cast<size_t>(beam_arc_curve_length / (outline_thickness * 0.9f));

    struct ArcPoint {
        glm::vec2 point;
        glm::vec2 normal; // Direction towards the center.
    };

    //Arc points
    std::vector<ArcPoint> arc_points;
    arc_points.reserve(curve_point_count + 1);
    
    for (size_t i = 0; i < curve_point_count; i++)
    {
        auto angle = vec2FromAngle(angle0 + i * arc_angle / curve_point_count) * arc_radius;
        arc_points.emplace_back(ArcPoint{ arc_center + angle, glm::normalize(angle) });
    }
    {
        auto angle = vec2FromAngle(angle0 + arc_angle) * arc_radius;
        arc_points.emplace_back(ArcPoint{ arc_center + angle, glm::normalize(angle) });
    }

    for (size_t n = 0; n < arc_points.size() - 1; n++)
    {
        const auto& p0 = arc_points[n].point;
        const auto& p1 = arc_points[n + 1].point;
        const auto& n0 = arc_points[n].normal;
        const auto& n1 = arc_points[n + 1].normal;
        renderer.drawTexturedQuad("gradient.png",
            p0, p0 - n0 * outline_thickness,
            p1 - n1 * outline_thickness, p1,
            { 0.f, 0.5f }, { 1.f, 0.5f }, { 1.f, 0.5f }, { 0.f, 0.5f },
            color);
    }

    if (arc_radius < 360.f)
    {
        // Arc bounds.
        // We use the left- and right-most edges as lines, going inwards, parallel to the center.
        const auto left_edge = vec2FromAngle(angle0) * arc_radius;
        const auto right_edge = vec2FromAngle(angle0 + arc_radius) * arc_radius;
    
        // Compute the half point, always going clockwise from the left edge.
        // This makes sure the algorithm never takes the short road.
        auto halfway_angle = vec2FromAngle(angle0 + arc_radius / 2.f) * arc_radius;
        auto middle = glm::normalize(halfway_angle);

        // Edge vectors.
        const auto left_edge_vector = glm::normalize(left_edge);
        const auto right_edge_vector = glm::normalize(right_edge);

        // Edge normals, inwards.
        auto left_edge_normal = glm::vec2{ left_edge_vector.y, -left_edge_vector.x };
        const auto right_edge_normal = glm::vec2{ -right_edge_vector.y, right_edge_vector.x };

        // Initial offset, follow along the edges' normals, inwards.
        auto left_inner_offset = -left_edge_normal * outline_thickness;
        auto right_inner_offset = -right_edge_normal * outline_thickness;

        if (arc_radius < 180.f)
        {
            // The thickness being perpendicular from the edges,
            // the inner lines just crosses path on the height,
            // so just use that point.
            left_inner_offset = middle * outline_thickness / sinf(glm::radians(arc_radius / 2.f));
            right_inner_offset = left_inner_offset;
        }
        else
        {
            // Make it shrink nicely as it grows up to 360 deg.
            // For that, we use the edge's normal against the height which will change from 0 to 90deg.
            // Also flip the direction so our points stay inside the beam.
            auto thickness_scale = -glm::dot(middle, right_edge_normal);
            left_inner_offset *= thickness_scale;
            right_inner_offset *= thickness_scale;
        }

        renderer.drawTexturedQuad("gradient.png",
            arc_center, arc_center + left_inner_offset,
            arc_center + left_edge - left_edge_normal * outline_thickness, arc_center + left_edge,
            { 0.f, 0.5f }, { 1.f, 0.5f }, { 1.f, 0.5f }, { 0.f, 0.5f },
            color);

        renderer.drawTexturedQuad("gradient.png",
            arc_center, arc_center + right_inner_offset,
            arc_center + right_edge - right_edge_normal * outline_thickness, arc_center + right_edge,
            { 0.f, 0.5f }, { 1.f, 0.5f }, { 1.f, 0.5f }, { 0.f, 0.5f },
            color);
    }
    LOG(WARNING) << "In TractorBeamSystem end of drawArc";
}

void TractorBeamSystem::renderOnRadar(sp::RenderTarget& renderer, sp::ecs::Entity entity, glm::vec2 screen_position, float scale, float rotation, TractorBeamSys& tractor_system)
{
    LOG(WARNING) << "Inside TractorBeamSystem start of renderOnRadar";

    if (entity != my_spaceship) {
        auto scanstate = entity.getComponent<ScanState>();
        if (scanstate && my_spaceship && scanstate->getStateFor(my_spaceship) != ScanState::State::FullScan)
            return;
    }

    // Draw beam arcs only if the beam has a range. A beam with range 0
    // effectively doesn't exist; exit if that's the case.
    LOG(WARNING) << "tractor_system.range = " << tractor_system.range;
    if (tractor_system.range > 0.0f) {
        LOG(WARNING) << "Inside renderOnRadar if to render on radar";
        // If the beam is cooling down, flash and fade the arc color.
        glm::u8vec4 color = Tween<glm::u8vec4>::linear(std::max(0.0f, tractor_system.cooldown), 0, tractor_system.cycle_time, tractor_system.arc_color, tractor_system.arc_color_fire);
        
        // Initialize variables from the beam's data.
        float beam_direction = tractor_system.bearing;
        float beam_arc = tractor_system.arc;
        float beam_range = tractor_system.range;

        // Set the beam's origin on radar to its relative position on the mesh.
        auto beam_offset = rotateVec2(glm::vec2(tractor_system.position.x, tractor_system.position.y) * scale, rotation);
        auto arc_center = beam_offset + screen_position;

        LOG(WARNING) << "Rendering tractor beam\nbeam_offset: " << beam_offset << "\narc_center: " << arc_center << "\nbeam_direction: " << beam_direction << "\nbeam_arc: " << beam_arc << "\nbeam_range: " << beam_range << "\nscale: " << scale;

        drawArc(renderer, arc_center, rotation + (beam_direction - beam_arc / 2.0f), beam_arc, beam_range * scale, color);
    }
    LOG(WARNING) << "Inside TractorBeamSystem end of renderOnRadar";
}