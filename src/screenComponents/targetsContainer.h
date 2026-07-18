#pragma once

#include "ecs/entity.h"
#include "components/faction.h"
#include <functional>

class TargetsContainer
{
public:
    // Targeting behavior can depend on the targeting interaction. Comms
    // targetability has different requirements than weapons, GM screen,
    // scanning, etc.
    enum ESelectionType
    {
        Selectable,
        Targetable,   // Weapons
        Scannable,    // Scanner
        Hackable,     // Hacking
        Analyzable,   // Target analysis
        Communicable, // Comms
        UtilityBeam
    };

    // Entities' faction relationships with one another are either friendly,
    // neutral, or hostile. On radar, their relationship is either known
    // (relationship is visible) or unknown (not scanned or interacted with).
    //
    // Targetability can depend on both dimensions. For instance, an entity
    // whose FoF is unknown might be targetable by weapons regardless of faction
    // relationship, while if its FoF is both known and friendly, it might not
    // be weapons targetable. Different targeting navigation methods, such as
    // selecting the next enemy or unscanned target, also filter by FoF type.
    enum class KnownFriendOrFoe
    {
        Any,              // Any FoF state
        Known,            // If FoF is known
        Unknown,          // If unknown
        KnownFriendly,    // If known and friendly
        KnownNonFriendly, // If known and either neutral or hostile
        NotKnownFriendly, // If unknown, neutral, or hostile
        KnownNeutral,     // If known and neither friendly nor hostile
        KnownNonNeutral,  // If known and either friendly or hostile
        NotKnownNeutral,  // If unknown, friendly, or hostile
        KnownHostile,     // If known and hostile
        KnownNonHostile,  // If known and either neutral or friendly
        NotKnownHostile   // If unknown, neutral, or friendly
    };

    TargetsContainer();

    void setAllowWaypointSelection() { allow_waypoint_selection = true; }

    void clear();
    void add(sp::ecs::Entity obj);
    void set(sp::ecs::Entity obj);
    void set(const std::vector<sp::ecs::Entity>& objs);
    std::vector<sp::ecs::Entity> getTargets();
    sp::ecs::Entity get();
    int getWaypointIndex();
    int getWaypointSetId();
    void setWaypointIndex(int index, int set_id = 1);

    void setToClosestTo(glm::vec2 position, float max_range, ESelectionType selection_type);

    // Select next/previous target by selection type, and optionally also by
    // friend-or-foe state.
    void setNextTarget(glm::vec2 position, float max_range, ESelectionType selection_type, KnownFriendOrFoe known_fof = KnownFriendOrFoe::Any);
    void setPrevTarget(glm::vec2 position, float max_range, ESelectionType selection_type, KnownFriendOrFoe known_fof = KnownFriendOrFoe::Any);
    // Select next/previous target by selection type and a function-defined
    // filter.
    void setNextTarget(glm::vec2 position, float max_range, ESelectionType selection_type, std::function<bool(sp::ecs::Entity)> filter);
    void setPrevTarget(glm::vec2 position, float max_range, ESelectionType selection_type, std::function<bool(sp::ecs::Entity)> filter);

private:
    std::vector<sp::ecs::Entity> entries;
    bool allow_waypoint_selection;
    int waypoint_selection_index;
    int waypoint_selection_set_id;

    bool isFoFKnown(sp::ecs::Entity entity);
    void sortByDistance(glm::vec2 position, std::vector<sp::ecs::Entity>& entities);
    bool isValidTarget(sp::ecs::Entity entity, ESelectionType selection_type);
    // Return a vector of entities that match the given condition.
    std::vector<sp::ecs::Entity> populateEntities(glm::vec2 position, float max_range, ESelectionType selection_type, KnownFriendOrFoe known_fof);
    std::vector<sp::ecs::Entity> populateEntities(glm::vec2 position, float max_range, ESelectionType selection_type, std::function<bool(sp::ecs::Entity)> filter);
    void setTarget(ESelectionType selection_type);
    void setNextTarget(glm::vec2 position, const std::vector<sp::ecs::Entity>& entities, ESelectionType selection_type = ESelectionType::Targetable);
    void setPrevTarget(glm::vec2 position, const std::vector<sp::ecs::Entity>& entities, ESelectionType selection_type = ESelectionType::Targetable);
};
