#pragma once

#include "ecs/entity.h"
#include "script/callback.h"
#include <vector>

class ScanState
{
public:
    enum class State
    {
        NotScanned,
        FriendOrFoeIdentified,
        SimpleScan,
        FullScan
    };

    struct Entry
    {
        sp::ecs::Entity faction;
        ScanState::State state;
    };

    // Scan state per FactionInfo. When the required faction is not in the
    // vector, the scan state is SS_NotScanned.
    bool per_faction_dirty = true;
    std::vector<Entry> per_faction;

    // Determines whether the first completed scan is a full or simple scan.
    bool allow_simple_scan = false;
    // Number of bars each minigame has (-1 for default)
    int complexity = -1;
    // Number of minigames that need to be finished (-1 for default)
    int depth = -1;

    State getStateFor(sp::ecs::Entity entity);
    void setStateFor(sp::ecs::Entity entity, State state);
    State getStateForFaction(sp::ecs::Entity entity);
    void setStateForFaction(sp::ecs::Entity entity, State state);

    sp::script::Callback on_scan_initiated;
    sp::script::Callback on_scan_completed;
    sp::script::Callback on_scan_cancelled;
};

class ScienceDescription
{
public:
    string not_scanned;
    string friend_or_foe_identified;
    string simple_scan;
    string full_scan;
};

class ScienceScanner
{
public:
    // When a delay-based scan is done, this value counts down.
    float delay = 0.0f;
    float max_scanning_delay = 6.0f;
    sp::ecs::Entity target;
    // Cached target for in-progress scan.
    sp::ecs::Entity scan_target;
    sp::ecs::Entity source;
};