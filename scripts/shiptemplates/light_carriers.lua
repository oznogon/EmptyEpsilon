--[[                  Light Carriers
Light carriers are small to medium vessels designed to carry, deploy,
and support starfighters and other small craft. They are typically
equipped with docking facilities and supplies to sustain small strike
groups on extended deployments.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Saipan")
    :setLocaleName(_("playerShip", "Saipan"))
    :setModel("battleship_destroyer_5_upgraded")
    :setType("playership")
    :setClass(_("class", "Light Carrier"), _("subclass", "Escort"))
template:setDescription(
    _(
        [[The Saipan mixes most of the strengths of the corvette class with carrier capability. Its weapons compare favorably with other corvette class ships. Having fighters use the Saipan as a base can really ruin an enemy's day.]]
    )
)
template:setRadarTrace("cruiser.png")
template:setHull(180)
template:setShields(90, 90)
template:setSpeed(80, 10, 20)
template:setJumpDrive(true)
template:setCombatManeuver(400, 250)
template:setExternalDockClasses(_("class", "Frigate"))
template:setInternalDockClasses(_("class", "Starfighter"), _("class", "Cargo"))
template:setSharesEnergyWithDocked(false)
template:setRepairDocked(true)
template:setRestocksScanProbes(false)
template:setRestocksMissilesDocked(true)
--                  Arc, Dir,  Range, CycleTime, Dmg
template:setBeam(0, 120, -40, 1000.0, 6.0, 6)
template:setBeam(1, 120, 40, 1000.0, 6.0, 6)
template:setBeam(2, 10, 180, 800.0, 6.0, 4)
--                                Arc, Dir, Rotate speed
template:setBeamWeaponTurret(2, 60, 180, 0.5)
template:setTubes(5, 8.0)
template
    :setTubeDirection(0, 0)
    :setTubeSize(0, "small")
    :setTubeLoadTime(0, 6)
    :setWeaponTubeExclusiveFor(0, "HVLI")
template
    :setTubeDirection(1, 0)
    :setTubeSize(1, "medium")
    :setTubeLoadTime(1, 8)
    :weaponTubeDisallowMissle(1, "Mine")
template
    :setTubeDirection(2, -90)
    :setTubeSize(2, "large")
    :setTubeLoadTime(2, 12)
    :setWeaponTubeExclusiveFor(2, "HVLI")
    :weaponTubeAllowMissle(2, "Homing")
template
    :setTubeDirection(3, 90)
    :setTubeSize(3, "large")
    :setTubeLoadTime(3, 12)
    :setWeaponTubeExclusiveFor(3, "HVLI")
    :weaponTubeAllowMissle(3, "Homing")
template
    :setTubeDirection(4, 180)
    :setTubeSize(4, "medium")
    :setTubeLoadTime(4, 10)
    :setWeaponTubeExclusiveFor(4, "Mine")
template:setWeaponStorage("Homing", 8)
template:setWeaponStorage("Nuke", 4)
template:setWeaponStorage("Mine", 6)
template:setWeaponStorage("EMP", 6)
template:setWeaponStorage("HVLI", 16)

template:setRepairCrewCount(5)
--                      HC,VC,HS,VS, system
template:addRoomSystem(0, 0, 4, 1, "Maneuver")
template:addRoomSystem(1, 1, 2, 2, "Impulse")
template:addRoomSystem(3, 2, 3, 1, "Warp")
template:addRoomSystem(6, 2, 2, 1, "BeamWeapons")
template:addRoomSystem(2, 3, 2, 2, "JumpDrive")
template:addRoomSystem(7, 3, 3, 2, "FrontShield")
template:addRoomSystem(1, 5, 2, 2, "Reactor")
template:addRoomSystem(3, 5, 3, 1, "MissileSystem")
template:addRoomSystem(6, 5, 2, 1, "DockingBay")
template:addRoomSystem(0, 7, 4, 1, "RearShield")
--                HC,VC, true = horizontal door, false = vertical door
template:addDoor(1, 1, true)
template:addDoor(2, 3, true)
template:addDoor(3, 3, true)
template:addDoor(6, 2, false)
template:addDoor(7, 3, true)
template:addDoor(2, 5, true)
template:addDoor(3, 5, true)
template:addDoor(6, 5, false)
template:addDoor(7, 5, true)
template:addDoor(1, 7, true)
