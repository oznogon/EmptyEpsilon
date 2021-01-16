#include "targetInfo.h"
#include "playerInfo.h"
#include "spaceObjects/playerSpaceship.h"
#include "i18n.h"
#include "gui/gui2_keyvaluedisplay.h"

GuiTargetInfo::GuiTargetInfo(GuiContainer* owner, string id, TargetsContainer targets)
: GuiAutoLayout(owner, id, LayoutVerticalTopToBottom),
  targets(targets)
{
    // Autosize to fit container.
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Add key-value rows.
    target_callsign = new GuiKeyValueDisplay(this, "TARGET_CALLSIGN", 0.4, tr("target", "Callsign"), "-");
    target_callsign->setSize(GuiElement::GuiSizeMax, 30);
    target_distance = new GuiKeyValueDisplay(this, "TARGET_DISTANCE", 0.4, tr("target", "Distance"), "-");
    target_distance->setSize(GuiElement::GuiSizeMax, 30);
    target_bearing = new GuiKeyValueDisplay(this, "TARGET_BEARING", 0.4, tr("target", "Bearing"), "-");
    target_bearing->setSize(GuiElement::GuiSizeMax, 30);
    target_relspeed = new GuiKeyValueDisplay(this, "TARGET_RELATIVE_SPEED", 0.4, tr("target", "Rel. Speed"), "-");
    target_relspeed->setSize(GuiElement::GuiSizeMax, 30);
    target_faction = new GuiKeyValueDisplay(this, "TARGET_FACTION", 0.4, tr("target", "Faction"), "-");
    target_faction->setSize(GuiElement::GuiSizeMax, 30);
    target_type = new GuiKeyValueDisplay(this, "TARGET_TYPE", 0.4, tr("target", "Type"), "-");
    target_type->setSize(GuiElement::GuiSizeMax, 30);
    target_shields = new GuiKeyValueDisplay(this, "TARGET_SHIELDS", 0.4, tr("target", "Shields"), "-");
    target_shields->setSize(GuiElement::GuiSizeMax, 30);
    target_hull = new GuiKeyValueDisplay(this, "TARGET_HULL", 0.4, tr("target", "Hull"), "-");
    target_hull->setSize(GuiElement::GuiSizeMax, 30);
}

void GuiTargetInfo::onDraw(sf::RenderTarget& window)
{
    // Initialize row values.
    target_callsign->setValue("-");
    target_distance->setValue("-");
    target_bearing->setValue("-");
    target_relspeed->setValue("-");
    target_faction->setValue("-");
    target_type->setValue("-");
    target_shields->setValue("-");
    target_hull->setValue("-");

    // If we have a target, populate its info.
    if (targets.get() && my_spaceship)
    {
        // Determine object type.
        P<SpaceObject> obj = targets.get();
        P<SpaceShip> ship = obj;
        P<SpaceStation> station = obj;

        // Populate target's callsign.
        target_callsign->setValue(obj->getCallSign());

        // Calculate and populate target's distance from us.
        sf::Vector2f position_diff = obj->getPosition() - my_spaceship->getPosition();
        float distance = sf::length(position_diff);
        target_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);

        // Calculate target's bearing relative to us.
        float bearing = sf::vector2ToAngle(position_diff) - 270.0f;

        // Limit its bearing value.
        while (bearing < 0.0f)
        {
            bearing += 360.0f;
        }

        // Populate bearing.
        target_bearing->setValue(string(int(bearing)));

        // Calculate and populate the target's relative velocity to us.
        float rel_velocity = dot(obj->getVelocity(), position_diff / distance) - dot(my_spaceship->getVelocity(), position_diff / distance);

        if (fabs(rel_velocity) < 0.01)
        {
            rel_velocity = 0.0;
        }

        target_relspeed->setValue(string(rel_velocity / 1000.0f * 60.0f, 1) + DISTANCE_UNIT_1K + "/min");

        // If the target is a ship, show basic information about it.
        if (ship)
        {
            // On a simple scan or deeper, populate the faction, ship type, shields,
            // and hull integrity.
            if (ship->getScannedStateFor(my_spaceship) >= SS_SimpleScan)
            {
                target_faction->setValue(factionInfo[obj->getFactionId()]->getLocaleName());
                target_type->setValue(ship->getTypeName());
                target_shields->setValue(ship->getShieldDataString());
                target_hull->setValue(int(ceil(ship->getHull())));
            }
        }
        // If the target isn't a ship, show basic info.
        else
        {
            // If the target is a station, populate tactical info.
            if (station)
            {
                target_type->setValue(station->template_name);
                target_shields->setValue(station->getShieldDataString());
                target_hull->setValue(int(ceil(station->getHull())));
            }

            // Populate faction. (Does this need validation?)
            target_faction->setValue(factionInfo[obj->getFactionId()]->getLocaleName());
        }
    }
    // If the target is a waypoint, show its bearing and distance, and our
    // velocity toward it.
    else if (targets.getWaypointIndex() >= 0 && my_spaceship)
    {
        sf::Vector2f position_diff = my_spaceship->waypoints[targets.getWaypointIndex()] - my_spaceship->getPosition();
        float distance = sf::length(position_diff);
        float bearing = sf::vector2ToAngle(position_diff) - 270;

        // Limit its bearing value.
        while (bearing < 0)
        {
            bearing += 360;
        }

        float rel_velocity = -dot(my_spaceship->getVelocity(), position_diff / distance);

        if (fabs(rel_velocity) < 0.01)
        {
            rel_velocity = 0.0;
        }

        target_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);
        target_bearing->setValue(string(int(bearing)));
        target_relspeed->setValue(string(rel_velocity / 1000.0f * 60.0f, 1) + DISTANCE_UNIT_1K + "/min");
    }
}