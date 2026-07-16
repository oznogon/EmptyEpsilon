--[[               Ktlitan Battleships
The largest Ktlitan vessels. The Queen serves as both a command
ship and a mobile hive, directing the swarm in battle.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ktlitan Queen")
    :setLocaleName(_("ship", "Ktlitan Queen"))
    :setClass(_("class", "Battleship"), _("subclass", "Command"))
    :setModel("sci_fi_alien_ship_8")
template:setRadarTrace("ktlitan_queen.png")
template:setHull(350)
template:setShields(100, 100, 100)
template:setTubes(2, 15.0)
template:setWeaponStorage("Nuke", 5)
template:setWeaponStorage("EMP", 5)
template:setWeaponStorage("Homing", 5)
