--[[               Ktlitan Battleships
The largest Ktlitan vessels. The Queen serves as both a command
ship and a mobile hive, directing the swarm in battle.
----------------------------------------------------------]]

-- Ktlitan Queen
local template = ShipTemplate()
    :setName("Ktlitan Queen")
    :setLocaleName(_("ship", "Ktlitan Queen"))
    :setClass(_("class", "Battleship"), _("subclass", "Command"))
    :setModel("sci_fi_alien_ship_8")
    :setRadarTrace("ktlitan_queen.png")
    :setHull(350)
    :setShields(100, 100, 100)
    :setTubes(2, 15.0)
    :setWeaponStorage("Nuke", 5)
    :setWeaponStorage("EMP", 5)
    :setWeaponStorage("Homing", 5)
