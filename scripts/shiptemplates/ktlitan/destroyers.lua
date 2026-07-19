--[[               Ktlitan Destroyers
The largest dedicated combat vessels in the Ktlitan swarm.
Heavily armored and armed with beam weapons and homing missiles.
----------------------------------------------------------]]

-- Ktlitan Destroyer
local template = ShipTemplate()
    :setName("Ktlitan Destroyer")
    :setLocaleName(_("ship", "Ktlitan Destroyer"))
    :setClass(_("class", "Destroyer"), _("subclass", "Assault"))
    :setModel("sci_fi_alien_ship_7")
    :setRadarTrace("ktlitan_destroyer.png")
    :setBeam(0, 90, -15, 1000.0, 6.0, 10)
    :setBeam(1, 90, 15, 1000.0, 6.0, 10)
    :setHull(300)
    :setShields(50, 50, 50)
    :setTubes(3, 15.0)
    :setSpeed(70, 5, 10)
    :setWeaponStorage("Homing", 25)
    :setDefaultAI("missilevolley")
