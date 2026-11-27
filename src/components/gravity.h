#pragma once

#include <glm/vec2.hpp>
#include "script/callback.h"


class Gravity
{
public:
    float range = 5000.0f;
    float force = 50.0f;
    bool damage = false;

    // Called with (gravity entity, entity that reached the center).
    sp::script::Callback on_singularity;

    // Deprecated: use Teleporter::target_coordinates instead.
    glm::vec2 wormhole_target{};
    // Deprecated: use Teleporter::on_teleportation instead.
    sp::script::Callback on_teleportation;
};
