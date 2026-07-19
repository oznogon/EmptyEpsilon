--[[                  Auxiliaries
Auxiliary ships provide non-combat support roles: freighters, transports,
tugs, and other vessels that supply, repair, and move materiel.
They are generally lightly armed or unarmed and rely on escorts
for protection in hostile space.
----------------------------------------------------------]]

-- Freighters

for cnt = 1, 5 do
    local template = ShipTemplate()
        :setName("Personnel Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Personnel Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_1_" .. cnt)
        :setDescription(
            _(
                [[These freighters are designed to transport armed troops, military support personnel, and combat gear.]]
            )
        )
        :setHull(100)
        :setShields(50, 50)
        :setSpeed(60 - 5 * cnt, 6, 10)
        :setRadarTrace("transport.png")
        :setDefaultAI("evasion")
        :setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template
            :copy("Personnel Jump Freighter " .. cnt)
            :setLocaleName(string.format(_("ship", "Personnel Jump Freighter %d"), cnt))
        variation
            :setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Goods Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Goods Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_2_" .. cnt)
        :setDescription(
            _(
                [[Cargo freighters haul large loads of cargo across long distances on impulse power. Their cargo bays include climate control and stabilization systems that keep the cargo in good condition.]]
            )
        )
        :setHull(100)
        :setShields(50, 50)
        :setSpeed(60 - 5 * cnt, 6, 10)
        :setRadarTrace("transport.png")
        :setDefaultAI("evasion")
        :setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template
            :copy("Goods Jump Freighter " .. cnt)
            :setLocaleName(string.format(_("ship", "Goods Jump Freighter %d"), cnt))
        variation
            :setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Garbage Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Garbage Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_3_" .. cnt)
        :setDescription(
            _(
                [[These freighters are specially designed to haul garbage and waste. They are fitted with a trash compactor and fewer stabilzation systems than cargo freighters.]]
            )
        )
        :setHull(100)
        :setShields(50, 50)
        :setSpeed(60 - 5 * cnt, 6, 10)
        :setRadarTrace("transport.png")
        :setDefaultAI("evasion")
        :setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template
            :copy("Garbage Jump Freighter " .. cnt)
            :setLocaleName(string.format(_("ship", "Garbage Jump Freighter %d"), cnt))
        variation
            :setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Equipment Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Equipment Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_4_" .. cnt)
        :setDescription(
            _(
                [[Equipment freighters have specialized environmental and stabilization systems to safely carry delicate machinery and complex instruments.]]
            )
        )
        :setHull(100)
        :setShields(50, 50)
        :setSpeed(60 - 5 * cnt, 6, 10)
        :setRadarTrace("transport.png")
        :setDefaultAI("evasion")
        :setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template
            :copy("Equipment Jump Freighter " .. cnt)
            :setLocaleName(string.format(_("ship", "Equipment Jump Freighter %d"), cnt))
        variation
            :setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Fuel Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Fuel Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_5_" .. cnt)
        :setDescription(
            _(
                [[Fuel freighters have massive tanks for hauling fuel, and delicate internal sensors that watch for any changes to their cargo's potentially volatile state.]]
            )
        )
        :setHull(100)
        :setShields(50, 50)
        :setSpeed(60 - 5 * cnt, 6, 10)
        :setRadarTrace("transport.png")
        :setDefaultAI("evasion")
        :setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template
            :copy("Fuel Jump Freighter " .. cnt)
            :setLocaleName(string.format(_("ship", "Fuel Jump Freighter %d"), cnt))
        variation
            :setJumpDrive(true)
    end
end

-- Transports

-- Jump Carrier
local template = ShipTemplate()
    :setName("Jump Carrier")
    :setLocaleName(_("ship", "Jump Carrier"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("transport_4_2")
    :setDescription(
        _(
            [[The Jump Carrier is a specialized freighter. Its cargo bay is replaced with a jump drive and the energy storage required to run it.
Rather than carrying cargo, the Jump Carrier is designed to carry other ships deep into space. It accordingly has special docking parameters that allow other ships to attach themselves to it.]]
        )
    )
    :setHull(100)
    :setShields(50, 50)
    :setSpeed(50, 6, 10)
    :setRadarTrace("transport.png")
    :setJumpDrive(true)
    :setJumpDriveRange(5000, 100 * 50000)
    :setExternalDockClasses(_("class", "Frigate"), _("class", "Destroyer"))
    :setInternalDockClasses(_("class", "Starfighter"), _("class", "Cargo"))
    :setDefaultAI("evasion")

-- Benedict
local variation = template
    :copy("Benedict")
    :setLocaleName(_("playerShip", "Benedict"))
    :setType("playership")
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
variation
    :setDescription(
        _(
            [[The Benedict is an improved version of the Jump Carrier.]]
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
            [[The Kiriya is an improved warp-drive version of the Jump Carrier.]]
        )
    )
    :setBeam(0, 10, 0, 1500.0, 6.0, 4)
    :setBeam(1, 10, 180, 1500.0, 6.0, 4)
    :setBeamWeaponTurret(0, 90, 0, 6)
    :setBeamWeaponTurret(1, 90, 180, 6)
    :setJumpDrive(false)
    :setWarpSpeed(750)

-- Generic transports
for type = 1, 5 do
    for cnt = 1, 5 do
        local t = ShipTemplate()
            :setName("Transport" .. type .. "x" .. cnt)
            :setLocaleName(
                string.format(_("ship", "Transport %dx%d"), type, cnt)
            )
            :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
            :setModel("transport_" .. type .. "_" .. cnt)
            :setHull(100)
            :setShields(50, 50)
            :setSpeed(60 - 5 * cnt, 6, 10)
            :setRadarTrace("transport.png")
            :setDefaultAI("evasion")
    end
end

-- Light Transports (Frigate-sized)

-- Flavia
template = ShipTemplate()
    :setName("Flavia")
    :setLocaleName(_("ship", "Flavia"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("LightCorvetteGrey")
    :setRadarTrace("tug.png")
    :setDescription(
        _(
            [[Popular among traders and smugglers, the Flavia is a small cargo and passenger transport. It's cheaper than a freighter for small loads and short distances, and is often used to carry high-value cargo discreetly.]]
        )
    )
    :setHull(50)
    :setShields(50, 50)
    :setSpeed(30, 8, 10)
    :setInternalDockClasses(_("class", "Cargo"))

-- Flavia Falcon
variation = template
    :copy("Flavia Falcon")
    :setLocaleName(_("ship", "Flavia Falcon"))
variation
    :setDescription(
        _(
            [[The Flavia Falcon is a Flavia transport modified for faster flight, and adds rear-mounted lasers to keep enemies off its back.]]
        )
    )
    :setSpeed(50, 8, 10)
    :setBeam(0, 40, 170, 1200.0, 6.0, 6)
    :setBeam(1, 40, 190, 1200.0, 6.0, 6)

-- Flavia P.Falcon
variation = variation
    :copy("Flavia P.Falcon")
    :setLocaleName(_("playerShip", "Flavia P.Falcon"))
    :setType("playership")
variation
    :setDescription(
        _(
            [[The Flavia P.Falcon has a nuclear-capable rear-facing weapon tube and a warp drive.]]
        )
    )
    :setHull(100)
    :setShields(70, 70)
    :setSpeed(60, 10, 10)
    :setWarpSpeed(500)
    :setCombatManeuver(250, 150)
    :setTubes(1, 20.0)
    :setTubeDirection(0, 180)
    :setWeaponStorage("HVLI", 5)
    :setWeaponStorage("Homing", 3)
    :setWeaponStorage("Mine", 1)
    :setWeaponStorage("Nuke", 1)
    :setRepairCrewCount(8)
    :addRoomSystem(1, 0, 6, 1, "DockingBay")
    :addRoom(1, 5, 6, 1)
    :addRoomSystem(0, 1, 2, 2, "RearShield")
    :addRoomSystem(0, 3, 2, 2, "MissileSystem")
    :addRoomSystem(2, 1, 2, 2, "Beamweapons")
    :addRoomSystem(2, 3, 2, 2, "Reactor")
    :addRoomSystem(4, 1, 2, 2, "Warp")
    :addRoomSystem(4, 3, 2, 2, "JumpDrive")
    :addRoomSystem(6, 1, 2, 2, "Impulse")
    :addRoomSystem(6, 3, 2, 2, "Maneuver")
    :addRoomSystem(8, 2, 2, 2, "FrontShield")
    :addDoor(1, 1, true)
    :addDoor(3, 1, true)
    :addDoor(4, 1, true)
    :addDoor(6, 1, true)
    :addDoor(4, 3, true)
    :addDoor(5, 3, true)
    :addDoor(8, 2, false)
    :addDoor(8, 3, false)
    :addDoor(1, 5, true)
    :addDoor(2, 5, true)
    :addDoor(5, 5, true)
    :addDoor(6, 5, true)

-- Repulse
template = ShipTemplate()
    :setName("Repulse")
    :setLocaleName(_("playerShip", "Repulse"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("LightCorvetteRed")
    :setType("playership")
    :setRadarTrace("tug.png")
    :setDescription(_("Jump/Turret version of Flavia Falcon"))
    :setHull(120)
    :setShields(80, 80)
    :setSpeed(55, 9, 10)
    :setInternalDockClasses(_("class", "Cargo"))
    :setBeam(0, 10, 90, 1200.0, 6.0, 5)
    :setBeam(1, 10, -90, 1200.0, 6.0, 5)
    :setBeamWeaponTurret(0, 200, 90, 5)
    :setBeamWeaponTurret(1, 200, -90, 5)
    :setJumpDrive(true)
    :setCombatManeuver(250, 150)
    :setTubes(2, 20.0)
    :setTubeDirection(0, 0)
    :setTubeDirection(1, 180)
    :setWeaponStorage("HVLI", 6)
    :setWeaponStorage("Homing", 4)
    :setRepairCrewCount(8)
    :addRoomSystem(0, 1, 2, 4, "Impulse")
    :addRoomSystem(2, 0, 2, 2, "RearShield")
    :addRoomSystem(2, 2, 2, 2, "Warp")
    :addRoomSystem(2, 4, 2, 2, "DockingBay")
    :addRoomSystem(4, 1, 1, 4, "Maneuver")
    :addRoom(5, 0, 2, 2)
    :addRoomSystem(5, 2, 2, 2, "JumpDrive")
    :addRoomSystem(5, 4, 2, 2, "Beamweapons")
    :addRoomSystem(7, 1, 3, 2, "Reactor")
    :addRoomSystem(7, 3, 3, 2, "MissileSystem")
    :addRoomSystem(10, 2, 2, 2, "FrontShield")
    :addDoor(2, 2, false)
    :addDoor(2, 4, false)
    :addDoor(3, 2, true)
    :addDoor(4, 3, false)
    :addDoor(5, 2, false)
    :addDoor(5, 4, true)
    :addDoor(7, 3, false)
    :addDoor(7, 1, false)
    :addDoor(8, 3, true)
    :addDoor(10, 2, false)

-- Tugs

-- Hylas
template = ShipTemplate()
    :setName("Hylas")
    :setLocaleName(_("ship", "Hylas"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Tug"))
    :setModel("space_tug")
    :setRadarTrace("tug.png")
    :setHull(50)
    :setShields(20)
    :setSpeed(100, 10, 15)
    :setUtilityBeam(90, 2000, 6.0, 1000.0)

-- Heracles
variation = template
    :copy("Hylas")
    :setName("Heracles")
    :setLocaleName(_("playerShip", "Heracles"))
    :setType("playership")
variation
    :setDescription(
        _(
            [[The Heracles tug model is a Hylas suited for carrier use in deep-space operations. Improvements include a stronger hull, minimal shield system, full sensor suite, and a shield-disrupting beam for use on abandoned hostile or unknown ships.]]
        )
    )
    :setShields(100)
    :setHull(100)
    :setBeamWeapon(0, 90, 0, 1000, 2, 1)
    :addRoomSystem(1, 0, 2, 1, "Maneuver")
    :addRoomSystem(1, 1, 2, 1, "BeamWeapons")
    :addRoom(2, 2, 2, 1)
    :addRoomSystem(0, 3, 1, 2, "RearShield")
    :addRoomSystem(1, 3, 2, 2, "Reactor")
    :addRoomSystem(3, 3, 2, 2, "Warp")
    :addRoomSystem(5, 3, 1, 2, "JumpDrive")
    :addRoomSystem(6, 3, 2, 1, "UtilityBeam")
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
