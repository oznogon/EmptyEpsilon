--[[ Frigates

Frigates are generally larger than corvettes and smaller than destroyers, with 2 to 4 shield segments.

This class of vessel often lacks FTL propulsion unless specialized for a role that requires it.

Frigates come in the following subclasses:

- Patrol: Self-sufficient ships that use their sensors to detect threats and
  either engage or call in larger reinforcements.
- Anti-fighter: Escort frigates with point-defense beams to clear the area
  around larger ships or convoys of missile and starfighter threats.
- Artillery: Missile batteries that engage at long range, but often rely on
  other ships for defensive support.
- Sniper: Uses a long-range beam weapon to quickly burn down less-mobile
  targets.
- Strike: Uses FTL propulsion to quickly strike a target and retreat.
]]

-- Phobos T3
local template = ShipTemplate()
    :setName("Phobos T3")
    :setLocaleName(_("ship", "Phobos T3"))
    :setClass(_("class", "Frigate"), _("subclass", "Patrol"))
    :setModel("AtlasHeavyFighterYellow")
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[The Phobos T3 is the workhorse of almost any navy. Its basic stats aren't impressive, but its modular nature makes it easy to rapidly manufacture it in large quantities and modify it for a variety of mission profiles.]]
        )
    )
    :setHull(70)
    :setShields(50, 40)
    :setSpeed(60, 10, 10)
    :setBeamWeapon(0, 90, -15, 1200, 8, 6)
    :setBeamWeapon(1, 90, 15, 1200, 8, 6)
    :setTubes(2, 60.0)
    :setWeaponStorage("HVLI", 20)
    :setWeaponStorage("Homing", 6)
    :setTubeDirection(0, -1)
    :setTubeDirection(1, 1)

-- Elara P2
local variation = template
    :copy("Elara P2")
    :setLocaleName(_("ship", "Elara P2"))
