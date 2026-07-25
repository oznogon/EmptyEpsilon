#pragma once

#include <cmath>
#include "stringImproved.h"

// Reformat a float as a string of its rounded integer.
static inline string toNearbyIntString(float value)
{
    return string(static_cast<int>(std::lrint(value)));
}
