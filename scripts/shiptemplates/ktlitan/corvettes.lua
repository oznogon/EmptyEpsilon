--[[               Ktlitan Corvettes
Ktlitan vessels of corvette size — well-armed and durable,
often found in the thick of combat.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Feeder")
    :setLocaleName(_("ship", "Ktlitan Feeder"))
    :setClass(_("class", "Corvette"), _("subclass", "Assault"))
    :setModel("sci_fi_alien_ship_5")
template:setRadarTrace("ktlitan_feeder.png")
template:setBeam(0, 20, 0, 800.0, 4.0, 6)
template:setBeam(1, 35, -15, 600.0, 4.0, 6)
template:setBeam(2, 35, 15, 600.0, 4.0, 6)
template:setBeam(3, 20, -25, 600.0, 4.0, 6)
template:setBeam(4, 20, 25, 600.0, 4.0, 6)
template:setHull(150)
template:setSpeed(120, 8, 25)
