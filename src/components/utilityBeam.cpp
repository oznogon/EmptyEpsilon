#include "utilityBeam.h"
#include "mounts.h"
#include "tween.h"

bool utilityBeamSetArc(Mount& mount, float arc_request)
{
    if (mount.max_arc <= 0.0f)
    {
        LOG(Debug, "[utilitybeam] Attempted to set utility beam arc when max arc <= 0");
        return false;
    }

    if (mount.fixed_arc)
    {
        LOG(Debug, "[utilitybeam] Attempted to set arc on fixed-arc utility beam");
        return false;
    }

    if (arc_request <= 0.0f || arc_request >= 360.0f)
        LOG(Warning, "[utilitybeam] Attempted invalid utility beam arc request of ", arc_request);

    mount.arc = std::max(std::min(arc_request, mount.max_arc), UTILITY_BEAM_MIN_ARC);
    return true;
}

bool utilityBeamSetArcAndAdjustRange(Mount& mount, float arc_request)
{
    if (utilityBeamSetArc(mount, arc_request))
        return utilityBeamSetRange(mount, std::max(mount.max_range * 0.25f, mount.max_range * (1.0f - ((mount.arc - UTILITY_BEAM_MIN_ARC) / (mount.max_arc - UTILITY_BEAM_MIN_ARC)))));

    return false;
}

bool utilityBeamSetRange(Mount& mount, float range_request)
{
    if (mount.max_range <= 0.0f)
    {
        LOG(Debug, "[utilitybeam] Attempted to set utility beam range when max range <= 0");
        return false;
    }

    if (mount.fixed_range)
    {
        LOG(Debug, "[utilitybeam] Attempted to set range on fixed-range utility beam");
        return false;
    }

    if (range_request <= 0.0f)
        LOG(Warning, "[utilitybeam] Attempted invalid utility beam range request of ", range_request);

    mount.range = std::max(std::min(range_request, mount.max_range), UTILITY_BEAM_MIN_RANGE);
    return true;
}

bool utilityBeamSetRangeAndAdjustArc(Mount& mount, float range_request)
{
    if (utilityBeamSetRange(mount, range_request))
        return utilityBeamSetArc(mount, std::max(UTILITY_BEAM_MIN_ARC, mount.max_arc * (1.0f - ((mount.range - UTILITY_BEAM_MIN_RANGE) / (mount.max_range - UTILITY_BEAM_MIN_RANGE)))));

    return false;
}
