#include "tractorbeam.h"
#include "tween.h"

void TractorBeamSys::setArcAndAdjustRange(float arc_request)
{
    if (max_arc <= 0.0f) return;
    arc_request = std::max(std::min(arc_request, max_arc), MIN_ARC);
    arc = arc_request;
    range = std::max(max_range * 0.25f, max_range * (1.0f - ((arc - MIN_ARC) / (max_arc - MIN_ARC))));
}

void TractorBeamSys::setRangeAndAdjustArc(float range_request)
{
    if (max_range <= 0.0f) return;
    const float min_range = max_range * 0.25f;
    range_request = std::max(std::min(range_request, max_range), min_range);
    range = range_request;
    arc = std::max(MIN_ARC, max_arc * (1.0f - ((range - min_range) / (max_range - min_range))));
}
