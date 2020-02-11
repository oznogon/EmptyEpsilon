#include "targetsContainer.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"

TargetsContainer::TargetsContainer()
{
    waypoint_selection_index = -1;
    allow_waypoint_selection = false;
    signal_threshold = 0.3f;
}

void TargetsContainer::clear()
{
    waypoint_selection_index = -1;
    entries.clear();
}

void TargetsContainer::add(P<SpaceObject> obj)
{
    if (obj && !entries.has(obj))
        entries.push_back(obj);
}

void TargetsContainer::set(P<SpaceObject> obj)
{
    if (obj)
    {
        P<SpaceShip> ship = obj;
        bool reaches_signal_threshold;

        // Use dynamic radar values for ships. Otherwise, use the baseline.
        if (ship)
            reaches_signal_threshold = ship->reachesSignalThreshold(signal_threshold);
        else
            reaches_signal_threshold = obj->reachesSignalThreshold(signal_threshold);

        // Object is targetable only if it exceeds the signal threshold or is
        // visible.
        if (obj->isVisible() || reaches_signal_threshold)
        {
            if (entries.size() > 0)
            {
                entries[0] = obj;
                if (entries.size() > 1)
                    entries.resize(1);
            } else {
                entries.push_back(obj);
            }
        }
    }
    else
    {
        clear();
    }
    waypoint_selection_index = -1;
}

void TargetsContainer::set(PVector<SpaceObject> objs)
{
    waypoint_selection_index = -1;
    entries = objs;
}

void TargetsContainer::setSignalThreshold(float signal_threshold)
{
    // Threshold in a targets container can't be < 0.
    signal_threshold = std::max(0.0f, signal_threshold);
}

float TargetsContainer::getSignalThreshold()
{
    return signal_threshold;
}

void TargetsContainer::setToClosestTo(sf::Vector2f position, float max_range, ESelectionType selection_type)
{
    P<SpaceObject> target;
    PVector<Collisionable> list = CollisionManager::queryArea(position - sf::Vector2f(max_range, max_range), position + sf::Vector2f(max_range, max_range));
    foreach(Collisionable, obj, list)
    {
        P<SpaceObject> spaceObject = obj;

        if (spaceObject && spaceObject != my_spaceship)
        {
            switch(selection_type)
            {
            case Selectable:
                if (!spaceObject->canBeSelectedBy(my_spaceship) && !reachesSignalThreshold(spaceObject))
                    continue;
                break;
            case Targetable:
                if (!spaceObject->canBeTargetedBy(my_spaceship) && !reachesSignalThreshold(spaceObject))
                    continue;
                break;
            }
            if (!target || sf::length(position - spaceObject->getPosition()) < sf::length(position - target->getPosition()))
                target = spaceObject;
        }
    }

    if (my_spaceship && allow_waypoint_selection)
    {
        for(int n=0; n<my_spaceship->getWaypointCount(); n++)
        {
            if ((my_spaceship->waypoints[n] - position) < max_range)
            {
                if (!target || sf::length(position - my_spaceship->waypoints[n]) < sf::length(position - target->getPosition()))
                {
                    clear();
                    waypoint_selection_index = n;
                    waypoint_selection_position = my_spaceship->waypoints[n];
                    return;
                }
            }
        }
    }
    set(target);
}

int TargetsContainer::getWaypointIndex()
{
    if (!my_spaceship || waypoint_selection_index < 0)
        waypoint_selection_index = -1;
    else if (waypoint_selection_index >= my_spaceship->getWaypointCount())
        waypoint_selection_index = -1;
    else if (my_spaceship->waypoints[waypoint_selection_index] != waypoint_selection_position)
        waypoint_selection_index = -1;
    return waypoint_selection_index;
}

void TargetsContainer::setWaypointIndex(int index)
{
    waypoint_selection_index = index;
    if (my_spaceship && index >= 0 && index < (int)my_spaceship->waypoints.size())
        waypoint_selection_position = my_spaceship->waypoints[index];
}
