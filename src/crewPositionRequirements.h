#pragma once

#include "crewPosition.h"
#include "ecs/entity.h"

namespace crewPositionRequirements
{
    // Returns true if the ship has the components required to operate a
    // given crew position. Returns true for positions that have no
    // component gate.
    bool hasRequirements(CrewPosition cp, sp::ecs::Entity ship);

    // Returns the localized "no controls" message for the given position,
    // or an empty string if the position has no component gate.
    string getMissingMessage(CrewPosition cp);
}
