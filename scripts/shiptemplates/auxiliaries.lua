--[[                  Auxiliaries
Auxiliary ships provide non-combat support roles: freighters, transports,
tugs, and other vessels that supply, repair, and move materiel.
They are generally lightly armed or unarmed and rely on escorts
for protection in hostile space.
----------------------------------------------------------]]

--[[----------------------Freighters----------------------]]

for cnt = 1, 5 do
    local template = ShipTemplate()
        :setName("Personnel Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Personnel Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_1_" .. cnt)
    template:setDescription(
        _(
            [[These freighters are designed to transport armed troops, military support personnel, and combat gear.]]
        )
    )
    template:setHull(100)
    template:setShields(50, 50)
    template:setSpeed(60 - 5 * cnt, 6, 10)
    template:setRadarTrace("transport.png")
    template:setDefaultAI("evasion")
    template:setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation =
            template:copy("Personnel Jump Freighter " .. cnt):setLocaleName(
                string.format(_("ship", "Personnel Jump Freighter %d"), cnt)
            )
        variation:setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Goods Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Goods Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_2_" .. cnt)
    template:setDescription(
        _(
            [[Cargo freighters haul large loads of cargo across long distances on impulse power. Their cargo bays include climate control and stabilization systems that keep the cargo in good condition.]]
        )
    )
    template:setHull(100)
    template:setShields(50, 50)
    template:setSpeed(60 - 5 * cnt, 6, 10)
    template:setRadarTrace("transport.png")
    template:setDefaultAI("evasion")
    template:setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template:copy("Goods Jump Freighter " .. cnt):setLocaleName(
            string.format(_("ship", "Goods Jump Freighter %d"), cnt)
        )
        variation:setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Garbage Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Garbage Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_3_" .. cnt)
    template:setDescription(
        _(
            [[These freighters are specially designed to haul garbage and waste. They are fitted with a trash compactor and fewer stabilzation systems than cargo freighters.]]
        )
    )
    template:setHull(100)
    template:setShields(50, 50)
    template:setSpeed(60 - 5 * cnt, 6, 10)
    template:setRadarTrace("transport.png")
    template:setDefaultAI("evasion")
    template:setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation =
            template:copy("Garbage Jump Freighter " .. cnt):setLocaleName(
                string.format(_("ship", "Garbage Jump Freighter %d"), cnt)
            )
        variation:setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Equipment Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Equipment Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_4_" .. cnt)
    template:setDescription(
        _(
            [[Equipment freighters have specialized environmental and stabilization systems to safely carry delicate machinery and complex instruments.]]
        )
    )
    template:setHull(100)
    template:setShields(50, 50)
    template:setSpeed(60 - 5 * cnt, 6, 10)
    template:setRadarTrace("transport.png")
    template:setDefaultAI("evasion")
    template:setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation =
            template:copy("Equipment Jump Freighter " .. cnt):setLocaleName(
                string.format(_("ship", "Equipment Jump Freighter %d"), cnt)
            )
        variation:setJumpDrive(true)
    end

    template = ShipTemplate()
        :setName("Fuel Freighter " .. cnt)
        :setLocaleName(string.format(_("ship", "Fuel Freighter %d"), cnt))
        :setClass(_("class", "Auxiliary"), _("subclass", "Freighter"))
        :setModel("transport_5_" .. cnt)
    template:setDescription(
        _(
            [[Fuel freighters have massive tanks for hauling fuel, and delicate internal sensors that watch for any changes to their cargo's potentially volatile state.]]
        )
    )
    template:setHull(100)
    template:setShields(50, 50)
    template:setSpeed(60 - 5 * cnt, 6, 10)
    template:setRadarTrace("transport.png")
    template:setDefaultAI("evasion")
    template:setInternalDockClasses(_("class", "Cargo"))

    if cnt > 2 then
        local variation = template:copy("Fuel Jump Freighter " .. cnt):setLocaleName(
            string.format(_("ship", "Fuel Jump Freighter %d"), cnt)
        )
        variation:setJumpDrive(true)
    end
end

--[[----------------------Transports----------------------]]

local template = ShipTemplate()
    :setName("Jump Carrier")
    :setLocaleName(_("ship", "Jump Carrier"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("transport_4_2")
template:setDescription(
    _(
        [[The Jump Carrier is a specialized freighter. Its cargo bay is replaced with a jump drive and the energy storage required to run it.
Rather than carrying cargo, the Jump Carrier is designed to carry other ships deep into space. It accordingly has special docking parameters that allow other ships to attach themselves to it.]]
    )
)
template:setHull(100)
template:setShields(50, 50)
template:setSpeed(50, 6, 10)
template:setRadarTrace("transport.png")
template:setJumpDrive(true)
template:setJumpDriveRange(5000, 100 * 50000)
template:setExternalDockClasses(_("class", "Frigate"), _("class", "Destroyer"))
template:setInternalDockClasses(_("class", "Starfighter"), _("class", "Cargo"))
template:setDefaultAI("evasion")

local variation = template
    :copy("Benedict")
    :setLocaleName(_("playerShip", "Benedict"))
    :setType("playership")
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
variation:setDescription(
    _(
        [[The Benedict is an improved version of the Jump Carrier.]]
    )
)
variation:setShields(70, 70)
variation:setHull(200)
variation:setSpeed(60, 6, 8)
--                  Arc, Dir, Range, CycleTime, Dmg
variation:setBeam(0, 10, 0, 1500.0, 6.0, 4)
variation:setBeam(1, 10, 180, 1500.0, 6.0, 4)
--                       Arc, Dir, Rotate speed
variation:setBeamWeaponTurret(0, 90, 0, 6)
variation:setBeamWeaponTurret(1, 90, 180, 6)
variation:setCombatManeuver(400, 250)
variation:setJumpDriveRange(5000, 90000)

variation:setRepairCrewCount(6)
variation:addRoomSystem(3, 0, 2, 3, "Reactor")
variation:addRoomSystem(3, 3, 2, 3, "Warp")
variation:addRoomSystem(6, 0, 2, 3, "JumpDrive")
variation:addRoomSystem(6, 3, 2, 3, "MissileSystem")
variation:addRoomSystem(5, 2, 1, 2, "Maneuver")
variation:addRoomSystem(2, 2, 1, 2, "RearShield")
variation:addRoomSystem(0, 1, 2, 4, "Beamweapons")
variation:addRoomSystem(8, 2, 1, 2, "FrontShield")
variation:addRoomSystem(0, 0, 1, 1, "DockingBay")
variation:addRoomSystem(9, 1, 2, 4, "Impulse")

variation:addDoor(0, 1, true)
variation:addDoor(3, 3, true)
variation:addDoor(6, 3, true)
variation:addDoor(5, 2, false)
variation:addDoor(6, 3, false)
variation:addDoor(3, 2, false)
variation:addDoor(2, 3, false)
variation:addDoor(8, 2, false)
variation:addDoor(9, 3, false)

local var2 = variation:copy("Kiriya"):setLocaleName(_("playerShip", "Kiriya"))
var2:setDescription(
    _(
        [[The Kiriya is an improved warp-drive version of the Jump Carrier.]]
    )
)
--          Arc, Dir, Range, CycleTime, Dmg
var2:setBeam(0, 10, 0, 1500.0, 6.0, 4)
var2:setBeam(1, 10, 180, 1500.0, 6.0, 4)
--                      Arc, Dir, Rotate speed
var2:setBeamWeaponTurret(0, 90, 0, 6)
var2:setBeamWeaponTurret(1, 90, 180, 6)
var2:setJumpDrive(false)
var2:setWarpSpeed(750)

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
        t:setHull(100)
        t:setShields(50, 50)
        t:setSpeed(60 - 5 * cnt, 6, 10)
        t:setRadarTrace("transport.png")
        t:setDefaultAI("evasion")
    end
end

--[[-----------------Light Transports (Frigate-sized)------------------]]

template = ShipTemplate()
    :setName("Flavia")
    :setLocaleName(_("ship", "Flavia"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("LightCorvetteGrey")
template:setRadarTrace("tug.png")
template:setDescription(
    _(
        [[Popular among traders and smugglers, the Flavia is a small cargo and passenger transport. It's cheaper than a freighter for small loads and short distances, and is often used to carry high-value cargo discreetly.]]
    )
)
template:setHull(50)
template:setShields(50, 50)
template:setSpeed(30, 8, 10)
template:setInternalDockClasses(_("class", "Cargo"))

variation =
    template:copy("Flavia Falcon"):setLocaleName(_("ship", "Flavia Falcon"))
variation:setDescription(
    _(
        [[The Flavia Falcon is a Flavia transport modified for faster flight, and adds rear-mounted lasers to keep enemies off its back.]]
    )
)
variation:setSpeed(50, 8, 10)
variation:setBeam(0, 40, 170, 1200.0, 6.0, 6)
variation:setBeam(1, 40, 190, 1200.0, 6.0, 6)

variation = variation
    :copy("Flavia P.Falcon")
    :setLocaleName(_("playerShip", "Flavia P.Falcon"))
    :setType("playership")
variation:setDescription(
    _(
        [[The Flavia P.Falcon has a nuclear-capable rear-facing weapon tube and a warp drive.]]
    )
)
variation:setHull(100)
variation:setShields(70, 70)
variation:setSpeed(60, 10, 10)
variation:setWarpSpeed(500)
variation:setCombatManeuver(250, 150)
variation:setTubes(1, 20.0)
variation:setTubeDirection(0, 180)
variation:setWeaponStorage("HVLI", 5)
variation:setWeaponStorage("Homing", 3)
variation:setWeaponStorage("Mine", 1)
variation:setWeaponStorage("Nuke", 1)

variation:setRepairCrewCount(8)

variation:addRoomSystem(1, 0, 6, 1, "DockingBay")
variation:addRoom(1, 5, 6, 1)
variation:addRoomSystem(0, 1, 2, 2, "RearShield")
variation:addRoomSystem(0, 3, 2, 2, "MissileSystem")
variation:addRoomSystem(2, 1, 2, 2, "Beamweapons")
variation:addRoomSystem(2, 3, 2, 2, "Reactor")
variation:addRoomSystem(4, 1, 2, 2, "Warp")
variation:addRoomSystem(4, 3, 2, 2, "JumpDrive")
variation:addRoomSystem(6, 1, 2, 2, "Impulse")
variation:addRoomSystem(6, 3, 2, 2, "Maneuver")
variation:addRoomSystem(8, 2, 2, 2, "FrontShield")

variation:addDoor(1, 1, true)
variation:addDoor(3, 1, true)
variation:addDoor(4, 1, true)
variation:addDoor(6, 1, true)

variation:addDoor(4, 3, true)
variation:addDoor(5, 3, true)

variation:addDoor(8, 2, false)
variation:addDoor(8, 3, false)

variation:addDoor(1, 5, true)
variation:addDoor(2, 5, true)
variation:addDoor(5, 5, true)
variation:addDoor(6, 5, true)

template = ShipTemplate()
    :setName("Repulse")
    :setLocaleName(_("playerShip", "Repulse"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("LightCorvetteRed")
    :setType("playership")
template:setRadarTrace("tug.png")
template:setDescription(_("Jump/Turret version of Flavia Falcon"))
template:setHull(120)
template:setShields(80, 80)
template:setSpeed(55, 9, 10)
template:setInternalDockClasses(_("class", "Cargo"))

--                 Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 10, 90, 1200.0, 6.0, 5)
template:setBeam(1, 10, -90, 1200.0, 6.0, 5)
--                                Arc, Dir, Rotate speed
template:setBeamWeaponTurret(0, 200, 90, 5)
template:setBeamWeaponTurret(1, 200, -90, 5)
template:setJumpDrive(true)
template:setCombatManeuver(250, 150)
template:setTubes(2, 20.0)
template:setTubeDirection(0, 0)
template:setTubeDirection(1, 180)
template:setWeaponStorage("HVLI", 6)
template:setWeaponStorage("Homing", 4)

template:setRepairCrewCount(8)
--    (H)oriz, (V)ert       HC,VC,HS,VS, system
template:addRoomSystem(0, 1, 2, 4, "Impulse")
template:addRoomSystem(2, 0, 2, 2, "RearShield")
template:addRoomSystem(2, 2, 2, 2, "Warp")
template:addRoomSystem(2, 4, 2, 2, "DockingBay")
template:addRoomSystem(4, 1, 1, 4, "Maneuver")
template:addRoom(5, 0, 2, 2)
template:addRoomSystem(5, 2, 2, 2, "JumpDrive")
template:addRoomSystem(5, 4, 2, 2, "Beamweapons")
template:addRoomSystem(7, 1, 3, 2, "Reactor")
template:addRoomSystem(7, 3, 3, 2, "MissileSystem")
template:addRoomSystem(10, 2, 2, 2, "FrontShield")

template:addDoor(2, 2, false)
template:addDoor(2, 4, false)
template:addDoor(3, 2, true)
template:addDoor(4, 3, false)
template:addDoor(5, 2, false)
template:addDoor(5, 4, true)
template:addDoor(7, 3, false)
template:addDoor(7, 1, false)
template:addDoor(8, 3, true)
template:addDoor(10, 2, false)

--[[------------------------Tugs------------------------]]

template = ShipTemplate()
    :setName("Hylas")
    :setLocaleName(_("ship", "Hylas"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Tug"))
    :setModel("space_tug")
template:setRadarTrace("tug.png")
template:setHull(50)
template:setShields(20)
template:setSpeed(100, 10, 15)
--[[               max_arc, max_range, cycle_time, strength]]
template:setUtilityBeam(90, 2000, 6.0, 1000.0)

variation = template
    :copy("Hylas")
    :setName("Heracles")
    :setLocaleName(_("playerShip", "Heracles"))
    :setType("playership")
variation:setDescription(
    _(
        [[The Heracles tug model is a Hylas suited for carrier use in deep-space operations. Improvements include a stronger hull, minimal shield system, full sensor suite, and a shield-disrupting beam for use on abandoned hostile or unknown ships.]]
    )
)
variation:setShields(100)
variation:setHull(100)
variation:setBeamWeapon(0, 90, 0, 1000, 2, 1)

variation:addRoomSystem(1, 0, 2, 1, "Maneuver")
variation:addRoomSystem(1, 1, 2, 1, "BeamWeapons")
variation:addRoom(2, 2, 2, 1)

variation:addRoomSystem(0, 3, 1, 2, "RearShield")
variation:addRoomSystem(1, 3, 2, 2, "Reactor")
variation:addRoomSystem(3, 3, 2, 2, "Warp")
variation:addRoomSystem(5, 3, 1, 2, "JumpDrive")
variation:addRoomSystem(6, 3, 2, 1, "UtilityBeam")
variation:addRoom(6, 4, 2, 1)
variation:addRoomSystem(8, 3, 1, 2, "FrontShield")

variation:addRoom(2, 5, 2, 1)
variation:addRoomSystem(1, 6, 2, 1, "MissileSystem")
variation:addRoomSystem(1, 7, 2, 1, "Impulse")

variation:addDoor(1, 1, true)
variation:addDoor(2, 2, true)
variation:addDoor(3, 3, true)
variation:addDoor(1, 3, false)
variation:addDoor(3, 4, false)
variation:addDoor(3, 5, true)
variation:addDoor(2, 6, true)
variation:addDoor(1, 7, true)
variation:addDoor(5, 3, false)
variation:addDoor(6, 3, false)
variation:addDoor(6, 4, false)
variation:addDoor(8, 3, false)
variation:addDoor(8, 4, false)
