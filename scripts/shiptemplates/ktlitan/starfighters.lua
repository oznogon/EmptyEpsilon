--[[               Ktlitan Starfighters
Small, fast Ktlitan spacecraft that swarm around larger prey.
These are not naval ships; they are starfighters.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Fighter")
    :setLocaleName(_("ship", "Ktlitan Fighter"))
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
    :setModel("sci_fi_alien_ship_1")
template:setRadarTrace("ktlitan_fighter.png")
template:setBeam(0, 60, 0, 1200.0, 4.0, 6)
template:setHull(70)
template:setSpeed(140, 30, 25)
template:setDefaultAI("fighter")
