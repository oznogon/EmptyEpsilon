--[[ Starfighters

Starfighters are small ships most commonly used in light firepower roles.

Fighters have crews of 1 to 3. They lack long-term life support and require a
nearby station or carrier for extended deployments. They're commonly deployed
in larger groups, and most have a single shield segment and light armaments.

Starfighters come in the following subclasses:

- Interceptors: Fast, lightly armed, very maneuverable.
- Gunship: Equipped with more weapons at the expense of maneuverability.
- Bomber: Slowest among starfighters, but packs a larger punch. While typically lacking any beam weapons, larger bombers can deliver nukes.
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
            [[The MT52 Hornet is a basic interceptor-class starfighter found in many corners of the galaxy. It's easy to find spare parts for MT52s, not only because they're produced in large numbers, but also because they suffer high losses in combat.]]
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
            [[The MU52 Hornet is an upgraded version of the MT52 interceptor-class starfighter. All of its systems are slightly improved over the MT52 model.]]
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
            [[The MP52 Hornet is a significantly upgraded version of MU52 Hornet interceptor-class starfighter, with nearly twice the hull strength, nearly three times the shielding, better acceleration, impulse boosters, and a second laser cannon.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The Adder MK5 has proven to be a great success amongst pirates and system patrols alike. It's cheap, fast, easy to maintain, and packs a decent punch.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The Adder MK4 is a rare sight these days due to the success its successor, the Adder MK5, which often replaces this model. Its similar hull, however, means careless buyers are sometimes conned into buying mark 4 models disguised as the mark 5.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The Adder MK3 is one of the first of the Adder line to meet with some success, and many were made before the manufacturer went through its first bankruptcy. Its low price and similarity to subsequent models has led to a resurgence of secondhand sales of the mark 3 model. Compared to the Adder MK4, the mark 3 has weaker shields and hull, but a faster turning rate.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The Adder MK6 is a small upgrade compared to the highly successful Adder MK5. Since people still prefer the more familiar and reliable mark 5, the mark 6 hasn't seen the same level of success.]]
        )
    )
    :setBeam(3, 35, 180, 600, 6.0, 2.0)
    :setWeaponStorage("HVLI", 8)

