--[[ Light carriers

Light carriers are small to medium vessels designed to carry, deploy, and
support starfighters and other small craft. They're typically equipped with
docking facilities and supplies to sustain small strike groups on extended
deployments.

Light carriers come in the following subclasses:

- Escort: Armed carriers capable of defending itself and its nearby launched
  fighters.
- Transport: Unarmed carriers that require escort ships or active starfighter
  patrols for defense.
]]

-- Saipan
local template = ShipTemplate()
    :setName("Saipan")
    :setLocaleName(_("playerShip", "Saipan"))
    :setModel("battleship_destroyer_5_upgraded")
    :setType("playership")
    :setClass(_("class", "Light carrier"), _("subclass", "Escort"))
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[The Saipan combines most of the strengths of the frigate class with the capability to carry and launch starfighters. Its weapons compare favorably with other frigate-class ships.]]
        )
    )
    :setHull(180)
    :setShields(90, 90)
    :setSpeed(80, 10, 20)
    :setJumpDrive(true)
    :setCombatManeuver(400, 250)
    :setExternalDockClasses(_("class", "Frigate"))
    :setInternalDockClasses(_("class", "Starfighter"), _("class", "Cargo"))
    :setSharesEnergyWithDocked(false)
    :setRepairDocked(true)
    :setRestocksScanProbes(false)
    :setRestocksMissilesDocked(true)
    :setBeam(0, 120, -40, 1000.0, 6.0, 6)
    :setBeam(1, 120, 40, 1000.0, 6.0, 6)
    :setBeam(2, 10, 180, 800.0, 6.0, 4)
    :setBeamWeaponTurret(2, 60, 180, 0.5)
    :setTubes(5, 8.0)
    :setTubeDirection(0, 0)
    :setTubeSize(0, "small")
    :setTubeLoadTime(0, 6)
    :setWeaponTubeExclusiveFor(0, "HVLI")
    :setTubeDirection(1, 0)
    :setTubeSize(1, "medium")
    :setTubeLoadTime(1, 8)
    :weaponTubeDisallowMissle(1, "Mine")
    :setTubeDirection(2, -90)
    :setTubeSize(2, "large")
    :setTubeLoadTime(2, 12)
    :setWeaponTubeExclusiveFor(2, "HVLI")
    :weaponTubeAllowMissle(2, "Homing")
    :setTubeDirection(3, 90)
    :setTubeSize(3, "large")
    :setTubeLoadTime(3, 12)
    :setWeaponTubeExclusiveFor(3, "HVLI")
    :weaponTubeAllowMissle(3, "Homing")
    :setTubeDirection(4, 180)
    :setTubeSize(4, "medium")
    :setTubeLoadTime(4, 10)
    :setWeaponTubeExclusiveFor(4, "Mine")
    :setWeaponStorage("Homing", 8)
    :setWeaponStorage("Nuke", 4)
    :setWeaponStorage("Mine", 6)
    :setWeaponStorage("EMP", 6)
    :setWeaponStorage("HVLI", 16)
    :setRepairCrewCount(5)
    :addRoomSystem(0, 0, 4, 1, "Maneuver")
    :addRoomSystem(1, 1, 2, 2, "Impulse")
    :addRoomSystem(3, 2, 3, 1, "Warp")
    :addRoomSystem(6, 2, 2, 1, "BeamWeapons")
    :addRoomSystem(2, 3, 2, 2, "JumpDrive")
    :addRoomSystem(7, 3, 3, 2, "FrontShield")
    :addRoomSystem(1, 5, 2, 2, "Reactor")
    :addRoomSystem(3, 5, 3, 1, "MissileSystem")
    :addRoomSystem(6, 5, 2, 1, "DockingBay")
    :addRoomSystem(0, 7, 4, 1, "RearShield")
    :addDoor(1, 1, true)
    :addDoor(2, 3, true)
    :addDoor(3, 3, true)
    :addDoor(6, 2, false)
    :addDoor(7, 3, true)
    :addDoor(2, 5, true)
    :addDoor(3, 5, true)
    :addDoor(6, 5, false)
    :addDoor(7, 5, true)
    :addDoor(1, 7, true)

