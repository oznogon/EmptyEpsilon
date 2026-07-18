--[[               Ktlitan Destroyers
The largest dedicated combat vessels in the Ktlitan swarm.
Heavily armored and armed with beam weapons and homing missiles.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Destroyer")
    :setLocaleName(_("ship", "Ktlitan Destroyer"))
    :setClass(_("class", "Destroyer"), _("subclass", "Assault"))
    :setModel("sci_fi_alien_ship_7")
template:setRadarTrace("ktlitan_destroyer.png")
template:setBeam(0, 90, -15, 1000.0, 6.0, 10)
template:setBeam(1, 90, 15, 1000.0, 6.0, 10)
template:setHull(300)
template:setShields(50, 50, 50)
template:setTubes(3, 15.0)
template:setSpeed(70, 5, 10)
template:setWeaponStorage("Homing", 25)
template:setDefaultAI("missilevolley")
