--[[                  Corvettes
Corvettes are small multirole ships that operate as escorts, pickets,
or static defense platforms. They are smaller and less armed than
destroyers but more substantial than patrol boats.
----------------------------------------------------------]]

--[[-----------------------Support-----------------------]]

local template = ShipTemplate()
    :setName("Defense platform")
    :setLocaleName(_("ship", "Defense platform"))
    :setClass(_("class", "Corvette"), _("subclass", "Defense"))
    :setModel("space_station_4")
template:setDescription(
    _(
        [[This stationary defense platform operates like a station, with docking and resupply functions, but is armed with powerful beam weapons and can slowly rotate. Larger systems often use these platforms to resupply patrol ships.]]
    )
)
template:setRadarTrace("smallstation.png")
template:setHull(150)
template:setShields(120, 120, 120, 120, 120, 120)
template:setSpeed(0, 0.5, 0)
template:setDockClasses(_("class", "Starfighter"), _("class", "Frigate"))
--               Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 30, 0, 4000.0, 1.5, 20)
template:setBeam(1, 30, 60, 4000.0, 1.5, 20)
template:setBeam(2, 30, 120, 4000.0, 1.5, 20)
template:setBeam(3, 30, 180, 4000.0, 1.5, 20)
template:setBeam(4, 30, 240, 4000.0, 1.5, 20)
template:setBeam(5, 30, 300, 4000.0, 1.5, 20)