-- Jump Carrier
template = ShipTemplate()
    :setName("Jump Carrier")
    :setLocaleName(_("ship", "Jump Carrier"))
    :setClass(_("class", "Light carrier"), _("subclass", "Transport"))
    :setModel("transport_4_2")
    :setRadarTrace("transport.png")
    :setDescription(
        _(
            [[The Jump Carrier is a freighter hull, but with a jump drive and energy storage in place of its cargo bay.]]
        ) .. " " .. _(
            [[It's designed to carry other ships deep into space, up to and including frigate-class hulls, and it accordingly has special docking parameters that allow ships too big to fit in its docking bay to attach themselves to its hull.]]
        )
    )
    :setHull(100)
    :setShields(50, 50)
    :setSpeed(50, 6, 10)
    :setJumpDrive(true)
    :setJumpDriveRange(5000, 100 * 50000)
    :setExternalDockClasses(_("class", "Frigate"), _("class", "Destroyer"))
    :setInternalDockClasses(_("class", "Starfighter"), _("class", "Cargo"))
    :setDefaultAI("evasion")

-- Benedict
local variation = template
    :copy("Benedict")
    :setLocaleName(_("playerShip", "Benedict"))
    :setClass(_("class", "Light carrier"), _("subclass", "Escort"))
    :setType("playership")
variation
    :setDescription(
        _(
            [[The Benedict is an improved version of the Jump Carrier armed with point-defense beam turrets.]]
        ) .. " " .. _(
            [[It's designed to carry other ships deep into space, up to and including frigate-class hulls, and it accordingly has special docking parameters that allow ships too big to fit in its docking bay to attach themselves to its hull.]]
        )
    )
    :setShields(70, 70)
    :setHull(200)
    :setSpeed(60, 6, 8)
    :setBeam(0, 10, 0, 1500.0, 6.0, 4)
    :setBeam(1, 10, 180, 1500.0, 6.0, 4)
    :setBeamWeaponTurret(0, 90, 0, 6)
    :setBeamWeaponTurret(1, 90, 180, 6)
    :setCombatManeuver(400, 250)
    :setJumpDriveRange(5000, 90000)
    :setRepairCrewCount(6)
    :addRoomSystem(3, 0, 2, 3, "Reactor")
    :addRoomSystem(3, 3, 2, 3, "Warp")
    :addRoomSystem(6, 0, 2, 3, "JumpDrive")
    :addRoomSystem(6, 3, 2, 3, "MissileSystem")
    :addRoomSystem(5, 2, 1, 2, "Maneuver")
    :addRoomSystem(2, 2, 1, 2, "RearShield")
    :addRoomSystem(0, 1, 2, 4, "Beamweapons")
    :addRoomSystem(8, 2, 1, 2, "FrontShield")
    :addRoomSystem(0, 0, 1, 1, "DockingBay")
    :addRoomSystem(9, 1, 2, 4, "Impulse")
    :addDoor(0, 1, true)
    :addDoor(3, 3, true)
    :addDoor(6, 3, true)
    :addDoor(5, 2, false)
    :addDoor(6, 3, false)
    :addDoor(3, 2, false)
    :addDoor(2, 3, false)
    :addDoor(8, 2, false)
    :addDoor(9, 3, false)

-- Kiriya
local var2 = variation
    :copy("Kiriya")
    :setLocaleName(_("playerShip", "Kiriya"))
var2
    :setDescription(
        _(
            [[The Kiriya is a warp-drive variant of the Benedict. Like the Benedict, it's armed with point-defense beam turrets.]]
        ) .. " " .. _(
            [[It's designed to carry other ships deep into space, up to and including frigate-class hulls, and it accordingly has special docking parameters that allow ships too big to fit in its docking bay to attach themselves to its hull.]]
        )
    )
    :setJumpDrive(false)
    :setWarpSpeed(750)