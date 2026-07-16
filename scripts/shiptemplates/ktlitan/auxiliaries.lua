--[[               Ktlitan Auxiliaries
Non-combat Ktlitan vessels that perform support functions
such as construction, resource gathering, and repair.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Worker")
    :setLocaleName(_("ship", "Ktlitan Worker"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Support"))
    :setModel("sci_fi_alien_ship_3")
template:setRadarTrace("ktlitan_worker.png")
template:setBeam(0, 40, -90, 600.0, 4.0, 6)
template:setBeam(1, 40, 90, 600.0, 4.0, 6)
template:setHull(50)
template:setSpeed(100, 35, 25)
