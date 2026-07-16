--[[               Ktlitan Frigates
Ktlitan vessels of frigate size — more durable than fighters,
these ships fill scout, assault, and skirmish roles.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Breaker")
    :setLocaleName(_("ship", "Ktlitan Breaker"))
    :setClass(_("class", "Frigate"), _("subclass", "Assault"))
    :setModel("sci_fi_alien_ship_2")
template:setRadarTrace("ktlitan_breaker.png")
template:setBeam(0, 40, 0, 800.0, 4.0, 6)
template:setBeam(1, 35, -15, 800.0, 4.0, 6)
template:setBeam(2, 35, 15, 800.0, 4.0, 6)
template:setTubes(1, 13.0)
template:setWeaponStorage("HVLI", 5)
template:setHull(120)
template:setSpeed(100, 5, 25)

template = ShipTemplate()
    :setName("Ktlitan Drone")
    :setLocaleName(_("ship", "Ktlitan Drone"))
    :setClass(_("class", "Frigate"), _("subclass", "Scout"))
    :setModel("sci_fi_alien_ship_4")
template:setRadarTrace("ktlitan_drone.png")
template:setBeam(0, 40, 0, 600.0, 4.0, 6)
template:setHull(30)
template:setSpeed(120, 10, 25)

template = ShipTemplate()
    :setName("Ktlitan Scout")
    :setLocaleName(_("ship", "Ktlitan Scout"))
    :setClass(_("class", "Frigate"), _("subclass", "Scout"))
    :setModel("sci_fi_alien_ship_6")
template:setRadarTrace("ktlitan_scout.png")
template:setBeam(0, 40, 0, 600.0, 4.0, 6)
template:setHull(100)
template:setSpeed(150, 30, 25)
