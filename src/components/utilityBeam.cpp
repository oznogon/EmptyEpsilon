#include "utilityBeam.h"
#include "tween.h"

bool UtilityBeam::setArc(float arc_request)
{
    if (max_arc <= 0.0f)
    {
        LOG(DEBUG) << "Attempted to set utility beam arc when max arc <= 0";
        return false;
    }
    if (fixed_arc)
    {
        LOG(DEBUG) << "Attempted to set arc on fixed-arc utility beam";
        return false;
    }
    if (arc_request <= 0.0f || arc_request >= 360.0f)
        LOG(WARNING) << "Attempted invalid utility beam arc request of " << arc_request;

    arc = std::max(std::min(arc_request, max_arc), MIN_ARC);
    return true;
}

bool UtilityBeam::setArcAndAdjustRange(float arc_request)
{
    if (setArc(arc_request))
        return setRange(std::max(max_range * 0.25f, max_range * (1.0f - ((arc - MIN_ARC) / (max_arc - MIN_ARC)))));

    return false;
}

bool UtilityBeam::setRange(float range_request)
{
    if (max_range <= 0.0f)
    {
        LOG(DEBUG) << "Attempted to set utility beam range when max range <= 0";
        return false;
    }
    if (fixed_range)
    {
        LOG(DEBUG) << "Attempted to set range on fixed-range utility beam";
        return false;
    }
    if (range_request <= 0.0f)
        LOG(WARNING) << "Attempted invalid utility beam range request of " << range_request;

    range = std::max(std::min(range_request, max_range), MIN_RANGE);
    return true;
}

bool UtilityBeam::setRangeAndAdjustArc(float range_request)
{
    if (setRange(range_request))
        return setArc(std::max(MIN_ARC, max_arc * (1.0f - ((range - MIN_RANGE) / (max_range - MIN_RANGE)))));

    return false;
}
