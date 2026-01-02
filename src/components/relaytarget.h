#pragma once

#include "ecs/entity.h"

// RelayTarget represents the entity selected on the Relay/Strategic Map radar.
// This is separate from CommsTarget (active comms) and HackTarget (active hacking).
class RelayTarget
{
public:
    sp::ecs::Entity entity;
};