variation
    :setDescription(
        _(
            [[Inspired by the Phobos T3's design, the Elara P2 adds a warp drive and stronger front shields.]]
        )
    )
    :setWarpSpeed(800)
    :setShields(70, 40)

-- Phobos M3
variation = template
    :copy("Phobos M3")
    :setLocaleName(_("ship", "Phobos M3"))
    :setModel("AtlasHeavyFighterRed")
variation
    :setDescription(
        _(
            [[The Phobos M3 is one of the most common variants of the Phobos T3. It adds a mine-laying tube, but the extra storage required for the mines slows this ship down slightly.]]
        )
    )
    :setTubes(3, 60.0)
    :setWeaponStorage("Mine", 6)
    :setSpeed(55, 10, 10)
    :weaponTubeDisallowMissle(0, "Mine")
    :weaponTubeDisallowMissle(1, "Mine")
    :setTubeDirection(0, -1)
    :setTubeDirection(1, 1)
    :setTubeDirection(2, 180)
    :setWeaponTubeExclusiveFor(2, "Mine")

-- Phobos M3P (PlayerControl variant)
variation = variation
    :copy("Phobos M3P")
    :setLocaleName(_("playerShip", "Phobos M3P"))
    :setType("playership")
variation
    :setDescription(
        _(
            [[This variant of the Phobos M3 has front-firing weapon tubes, making it an easier-to-use ship in some scenarios.]]
        )
    )
    :setShields(100, 100)
    :setHull(200)
    :setSpeed(80, 10, 20)
    :setCombatManeuver(400, 250)
    :setTubes(3, 10.0)
    :setWeaponStorage("Homing", 10)
    :setWeaponStorage("Nuke", 2)
    :setWeaponStorage("Mine", 4)
    :setWeaponStorage("EMP", 3)
    :addRoomSystem(1, 0, 2, 1, "Maneuver")
    :addRoomSystem(1, 1, 2, 1, "BeamWeapons")
    :addRoomSystem(2, 2, 2, 1, "DockingBay")
    :addRoomSystem(0, 3, 1, 2, "RearShield")
    :addRoomSystem(1, 3, 2, 2, "Reactor")
    :addRoomSystem(3, 3, 2, 2, "Warp")
    :addRoomSystem(5, 3, 1, 2, "JumpDrive")
    :addRoom(6, 3, 2, 1)
    :addRoom(6, 4, 2, 1)
    :addRoomSystem(8, 3, 1, 2, "FrontShield")
    :addRoom(2, 5, 2, 1)
    :addRoomSystem(1, 6, 2, 1, "MissileSystem")
    :addRoomSystem(1, 7, 2, 1, "Impulse")
    :addDoor(1, 1, true)
    :addDoor(2, 2, true)
    :addDoor(3, 3, true)
    :addDoor(1, 3, false)
    :addDoor(3, 4, false)
    :addDoor(3, 5, true)
    :addDoor(2, 6, true)
    :addDoor(1, 7, true)
    :addDoor(5, 3, false)
    :addDoor(6, 3, false)
    :addDoor(6, 4, false)
    :addDoor(8, 3, false)
    :addDoor(8, 4, false)
--Airlock doors
--variation:addDoor(2, 2, false);
--variation:addDoor(2, 5, false);

-- Nirvana R5
template = ShipTemplate()
    :setName("Nirvana R5")
    :setLocaleName(_("ship", "Nirvana R5"))
    :setClass(_("class", "Frigate"), _("subclass", "Anti-fighter"))
    :setModel("small_frigate_5") -- TODO: Better 3D model selection
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[The Nirvana series of anti-fighter frigates have several rapid-firing, low-damage point-defense weapons to quickly take out starfighters.]]
        ) .. " " .. _(
            [[Compared to the older, rarer Nirvana R3, it has longer beam range, stronger shields and hull, and a faster impulse drive. Its successor, the R5A, has a faster turning speed and firing rates.]]
        )
    )
    :setBeamWeapon(0, 90, -15, 1200, 3, 1)
    :setBeamWeapon(1, 90, 15, 1200, 3, 1)
    :setBeamWeapon(2, 90, 50, 1200, 3, 1)
    :setBeamWeapon(3, 90, -50, 1200, 3, 1)
    :setHull(70)
    :setShields(50, 40)
    :setSpeed(70, 12, 10)

-- Nirvana R5A
variation = template
    :copy("Nirvana R5A")
    :setLocaleName(_("ship", "Nirvana R5A"))
variation
    :setDescription(
        _(
            [[The Nirvana series of anti-fighter frigates have several rapid-firing, low-damage point-defense weapons to quickly take out starfighters.]]
        ) .. " " .. _(
            [[This improved version of the Nirvana R5 has a faster turning speed and firing rates.]]
        )
    )
    :setBeamWeapon(0, 90, -15, 1200, 2.9, 1)
    :setBeamWeapon(1, 90, 15, 1200, 2.9, 1)
    :setBeamWeapon(2, 90, 50, 1200, 2.9, 1)
    :setBeamWeapon(3, 90, -50, 1200, 2.9, 1)
    :setSpeed(70, 15, 10)

-- Nirvana R3
variation = template
    :copy("Nirvana R3")
    :setLocaleName(_("ship", "Nirvana R3"))
variation
    :setDescription(
        _(
            [[The Nirvana series of anti-fighter frigates have several rapid-firing, low-damage point-defense weapons to quickly take out starfighters.]]
        ) .. " " .. _(
            [[Compared to the newer, more common Nirvana R5, it has shorter beams, weaker shields and hull, and a slower impulse drive.]]
        )
    )
    :setBeamWeapon(0, 90, -15, 1000.0, 3, 1)
    :setBeamWeapon(1, 90, 15, 1000.0, 3, 1)
    :setBeamWeapon(2, 90, -50, 1000.0, 3, 1)
    :setBeamWeapon(3, 90, 50, 1000.0, 3, 1)
    :setHull(60)
    :setShields(40, 30)
    :setSpeed(65, 12, 10)