-- Adder MK7
local var2 = variation
    :copy("Adder MK7")
    :setLocaleName(_("ship", "Adder MK7"))
    :setModel("AdlerLongRangeScoutGreen")
    :setDescription(
        _(
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The release of the Adder MK7 sent the manufacturer into a second bankruptcy. Despite stronger shields and longer beam ranges, the popularity of previous models (especially the Adder MK5) prevented them from raising the purchase price enough to recoup the mark 7's development and manufacturing costs.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[After replacing its management, the Adder MK8 returned to the roots of its most popular Adder MK5 model with modernized shields, longer-ranged and stronger beam weapons, and a faster turning rate. The mark 8 targeted practical but nostalgic buyers replacing their mark 5 hardware.]]
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
            [[The Adder starfighter hull is a long-running, frequently iterated-upon design. Adders are commonly classified as gunships, with most models featuring several beam weapons and at least one weapon tube.]]
        ) .. " " .. _(
            [[The Adder MK9 quickly followed the Adder MK8. While still using the popular Adder MK5 as a base, the designers further strengthened its shields, increased the beam weapons' fire rate and thrusters' turning rate, and storage for two nuclear missiles.]]
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
    :setTubeDirection(1, 1)
    :setWeaponTubeExclusiveFor(1, "HVLI")
    :setTubeDirection(2, -1)
    :setWeaponTubeExclusiveFor(2, "HVLI")

-- ZX-Lindworm (PlayerControl variant)
variation = template
    :copy("ZX-Lindworm")
    :setLocaleName(_("playerShip", "ZX-Lindworm"))
    :setModel("LindwurmFighterBlue")
    :setType("playership")
    :setDescription(
        _(
            [[The ZX-Lindworm is a vastly improved version of the WX-Lindworm bomber-class starfighter, with an additional beam weapon, more missiles, tougher hull, faster engine, and more agile thrusters.]]
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

-- Stingray (PlayerControl ship, fka Player Fighter)
template = ShipTemplate()
    :setName("Stingray")
    :setLocaleName(_("playerShip", "Stingray"))
    :setModel("small_fighter_1")
    :setType("playership")
    :setRadarTrace("fighter.png")
    :setDescription(
        _(
            [[The Stingray is a little-known predecessor to the MU52 Hornet. Once commonplace, most of the few remaining Stingrays have been converted to couriers and illegal racers due to their (frankly unsafe) impulse engines.]]
        )
    )
    :setHull(60)
    :setShields(40)
    :setSpeed(110, 20, 40)
    :setCombatManeuver(600, 0)
    :setEnergyStorage(400)
    :setBeam(0, 40, -10, 1000.0, 6.0, 8)
    :setBeam(1, 40, 10, 1000.0, 6.0, 8)
    :setTubes(1, 10.0)
    :setWeaponStorage("HVLI", 4)
    :addRoomSystem(3, 0, 1, 1, "Maneuver")
    :addRoomSystem(1, 0, 2, 1, "BeamWeapons")
    :addRoomSystem(0, 1, 1, 2, "RearShield")
    :addRoomSystem(1, 1, 2, 2, "Reactor")
    :addRoomSystem(3, 1, 2, 1, "Warp")
    :addRoomSystem(3, 2, 2, 1, "JumpDrive")
    :addRoomSystem(5, 1, 1, 2, "FrontShield")
    :addRoomSystem(1, 3, 2, 1, "MissileSystem")
    :addRoomSystem(3, 3, 1, 1, "Impulse")
    :addRoomSystem(0, 0, 1, 1, "Sensors")
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

-- Riposte
template = ShipTemplate()
    :setName("Riposte")
    :setLocaleName(_("ship", "Fighter"))
    :setModel("small_fighter_1")
    :setRadarTrace("fighter.png")
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
    :setDescription(
        _(
            [[Ripostes are weak, nimble interceptors with a single beam weapon that become a greater threat when they engage in larger groups. They're often deployed in reconnaissance, patrol, and outpost-defense roles.]]
        )
    )
    :setBeam(0, 60, 0, 1000.0, 4.0, 4)
    :setHull(30)
    :setShields(30)
    :setSpeed(120, 30, 25)
    :setDefaultAI("fighter")

-- Strix (fka Strikeship)
template = ShipTemplate()
    :setName("Strix")
    :setLocaleName(_("ship", "Strix"))
    :setModel("small_frigate_3")
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
    :setRadarTrace("striker.png")
    :setDescription(
        _(
            [[The Strix is a warp-equipped interceptor built for ambush tactics.]]
        ) .. " " .. _(
            [[For a starfighter it's slow at sublight flight and lacks manueverability, and most of its shielding is focused forward. However, thanks to its paired beam weapons and ability to strike quickly and escape, they've become a favorite of raiders that seek to catch poorly defended convoys unaware.]]
        ) .. " " .. _(
            [[Strixes are often accompanied or complemented by Magpies, which have similar capabilities but use a jump drive for FTL travel.]]
        )
    )
    :setBeam(0, 40, -5, 1000.0, 6.0, 6)
    :setBeam(1, 40, 5, 1000.0, 6.0, 6)
    :setHull(100)
    :setShields(80, 30, 30, 30)
    :setSpeed(70, 12, 12)
    :setWarpSpeed(1000)

-- Magpie (fka Advanced Striker)
template = ShipTemplate()
    :setName("Magpie")
    :setLocaleName(_("ship", "Magpie"))
    :setClass(_("class", "Starfighter"), _("subclass", "Gunship"))
    :setModel("space_frigate_6")
    :setRadarTrace("adv_striker.png")
    :setDescription(
        _(
            [[The Magpie is a jump-equipped gunship built for ambush tactics.]]
        ) .. " " .. _(
            [[For a starfighter it's slow at sublight flight and lacks manueverability, and most of its shielding is focused forward. However, thanks to its paired beam weapons and ability to strike quickly and escape, they've become a favorite of raiders that seek to catch poorly defended convoys unaware.]]
        ) .. " " .. _(
            [[Magpies are often accompanied or complemented by Strixes, which have similar capabilities but use a warp drive for FTL travel.]]
        )
)
    :setBeam(0, 50, -15, 1000.0, 6.0, 6)
    :setBeam(1, 50, 15, 1000.0, 6.0, 6)
    :setHull(70)
    :setShields(50, 30)
    :setSpeed(45, 12, 15)
    :setJumpDrive(true)

-- Crow (fka Striker)
variation = template
    :copy("Crow")
    :setLocaleName(_("playerShip", "Crow"))
    :setClass(_("class", "Starfighter"), _("subclass", "Gunship"))
    :setType("playership")
    :setDescription(
        _(
            [[The Crow gunship is the predecessor to the Magpie starfighter. Slow, weakly armed, and lacking in shields, it's at least relatively agile.]]
        )
    )
    :setHull(120)
    :setSpeed(45, 15, 30)
    :setJumpDrive(false)
    :setCombatManeuver(250, 150)
    :setEnergyStorage(500)
    :setRepairCrewCount(2)
    :setBeam(0, 10, -15, 1000.0, 6.0, 6)
    :setBeamWeaponTurret(0, 100, -15, 6)
    :setBeam(1, 10, 15, 1000.0, 6.0, 6)
    :setBeamWeaponTurret(1, 100, 15, 6)
    :addRoomSystem(0, 0, 1, 2, "Sensors")
    :addRoomSystem(4, 0, 3, 1, "RearShield")
    :addRoomSystem(1, 1, 1, 3, "Reactor")
    :addRoomSystem(3, 1, 3, 1, "MissileSystem")
    :addRoomSystem(2, 2, 3, 1, "Warp")
    :addRoomSystem(5, 2, 4, 1, "JumpDrive")
    :addRoomSystem(0, 3, 1, 2, "Impulse")
    :addRoomSystem(3, 3, 3, 1, "Maneuver")
    :addRoomSystem(4, 4, 3, 1, "FrontShield")
    :addDoor(1, 1, false)
    :addDoor(4, 1, true)
    :addDoor(2, 2, false)
    :addDoor(5, 2, true)
    :addDoor(5, 2, false)
    :addDoor(1, 3, false)
    :addDoor(4, 3, true)
    :addDoor(5, 4, true)
