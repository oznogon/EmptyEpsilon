--[[ Starfighter templates

Starfighters are small ships most commonly used in light firepower roles.

Fighters have crews of 1 to 3 and lack long-term life support for extended missions, requiring a nearby station or carrier. They're commonly deployed in larger groups, and most have a single shield segment and light armaments.

Starfighters come in 3 subclasses:

- Interceptors: Fast. Low on firepower, high on maneuverability.
- Gunship: Equipped with more weapons at the expense of maneuverability.
- Bomber: Slowest of all starfighters, but packs a larger punch. While typically lacking any beam weapons, larger bombers can deliver nukes.
]]

-- MT52 Hornet
local template = ShipTemplate()
    :setName("MT52 Hornet")
    :setLocaleName(_("ship", "MT52 Hornet"))
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
    :setModel("WespeScoutYellow")
    :setRadarTrace("fighter.png")
    :setDescription(
        _(
            [[The MT52 Hornet is a basic interceptor found in many corners of the galaxy. It's easy to find spare parts for MT52s, not only because they are produced in large numbers, but also because they suffer high losses in combat.]]
        )
    )
    :setHull(30)
    :setShields(20)
    :setSpeed(120, 30, 25)
    :setDefaultAI("fighter")
    :setBeam(0, 30, 0, 700.0, 4.0, 2)

-- MU52 Hornet
local variation = template
    :copy("MU52 Hornet")
    :setLocaleName(_("ship", "MU52 Hornet"))
    :setModel("WespeScoutRed")
    :setDescription(
        _(
            [[The MU52 Hornet is a new, upgraded version of the MT52. All of its systems are slightly improved over the MT52 model.]]
        )
    )
    :setHull(35)
    :setShields(22)
    :setSpeed(125, 32, 25)
    :setBeam(0, 30, 0, 900.0, 4.0, 2.5)

-- MP52 Hornet (PlayerControl variant)
variation = variation
    :copy("MP52 Hornet")
    :setLocaleName(_("playerShip", "MP52 Hornet"))
    :setType("playership")
    :setDescription(
        _(
            [[The MP52 Hornet is a significantly upgraded version of MU52 Hornet, with nearly twice the hull strength, nearly three times the shielding, better acceleration, impulse boosters, and a second laser cannon.]]
        )
    )
    :setImpulseSoundFile("sfx/engine_fighter.wav")
    :setHull(70)
    :setShields(60)
    :setSpeed(125, 32, 40)
    :setCombatManeuver(600, 0)
    :setBeam(0, 30, 5, 900.0, 4.0, 2.5)
    :setBeam(1, 30, -5, 900.0, 4.0, 2.5)
    :setEnergyStorage(400)
    :setRepairCrewCount(1)
    :addRoomSystem(3, 0, 1, 1, "Maneuver")
    :addRoomSystem(1, 0, 2, 1, "BeamWeapons")
    :addRoomSystem(0, 1, 1, 2, "RearShield")
    :addRoomSystem(1, 1, 2, 2, "Reactor")
    :addRoomSystem(3, 1, 2, 1, "Warp")
    :addRoomSystem(3, 2, 2, 1, "JumpDrive")
    :addRoomSystem(5, 1, 1, 2, "FrontShield")
    :addRoomSystem(1, 3, 2, 1, "MissileSystem")
    :addRoomSystem(3, 3, 1, 1, "Impulse")
    :addRoomSystem(0, 0, 1, 1, "DockingBay")
    :addDoor(1, 0, false)
    :addDoor(2, 1, true)
    :addDoor(3, 1, true)
    :addDoor(1, 1, false)
    :addDoor(3, 1, false)
    :addDoor(3, 2, false)
    :addDoor(3, 3, true)
    :addDoor(2, 3, true)
    :addDoor(5, 1, false)
    :addDoor(5, 2, false)

-- Adder MK5
template = ShipTemplate()
    :setName("Adder MK5")
    :setLocaleName(_("ship", "Adder MK5"))
    :setClass(_("class", "Starfighter"), _("subclass", "Gunship"))
    :setModel("AdlerLongRangeScoutYellow")
    :setRadarTrace("fighter.png")
    :setDescription(
        _(
            [[The Adder line's fifth iteration proved to be a great success among pirates and law officers alike. It is cheap, fast, and easy to maintain, and it packs a decent punch.]]
        )
    )
    :setHull(50)
    :setShields(30)
    :setSpeed(80, 28, 25)
    :setBeam(0, 35, 0, 800, 5.0, 2.0)
    :setBeam(1, 70, 30, 600, 5.0, 2.0)
    :setBeam(2, 70, -30, 600, 5.0, 2.0)
    :setTubes(1, 15.0)
    :setTubeSize(0, "small")
    :setWeaponStorage("HVLI", 4)

-- Adder MK4
variation = template
    :copy("Adder MK4")
    :setLocaleName(_("ship", "Adder MK4"))
    :setModel("AdlerLongRangeScoutBlue")
    :setDescription(
        _(
            [[The mark 4 Adder is a rare sight these days due to the success its successor, the mark 5 Adder, which often replaces this model. Its similar hull, however, means careless buyers are sometimes conned into buying mark 4 models disguised as the mark 5.]]
        )
    )
    :setHull(40)
    :setShields(20)
    :setSpeed(60, 20, 20)
    :setTubes(1, 20.0)
    :setTubeSize(0, "small")
    :setWeaponStorage("HVLI", 2)

-- Adder MK3
var2 = variation
    :copy("Adder MK3")
    :setLocaleName(_("ship", "Adder MK3"))
    :setDescription(
        _(
            [[The Adder MK3 is one of the first of the Adder line to meet with some success. A large number of them were made before the manufacturer went through its first bankruptcy. There has been a recent surge of purchases of the Adder MK3 in the secondary market due to its low price and its similarity to subsequent models. Compared to the Adder MK4, the Adder MK3 has weaker shields and hull, but a faster turn speed]]
        )
    )
    :setHull(35)
    :setShields(15)
    :setSpeed(60, 35, 20)

-- Adder MK6
variation = template
    :copy("Adder MK6")
    :setLocaleName(_("ship", "Adder MK6"))
    :setModel("AdlerLongRangeScoutRed")
    :setDescription(
        _(
            [[The mark 6 Adder is a small upgrade compared to the highly successful mark 5 model. Since people still prefer the more familiar and reliable mark 5, the mark 6 has not seen the same level of success.]]
        )
    )
    :setBeam(3, 35, 180, 600, 6.0, 2.0)
    :setWeaponStorage("HVLI", 8)

-- Adder MK7
var2 = variation
    :copy("Adder MK7")
    :setLocaleName(_("ship", "Adder MK7"))
    :setModel("AdlerLongRangeScoutGreen")
    :setDescription(
        _(
            [[The release of the Adder Mark 7 sent the manufacturer into a second bankruptcy. They made improvements to the Mark 7 over the Mark 6 like stronger shields and longer beams, but the popularity of their previous models, especially the Mark 5, prevented them from raising the purchase price enough to recoup the development and manufacturing costs of the Mark 7]]
        )
    )
    :setShields(40)
    :setBeam(0, 30, 0, 900, 5.0, 2.0)

-- Adder MK8
variation = template
    :copy("Adder MK8")
    :setLocaleName(_("ship", "Adder MK8"))
    :setModel("AdlerLongRangeScoutGreen")
    :setDescription(
        _(
            [[New management after bankruptcy revisited their most popular Adder Mark 5 model with improvements: stronger shields, longer and stronger beams and a faster turn speed. Thus was born the Adder Mark 8 model. Targeted to the practical but nostalgic buyer who must purchase replacements for their Adder Mark 5 fleet]]
        )
    )
    :setShields(50)
    :setSpeed(80, 30, 25)
    :setBeam(0, 30, 0, 900, 5.0, 2.3)

-- Adder MK9
variation = template
    :copy("Adder MK9")
    :setLocaleName(_("ship", "Adder MK9"))
    :setModel("AdlerLongRangeScoutRed")
    :setDescription(
        _(
            [[Hot on the heels of the Adder Mark 8 comes the Adder Mark 9. Still using the Adder Mark 5 as a base, the designers provided stronger shields, stronger, longer and faster beams, faster turn speed and for that extra special touch, two nuclear missiles. As their ad says, 'You'll feel better in an Adder Mark 9.']]
        )
    )
    :setShields(50)
    :setBeam(0, 30, 0, 900, 4.5, 2.5)
    :setSpeed(80, 30, 25)
    :setWeaponStorage("Nuke", 2)

-- WX-Lindworm
template = ShipTemplate()
    :setName("WX-Lindworm")
    :setLocaleName(_("ship", "WX-Lindworm"))
    :setClass(_("class", "Starfighter"), _("subclass", "Bomber"))
    :setModel("LindwurmFighterYellow")
    :setRadarTrace("fighter.png")
    :setDescription(
        _(
            [[The WX-Lindworm, or "Worm" as it's often called, is a bomber-class starfighter. While one of the least-shielded starfighters in active duty, the Worm's two launchers can pack quite a punch. Its goal is to fly in, destroy its target, and fly out or be destroyed.]]
        )
    )
    :setHull(50)
    :setShields(20)
    :setSpeed(50, 15, 25)
    :setTubes(3, 15.0)
    :setWeaponStorage("HVLI", 6)
    :setWeaponStorage("Homing", 1)
    :setTubeSize(0, "small")
    :setTubeSize(1, "small")
    :setTubeSize(2, "small")
    :setTubeDirection(1, 1):setWeaponTubeExclusiveFor(1, "HVLI")
    :setTubeDirection(2, -1):setWeaponTubeExclusiveFor(2, "HVLI")

-- ZX-Lindworm (PlayerControl variant)
variation = template
    :copy("ZX-Lindworm")
    :setLocaleName(_("playerShip", "ZX-Lindworm"))
    :setModel("LindwurmFighterBlue")
    :setType("playership")
    :setDescription(
        _(
            [[The ZX-Lindworm is a vastly improved version of the WX-Lindworm, with an additional beam weapon, more missiles, tougher hull, faster engine, and more agile thrusters.]]
        )
    )
    :setHull(75)
    :setShields(40)
    :setSpeed(70, 15, 25)
    :setTubes(3, 10.0)
    :setTubeSize(0, "small")
    :setTubeSize(1, "small")
    :setTubeSize(2, "small")

    :setWeaponStorage("HVLI", 12)
    :setWeaponStorage("Homing", 3)
    :setBeam(0, 10, 180, 700, 6.0, 2)
    :setBeamWeaponTurret(0, 270, 180, 4)
    :setCombatManeuver(250, 150)
    :setEnergyStorage(400)

    :setRepairCrewCount(1)
    :addRoomSystem(0, 0, 1, 3, "RearShield")
    :addRoomSystem(1, 1, 3, 1, "MissileSystem")
    :addRoomSystem(4, 1, 2, 1, "Beamweapons")
    :addRoomSystem(3, 2, 2, 1, "Reactor")
    :addRoomSystem(2, 3, 2, 1, "Warp")
    :addRoomSystem(4, 3, 5, 1, "JumpDrive")
    :addRoomSystem(0, 4, 1, 3, "Impulse")
    :addRoomSystem(3, 4, 2, 1, "Maneuver")
    :addRoomSystem(1, 5, 3, 1, "FrontShield")
    :addRoomSystem(4, 5, 2, 1, "DockingBay")

    :addDoor(1, 1, false)
    :addDoor(1, 5, false)
    :addDoor(3, 2, true)
    :addDoor(4, 2, true)
    :addDoor(3, 3, true)
    :addDoor(4, 3, true)
    :addDoor(3, 4, true)
    :addDoor(4, 4, true)
    :addDoor(3, 5, true)
    :addDoor(4, 5, true)