-- Storm
template = ShipTemplate()
    :setName("Storm")
    :setLocaleName(_("ship", "Storm"))
    :setClass(_("class", "Frigate"), _("subclass", "Artillery"))
    :setModel("HeavyCorvetteYellow")
    :setRadarTrace("piranha.png")
    :setDescription(
    _(
        [[A heavy artillery frigate, the Storm fires volleys of missiles from forward-facing tubes.]]
    )
    )
    :setBeamWeapon(0, 60, 0, 1200, 3, 2)
    :setHull(50)
    :setShields(30, 30)
    :setSpeed(40, 6, 8)
    :setTubes(5, 15.0)
    :setWeaponStorage("HVLI", 15)
    :setWeaponStorage("Homing", 15)
    :setTubeDirection(0, 0)
    :setTubeDirection(1, -1)
    :setTubeDirection(2, 1)
    :setTubeDirection(3, -2)
    :setTubeDirection(4, 2)
    :setDefaultAI("missilevolley")

-- Hathcock (PlayerControl)
template = ShipTemplate()
    :setName("Hathcock")
    :setLocaleName(_("playerShip", "Hathcock"))
    :setClass(_("class", "Frigate"), _("subclass", "Sniper"))
    :setModel("HeavyCorvetteGreen")
    :setType("playership")
    :setRadarTrace("piranha.png")
    :setDescription(
        _(
            [[The Hathcock has a long-range beam weapon with a narrow arc, as well as point-defense beams and a versatile stock of broadside missiles. Agile for a frigate.]]
        )
    )
    :setBeamWeapon(0, 4, 0, 1400.0, 6.0, 4)
    :setBeamWeapon(1, 20, 0, 1200.0, 6.0, 4)
    :setBeamWeapon(2, 60, 0, 1000.0, 6.0, 4)
    :setBeamWeapon(3, 90, 0, 800.0, 6.0, 4)
    :setHull(120)
    :setShields(70, 70)
    :setSpeed(50, 15, 8)
    :setTubes(2, 15.0)
    :setCombatManeuver(200, 150)
    :setJumpDrive(true)
    :setWeaponStorage("HVLI", 8)
    :setWeaponStorage("Homing", 4)
    :setWeaponStorage("EMP", 2)
    :setWeaponStorage("Nuke", 1)
    :setTubeDirection(0, -90)
    :setTubeDirection(1, 90)
    :setRepairCrewCount(2)
    :addRoomSystem(0, 0, 1, 4, "Reactor")
    :addRoomSystem(1, 0, 1, 1, "JumpDrive")
    :addRoomSystem(1, 3, 1, 1, "Warp")
    :addRoomSystem(2, 0, 1, 1, "FrontShield")
    :addRoomSystem(2, 3, 1, 1, "RearShield")
    :addRoomSystem(3, 0, 1, 1, "MissileSystem")
    :addRoomSystem(3, 3, 1, 1, "Impulse")
    :addRoomSystem(3, 1, 2, 1, "Maneuver")
    :addRoomSystem(3, 2, 2, 1, "DockingBay")
    :addRoomSystem(5, 1, 2, 2, "Beamweapons")
    :addDoor(1, 0, false)
    :addDoor(1, 3, false)
    :addDoor(2, 0, false)
    :addDoor(2, 3, false)
    :addDoor(3, 0, false)
    :addDoor(3, 3, false)
    :addDoor(3, 3, true)
    :addDoor(3, 2, true)
    :addDoor(5, 1, false)

