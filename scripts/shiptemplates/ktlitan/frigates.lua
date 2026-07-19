--[[               Ktlitan Frigates
Ktlitan vessels of frigate size — more durable than fighters,
these ships fill scout, assault, and skirmish roles.
----------------------------------------------------------]]

-- Ktlitan Breaker
local template = ShipTemplate()
    :setName("Ktlitan Breaker")
    :setLocaleName(_("ship", "Ktlitan Breaker"))
    :setClass(_("class", "Frigate"), _("subclass", "Assault"))
    :setModel("sci_fi_alien_ship_2")
    :setRadarTrace("ktlitan_breaker.png")
    :setBeam(0, 40, 0, 800.0, 4.0, 6)
    :setBeam(1, 35, -15, 800.0, 4.0, 6)
    :setBeam(2, 35, 15, 800.0, 4.0, 6)
    :setTubes(1, 13.0)
    :setWeaponStorage("HVLI", 5)
    :setHull(120)
    :setSpeed(100, 5, 25)

-- Ktlitan Drone
template = ShipTemplate()
    :setName("Ktlitan Drone")
    :setLocaleName(_("ship", "Ktlitan Drone"))
    :setClass(_("class", "Frigate"), _("subclass", "Scout"))
    :setModel("sci_fi_alien_ship_4")
    :setRadarTrace("ktlitan_drone.png")
    :setBeam(0, 40, 0, 600.0, 4.0, 6)
    :setHull(30)
    :setSpeed(120, 10, 25)

-- Ktlitan Scout
template = ShipTemplate()
    :setName("Ktlitan Scout")
    :setLocaleName(_("ship", "Ktlitan Scout"))
    :setClass(_("class", "Frigate"), _("subclass", "Scout"))
    :setModel("sci_fi_alien_ship_6")
    :setRadarTrace("ktlitan_scout.png")
    :setBeam(0, 40, 0, 600.0, 4.0, 6)
    :setHull(100)
    :setSpeed(150, 30, 25)
