#include "scanning.h"
#include <ecs/query.h>
#include "gameGlobalInfo.h"
#include "multiplayer_server.h"
#include <glm/gtx/norm.hpp>

#include "components/radar.h"
#include "components/scanning.h"

#include "systems/radarblock.h"

#include "menus/luaConsole.h"

static constexpr float PROBE_SCAN_RANGE = 5000.0f;

void ScanningSystem::update(float delta)
{
    for (auto [entity, scanner] : sp::ecs::Query<ScienceScanner>())
    {
        if (!scanner.scan_target)
        {
            scanner.delay = 0.0f;
            continue;
        }

        if (game_server && scanner.delay > 0.0f)
        {
            auto target_transform = scanner.scan_target.getComponent<sp::Transform>();
            auto ship_transform = entity.getComponent<sp::Transform>();

            if (ship_transform && target_transform)
            {
                bool target_reachable = false;

                if (auto lrr = entity.getComponent<LongRangeRadar>())
                {
                    float long_range = lrr->long_range;
                    float short_range = lrr->short_range;

                    if (auto sensors = entity.getComponent<SensorsSystem>())
                    {
                        long_range = sensorsScaleLongRange(long_range, sensors->getSystemEffectiveness());
                        short_range = sensorsScaleShortRange(short_range, sensors->getSystemEffectiveness());
                    }

                    // Check if the target's reachable from the player ship's
                    // sensors.
                    if (glm::length(target_transform->getPosition() - ship_transform->getPosition()) <= long_range
                        && !RadarBlockSystem::isRadarBlockedFrom(ship_transform->getPosition(), scanner.scan_target, short_range)
                    ) target_reachable = true;
                }

                // If the scan target is out of the player's radar range,
                // confirm that it's also out of linked probe range.
                if (!target_reachable)
                {
                    if (auto rl = entity.getComponent<RadarLink>())
                    {
                        if (rl->linked_entity)
                        {
                            if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
                            {
                                float probe_short_range = getEffectiveShortRangeRadarRange(rl->linked_entity);
                                float dist = glm::length(target_transform->getPosition() - probe_transform->getPosition());
                                if (dist <= PROBE_SCAN_RANGE
                                    && !RadarBlockSystem::isRadarBlockedFrom(probe_transform->getPosition(), scanner.scan_target, probe_short_range)
                                ) target_reachable = true;
                            }
                        }
                    }
                }

                // If the target's not on any reachable sensor range, cancel the
                // scan and clear the scanner's target.
                if (!target_reachable)
                {
                    scanner.scan_target = {};
                    scanner.delay = 0.0f;
                    scanner.source = {};
                    continue;
                }
            }
        }

        if (auto ss = scanner.scan_target.getComponent<ScanState>())
        {
            if (ss->complexity == 0 || (ss->complexity < 0 && gameGlobalInfo->scanning_complexity == SC_None))
            {
                if (scanner.delay == scanner.max_scanning_delay && ss->on_scan_initiated)
                    LuaConsole::checkResult(ss->on_scan_initiated.call<void>(scanner.scan_target, entity, scanner.source));

                scanner.delay -= delta;
                if (scanner.delay < 0.0f && game_server)
                    scanningFinished(entity);
            }
        }
        else scanner.delay = 0.0f;
    }
}

void ScanningSystem::scanningFinished(sp::ecs::Entity command_source)
{
    auto scanner = command_source.getComponent<ScienceScanner>();
    if (!scanner) return;

    if (auto ss = scanner->scan_target.getComponent<ScanState>())
    {
        switch (ss->getStateFor(command_source))
        {
        case ScanState::State::NotScanned:
        case ScanState::State::FriendOrFoeIdentified:
            if (ss->allow_simple_scan)
                ss->setStateFor(command_source, ScanState::State::SimpleScan);
            else
                ss->setStateFor(command_source, ScanState::State::FullScan);
            break;
        case ScanState::State::SimpleScan:
            ss->setStateFor(command_source, ScanState::State::FullScan);
            break;
        case ScanState::State::FullScan:
            break;
        }
        if (ss->on_scan_completed)
            LuaConsole::checkResult(ss->on_scan_completed.call<void>(scanner->scan_target, command_source, scanner->source));
    }

    scanner->source = {};
    scanner->scan_target = {};
    scanner->delay = 0.0f;
}