-- Piranha F12
template = ShipTemplate()
    :setName("Piranha F12")
    :setLocaleName(_("ship", "Piranha F12"))
    :setClass(_("class", "Frigate"), _("subclass", "Artillery"))
    :setModel("HeavyCorvetteRed")
    :setRadarTrace("piranha.png")
    :setDescription(
        _(
            [[A light artillery frigate, the Piranha F12 is the smallest ship to fire exclusively from broadside weapon tubes.]]
        )
    )
    :setHull(70)
    :setShields(30, 30)
    :setSpeed(40, 6, 8)
    :setTubes(6, 15.0)
    :setWeaponStorage("HVLI", 20)
    :setWeaponStorage("Homing", 6)
    :setTubeDirection(0, -90)
    :setWeaponTubeExclusiveFor(0, "HVLI")
    :setTubeDirection(1, -90)
    :setTubeDirection(2, -90)
    :setWeaponTubeExclusiveFor(2, "HVLI")
    :setTubeDirection(3, 90)
    :setWeaponTubeExclusiveFor(3, "HVLI")
    :setTubeDirection(4, 90)
    :setTubeDirection(5, 90)
    :setWeaponTubeExclusiveFor(5, "HVLI")
    :setTubeSize(0, "large")
    :setTubeSize(2, "large")
    :setTubeSize(3, "large")
    :setTubeSize(5, "large")

-- Piranha F12.M
variation = template
    :copy("Piranha F12.M")
    :setLocaleName(_("ship", "Piranha F12.M"))
variation
    :setDescription(
        _(
            [[This Piranha F12 variant has specially modified weapon tubes that allow it to fire nukes in addition to its normal loadout. However, these changes reduce its overall missile storage capacity.]]
        )
    )
    :setWeaponStorage("HVLI", 10)
    :setWeaponStorage("Homing", 4)
    :setWeaponStorage("Nuke", 2)

-- Piranha (PlayerControl F12 variant)
variation = template
    :copy("Piranha")
    :setLocaleName(_("playerShip", "Piranha"))
    :setType("playership")
    :setClass(_("class", "Frigate"), _("subclass", "Assault"))
variation
    :setDescription(
        _(
            [[This combat-specialized Piranha F12 adds mine-laying tubes, combat maneuvering systems, and a jump drive.]]
        )
    )
    :setHull(120)
    :setShields(70, 70)
    :setSpeed(60, 10, 8)
    :setTubes(8, 8.0)
    :setCombatManeuver(200, 150)
    :setJumpDrive(true)
    :setWeaponStorage("HVLI", 20)
    :setWeaponStorage("Homing", 12)
    :setWeaponStorage("Nuke", 6)
    :setWeaponStorage("Mine", 8)
    :weaponTubeAllowMissle(0, "Homing")
    :weaponTubeAllowMissle(2, "Homing")
    :weaponTubeAllowMissle(3, "Homing")
    :weaponTubeAllowMissle(5, "Homing")
    :setTubeDirection(6, 170)
    :setWeaponTubeExclusiveFor(6, "Mine")
    :setTubeDirection(7, 190)
    :setWeaponTubeExclusiveFor(7, "Mine")
    :setRepairCrewCount(2)
    :addRoomSystem(0, 0, 1, 4, "RearShield")
    :addRoomSystem(1, 0, 1, 1, "DockingBay")
    :addRoomSystem(1, 1, 3, 2, "MissileSystem")
    :addRoom(1, 3, 1, 1)
    :addRoomSystem(2, 0, 2, 1, "Beamweapons")
    :addRoomSystem(2, 3, 2, 1, "Maneuver")
    :addRoomSystem(4, 0, 2, 1, "Warp")
    :addRoomSystem(4, 3, 2, 1, "JumpDrive")
    :addRoomSystem(5, 1, 1, 2, "Reactor")
    :addRoom(6, 0, 1, 1)
    :addRoomSystem(6, 1, 1, 2, "Impulse")
    :addRoom(6, 3, 1, 1)
    :addRoomSystem(7, 0, 1, 4, "FrontShield")
    :addDoor(1, 0, false)
    :addDoor(2, 0, false)
    :addDoor(4, 0, false)
    :addDoor(6, 0, false)
    :addDoor(7, 0, false)
    :addDoor(1, 1, true)
    :addDoor(1, 3, true)
    :addDoor(6, 1, true)
    :addDoor(6, 2, false)
    :addDoor(6, 3, true)
    :addDoor(1, 3, false)
    :addDoor(2, 3, false)
    :addDoor(4, 3, false)
    :addDoor(6, 3, false)
    :addDoor(7, 3, false)

