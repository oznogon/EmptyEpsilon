--[[               Ktlitan Auxiliaries
Non-combat Ktlitan vessels that perform support functions
such as construction, resource gathering, and repair.
----------------------------------------------------------]]

-- Ktlitan Worker
local template = ShipTemplate()
    :setName("Ktlitan Worker")
    :setLocaleName(_("ship", "Ktlitan Worker"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Support"))
    :setModel("sci_fi_alien_ship_3")
    :setRadarTrace("ktlitan_worker.png")
    :setBeam(0, 40, -90, 600.0, 4.0, 6)
    :setBeam(1, 40, 90, 600.0, 4.0, 6)
    :setHull(50)
    :setSpeed(100, 35, 25)
