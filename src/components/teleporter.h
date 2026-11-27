#pragma once

#include <glm/vec2.hpp>
#include "script/callback.h"


class Teleporter
{
public:
    glm::vec2 target_coordinates{};
    sp::script::Callback on_teleportation;
    bool teleport_on_collision = true;
    bool is_single_use = false;
};