-- Piranha F8
variation = template
    :copy("Piranha F8")
    :setLocaleName(_("ship", "Piranha F8"))
variation
    :setDescription(
        _(
            [[The first version of the Piranha wasn't popular due to its meager firepower and odd tube configuration. The result was a huge financial failure.]]
        )
    )
    :setTubes(3, 12.0)
    :setWeaponStorage("HVLI", 10)
    :setWeaponStorage("Homing", 5)
    :setTubeDirection(0, 0)
    :setWeaponTubeExclusiveFor(0, "HVLI")
    :setTubeDirection(1, -90)
    :setTubeDirection(2, 90)

-- Stalker Q7
template = ShipTemplate()
    :setName("Stalker Q7")
    :setLocaleName(_("ship", "Stalker Q7"))
    :setClass(_("class", "Frigate"), _("subclass", "Strike"))
    :setModel("small_frigate_3")
template
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[Ships of the Stalker line are designed to swoop into battle, deal damage quickly, and get out fast.]]
        ) .. " " .. _(
            [[The Q series is fitted with a warp drive.]]
        ) .. " " .. _(
            [[Compared to its predecessor, the Q5, the Q7 has stronger shields and hull but a slower turning rate.]]
        )
    )
    :setHull(50)
    :setShields(80, 30, 30, 30)
    :setSpeed(70, 12, 12)
    :setWarpSpeed(700)
    :setBeam(0, 40, -5, 1000.0, 6.0, 6)
    :setBeam(1, 40, 5, 1000.0, 6.0, 6)

-- Stalker Q5
variation = template
    :copy("Stalker Q5")
    :setLocaleName(_("ship", "Stalker Q5"))
variation
    :setDescription(
        _(
            [[Ships of the Stalker line are designed to swoop into battle, deal damage quickly, and get out fast.]]
        ) .. " " .. _(
            [[The Q series is fitted with a warp drive.]]
        ) .. " " .. _(
            [[Compared to its successor, the Q7, the Q5 has weaker shields and hull but a faster turning rate.]]
        )
    )
    :setHull(45)
    :setShields(50, 50)
    :setSpeed(70, 15, 12)

-- Stalker R7
variation = template
    :copy("Stalker R7")
    :setLocaleName(_("ship", "Stalker R7"))
variation
    :setDescription(
        _(
            [[Ships of the Stalker line are designed to swoop into battle, deal damage quickly, and get out fast.]]
        ) .. " " .. _(
            [[The R series is fitted with a jump drive.]]
        ) .. " " .. _(
            [[Compared to its predecessor, the R5, the R7 has stronger shields and hull but a slower turning rate.]]
        )
    )
    :setWarpSpeed(0)
    :setJumpDrive(true)

-- Stalker R5
var2 = variation
    :copy("Stalker R5")
    :setLocaleName(_("ship", "Stalker R5"))
var2
    :setDescription(
        _(
            [[Ships of the Stalker line are designed to swoop into battle, deal damage quickly, and get out fast.]]
        ) .. " " .. _(
            [[The R series is fitted with a jump drive.]]
        ) .. " " .. _(
            [[Compared to its successor, the R7, the R5 has weaker shields and hull but a faster turning rate.]]
        )
    )
    :setHull(45)
    :setShields(50, 50)
    :setSpeed(70, 15, 12)

-- Ranus U
template = ShipTemplate()
    :setName("Ranus U")
    :setLocaleName(_("ship", "Ranus U"))
    :setClass(_("class", "Frigate"), _("subclass", "Sniper"))
    :setModel("MissileCorvetteGreen")
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[The Ranus U sniper is built to deal large amounts of damage quickly at distance before escaping. While it's the smallest frigate-class ship, it's also one of the only frigate models to carry nukes in its standard configuration.]]
        )
    )
    :setHull(30)
    :setShields(30, 5, 5)
    :setSpeed(50, 6, 20)
    :setTubes(3, 25.0)
    :weaponTubeDisallowMissle(1, "Nuke")
    :weaponTubeDisallowMissle(2, "Nuke")
    :setWeaponStorage("Homing", 6)
    :setWeaponStorage("Nuke", 2)

