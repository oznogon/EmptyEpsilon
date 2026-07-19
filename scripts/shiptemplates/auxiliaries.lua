--[[ Auxiliaries

Auxiliary ships fill non-combat support roles. This includes freighters,
transports, tugs, and other vessels that supply, repair, and move materiel.
They are generally lightly armed or unarmed and rely on escorts for protection.
]]

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
                [[Cargo freighters haul large loads across long distances on impulse power. Their cargo bays include climate control and stabilization systems that keep the cargo in good condition.]]
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

-- Light transports

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
            [[The Flavia Falcon is a variant of the Flavia small transport modified for faster flight, and adds rear-mounted beam weapons to keep enemies off its back.]]
        )
    )
    :setSpeed(50, 8, 10)
    :setBeam(0, 40, 170, 1200.0, 6.0, 6)
    :setBeam(1, 40, 190, 1200.0, 6.0, 6)

-- Flavia P.Falcon (PlayerControl variant)
variation = variation
    :copy("Flavia P.Falcon")
    :setLocaleName(_("playerShip", "Flavia P.Falcon"))
    :setType("playership")
variation
    :setDescription(
        _(
            [[The Flavia P.Falcon is a variant of the Flavia Falcon, and adds a nuclear-capable rear-facing weapon tube and warp drive to its improved impulse engine and rear-facing beam weapons.]]
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

-- Repulse (PlayerControl ship)
template = ShipTemplate()
    :setName("Repulse")
    :setLocaleName(_("playerShip", "Repulse"))
    :setClass(_("class", "Auxiliary"), _("subclass", "Transport"))
    :setModel("LightCorvetteRed")
    :setType("playership")
    :setRadarTrace("tug.png")
    :setDescription(
        _(
            [[The Repulse is an armed and armored transport ship based on the popular Flavia design. Despite its bolstered shields and hull, it remains faster than a stock Flavia, or even the Flavia Falcon, but is slightly slower than the Flavia P.Falcon variant.]]
        )
    )
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
    :setDescription(
        _(
            [[The Hylas is an unarmed tugboat with a powerful short-range tractor beam capable of moving much larger ships through gravity-field manipulation. It's nimble on its own and lightly shielded to avoid taking damage from collisions with larger ships, but it's otherwise defenseless.]]
        )
    )
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
            [[The Heracles tug model is a Hylas suited for carrier use in deep-space operations. Improvements include a stronger hull, bolstered shield, full sensor suite, and a shield-disrupting beam for use in boarding operations, salvaging abandoned vessels, or investigating unknown ships.]]
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
    :addRoomSystem(2, 5, 2, 1, "Sensors")
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
