--[[ Corvettes

Corvettes are small multirole ships that operate as escorts, pickets,
or patrol vessels. They are smaller and less well-armed than frigates, and
usually have no more than 2 shield segments.
]]

-- Nautilus (PlayerControl ship)
local template = ShipTemplate()
    :setName("Nautilus")
    :setLocaleName(_("playerShip", "Nautilus"))
    :setType("playership")
    :setClass(_("class", "Corvette"), _("subclass", "Mine layer"))
    :setModel("space_tug")
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[The Nautilus is a mine-laying corvette with minimal armament, shields, energy storage, and hull. While not particularly fast or capable, its triple rear-facing weapon tubes, combat thrusters, and surprising acceleration allow it to efficiently blanket an area with up to a dozen mines before resupplying.

Point-defense beams grant it a modicum of self-defense, but a Nautilus largely relies on its manueverability and supporting forces to survive direct combat.]]
        )
    )
    :setHull(55)
    :setShields(35, 35)
    :setSpeed(55, 25, 25)
    :setBeam(0, 10, 35, 1000.0, 6.0, 6)
    :setBeam(1, 10, -35, 1000.0, 6.0, 6)
    :setBeamWeaponTurret(0, 90, 35, 6)
    :setBeamWeaponTurret(1, 90, -35, 6)
    :setEnergyStorage(500)
    :setCombatManeuver(250, 150)
    :setTubes(3, 10.0)
    :setTubeDirection(0, 180)
    :setTubeDirection(1, 180)
    :setTubeDirection(2, 180)
    :setWeaponStorage("Mine", 12)
    :setRepairCrewCount(4)
    :addRoomSystem(0, 1, 1, 2, "Impulse")
    :addRoomSystem(1, 0, 2, 1, "RearShield")
    :addRoomSystem(1, 1, 2, 2, "JumpDrive")
    :addRoomSystem(1, 3, 2, 1, "FrontShield")
    :addRoomSystem(3, 0, 2, 1, "Beamweapons")
    :addRoomSystem(3, 1, 3, 1, "Warp")
    :addRoomSystem(3, 2, 3, 1, "Reactor")
    :addRoomSystem(3, 3, 2, 1, "MissileSystem")
    :addRoomSystem(6, 1, 1, 2, "Maneuver")
    :addRoomSystem(0, 0, 1, 1, "Sensors")
    :addDoor(1, 0, false)
    :addDoor(1, 1, false)
    :addDoor(2, 1, true)
    :addDoor(1, 3, true)
    :addDoor(3, 2, false)
    :addDoor(4, 3, true)
    :addDoor(6, 1, false)
    :addDoor(4, 2, true)
    :addDoor(4, 1, true)

-- Karnack
template = ShipTemplate()
    :setName("Karnack")
    :setLocaleName(_("ship", "Karnack"))
    :setModel("small_frigate_4")
    :setClass(_("class", "Corvette"), _("subclass", "Patrol"))
    :setRadarTrace("cruiser.png")
    :setDescription(
        _(
            [[Due to its versatility, the Karnack design has found wide adoptation across factions. Most have extensively retrofitted these older Repulse shipyards-fabricated patrol corvettes to suit their combat doctrines.

Due to the design's age, most factions procure stripped-down versions, a practice that's led to the Karnack becoming a favorite among smugglers and other civilian parties to refit them with (often illegal) weaponry.]]
        )
    )
    :setBeam(0, 60, -15, 1000.0, 6.0, 6)
    :setBeam(1, 60, 15, 1000.0, 6.0, 6)
    :setHull(60)
    :setShields(40, 40)
    :setSpeed(60, 6, 10)

-- Karnack MK2
variation = template
    :copy("Karnack MK2")
    :setLocaleName(_("ship", "Karnack MK2"))
variation:setDescription(
        _(
            [[The successor to the widely successful Karnack corvette, the mark 2 has several notable improvements over the original ship, including better armor, slightly improved weaponry, and customization by the shipyards. The latter improvement was the most requested feature by several factions once they realized that their old surplus mark I ships were used for less savory purposes.]]
        )
    )
    :setBeam(0, 90, -15, 1000.0, 6.0, 6)
    :setBeam(1, 90, 15, 1000.0, 6.0, 6)
    :setHull(70)

-- Polaris
template = ShipTemplate()
    :setName("Polaris")
    :setLocaleName(_("ship", "Polaris"))
    :setModel("space_cruiser_4")
    :setClass(_("class", "Corvette"), _("subclass", "Missile"))
    :setRadarTrace("missile_cruiser.png")
    :setDescription(
        _(
            [[The Polaris missile corvette is a platform for launching long-range missiles. It can't take much damage, but it can deal a lot if not dealt with quickly. Its single shield segment and lack of point-defense beam weapons leave it vulnerable to being swarmed by starfighters that can evade its missiles.]]
        )
    )
    :setTubes(1, 25.0)
    :setHull(40)
    :setShields(60)
    :setSpeed(45, 3, 10)
    :setWeaponStorage("Homing", 10)

-- Gunship
template = ShipTemplate()
    :setName("Gunship")
    :setLocaleName(_("ship", "Gunship"))
    :setModel("battleship_destroyer_4_upgraded")
    :setClass(_("class", "Corvette"), _("subclass", "Gunship"))
    :setRadarTrace("adv_gunship.png")
    :setDescription(
        _(
            [[The plainly named Gunship corvette is equipped with a homing missile tube damage a target at range, and dual front-firing beams to finish the target off. It's designed to quickly take out enemies weaker then itself.]]
        )
    )
    --                  Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 50, -15, 1000.0, 6.0, 8)
template:setBeam(1, 50, 15, 1000.0, 6.0, 8)
template:setTubes(1, 8.0)
template:setHull(100)
template:setShields(100, 80, 80)
template:setSpeed(60, 5, 10)
template:setWeaponStorage("Homing", 4)

-- Adv. Gunship
variation = template
    :copy("Adv. Gunship")
    :setLocaleName(_("ship", "Adv. Gunship"))
variation:setDescription(
        _(
            [[The Advanced Gunship corvette adds a second homing missile tube to damage targets at range, and dual front-firing beams to finish its foes off. It's designed to quickly take out enemies weaker then itself.]]
        )
    )
    :setTubes(2, 8.0)