-- Fiend G3
template = ShipTemplate()
    :setName("Fiend G3")
    :setLocaleName(_("ship", "Fiend G3"))
    :setModel("battleship_destroyer_4_upgraded")
    :setClass(_("class", "Frigate"), _("subclass", "Strike"))
    :setRadarTrace("adv_gunship.png")
    :setDescription(
        _(
            [[The first model produced by Conversions R Us, the Fiend G3 is simply a decommissioned gunship hull with a cheap FTL drive installed. It has the same homing missile tube and beams as a gunship to take down weaker ships, but its FTL drive makes it a more dangerous foe.]]
        ) .. " " .. _(
            [[The G3 is fitted with a jump drive.]]
        )
    )
    :setBeam(0, 50, -15, 1000.0, 6.0, 8)
    :setBeam(1, 50, 15, 1000.0, 6.0, 8)
    :setTubes(1, 8.0)
    :setHull(100)
    :setShields(100, 80, 80)
    :setSpeed(60, 5, 10)
    :setWeaponStorage("Homing", 4)
    :setJumpDrive(true)
    :setJumpDriveRange(5000, 35000)

-- Fiend G4
variation = template
    :copy("Fiend G4")
    :setLocaleName(_("ship", "Fiend G4"))
variation
    :setDescription(
        _(
            [[The second model produced by Conversions R Us, the Fiend G4 is simply a decommissioned gunship hull with a cheap FTL drive installed. It has the same homing missile tube and beams as a gunship to take down weaker ships, but its FTL drive makes it a more dangerous foe.]]
        ) .. " " .. _(
            [[The G4 is fitted with a warp drive.]]
        )
    )
    :setJumpDrive(false)
    :setWarpSpeed(800)

-- Fiend G6
variation = variation
    :copy("Fiend G6")
    :setLocaleName(_("ship", "Fiend G6"))
variation
    :setDescription(
        _(
            [[Following the success of the Fiend G3 and G4, the Fiend G5 and G6 are simply decommissioned advanced gunship hulls with a cheap FTL drive installed. It has the same two homing missile tubes and beams as an advanced gunship to take down weaker ships, but its FTL drive makes it a more dangerous foe.]]
        ) .. " " .. _(
            [[The G6 is fitted with a warp drive.]]
        )
    )
    :setTubes(2, 8.0)

-- Fiend G5
variation = template
    :copy("Fiend G5")
    :setLocaleName(_("ship", "Fiend G5"))
variation
    :setDescription(
        _(
            [[Following the success of the Fiend G3 and G4, the Fiend G5 and G6 are simply decommissioned advanced gunship hulls with a cheap FTL drive installed. It has the same two homing missile tubes and beams as an advanced gunship to take down weaker ships, but its FTL drive makes it a more dangerous foe.]]
        ) .. " " .. _(
            [[The G6 is fitted with a jump drive.]]
        )
    )
    :setTubes(2, 8.0)

-- Blockade runner
template = ShipTemplate()
    :setName("Blockade Runner")
    :setLocaleName(_("ship", "Blockade Runner"))
    :setModel("battleship_destroyer_3_upgraded")
    :setClass(_("class", "Frigate"), _("subclass", "Assault"))
    :setRadarTrace("blockade.png")
    :setDescription(
        _(
            [[Blockade Runners are reasonably fast, highly shielded, slow-firing ships designed to break through defensive lines and deliver goods.]]
        )
    )
    :setBeam(0, 60, -15, 1000.0, 6.0, 8)
    :setBeam(1, 60, 15, 1000.0, 6.0, 8)
    :setBeam(2, 25, 170, 1000.0, 6.0, 8)
    :setBeam(3, 25, 190, 1000.0, 6.0, 8)
    :setHull(70)
    :setShields(100, 150)
    :setSpeed(60, 15, 25)

