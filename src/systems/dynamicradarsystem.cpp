#include "dynamicradarsystem.h"

#include "ecs/query.h"
#include "components/radar.h"
#include "components/shipsystem.h"
#include "components/warpdrive.h"
#include "components/jumpdrive.h"


void DynamicRadarSystem::update(float delta)
{
    for (auto [entity, dyn_sig] : sp::ecs::Query<DynamicRadarSignatureInfo>())
    {
        dyn_sig.gravitational = 0.0f;
        dyn_sig.electrical = 0.0f;
        dyn_sig.thermal = 0.0f;

        for (int n = 0; n < ShipSystem::COUNT; n++)
        {
            auto type = static_cast<ShipSystem::Type>(n);
            auto sys = ShipSystem::get(entity, type);
            if (!sys) continue;

            dyn_sig.thermal += std::max(0.0f, std::min(1.0f, sys->heat_level - (sys->coolant_level / 10.0f)));

            if (type == ShipSystem::Type::JumpDrive)
            {
                auto jump = entity.getComponent<JumpDrive>();
                if (jump && jump->charge < jump->max_distance)
                    dyn_sig.electrical += std::clamp(sys->power_level * (jump->charge / jump->max_distance), 0.0f, 1.0f);
            }
            else if (sys->power_level != 1.0f)
            {
                dyn_sig.electrical += std::max(-1.0f, std::min(1.0f, sys->power_level - 1.0f));
            }
        }

        auto jump = entity.getComponent<JumpDrive>();
        if (jump && jump->delay > 0.0f)
            dyn_sig.gravitational += std::clamp((1.0f / jump->delay) + 0.26f, 0.0f, 1.0f);

        auto warp = entity.getComponent<WarpDrive>();
        if (warp && warp->current > 0.0f)
            dyn_sig.gravitational += warp->current;
    }
}
