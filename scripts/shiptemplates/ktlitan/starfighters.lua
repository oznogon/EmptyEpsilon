--[[               Ktlitan Starfighters
Small, fast Ktlitan spacecraft that swarm around larger prey.
These are not naval ships; they are starfighters.
----------------------------------------------------------]]

-- Ktlitan Fighter
local template = ShipTemplate()
    :setName("Ktlitan Fighter")
    :setLocaleName(_("ship", "Ktlitan Fighter"))
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
    :setModel("sci_fi_alien_ship_1")
    :setRadarTrace("ktlitan_fighter.png")
    :setBeam(0, 60, 0, 1200.0, 4.0, 6)
    :setHull(70)
    :setSpeed(140, 30, 25)
    :setDefaultAI("fighter")
