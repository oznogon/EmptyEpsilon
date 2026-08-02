-- Name: Mounts Test
-- Description: Test scenario for the unified Mounts component. Verifies beam weapon, missile weapon, and utility beam mounts.
-- Type: Development

require("utils.lua")

local function mlog(msg)
    log("[MountsTest] " .. msg)
end

local function findMountOfType(mounts, mount_type)
    if mounts then
        for i = 1, #mounts do
            if mounts[i].type == mount_type then
                return mounts[i]
            end
        end
    end
    return nil
end

function init()
    mlog("=== Mounts Component Test ===")

    -- Create a test ship
    local player = PlayerSpaceship()
    player
        :setTemplate("Phobos M3")
        :setFaction("Independent")
        :setPosition(0, 0)

    -- Verify the entity has the mounts component
    local mounts = player.components.mounts
    assert_eq(mounts ~= nil, true, "Mounts component exists")
    local num_mounts = #mounts
    mlog("Total mounts: " .. num_mounts)

    -- Count mounts by type
    local beam_count = 0
    local missile_count = 0
    for i = 1, num_mounts do
        local t = mounts[i].type
        if t == "beam" then beam_count = beam_count + 1
        elseif t == "missile" then missile_count = missile_count + 1
        end
    end
    mlog("Beam mounts: " .. beam_count .. ", Missile mounts: " .. missile_count)

    -- Verify beam weapon mount properties
    if beam_count > 0 then
        local bm = nil
        for i = 1, num_mounts do
            if mounts[i].type == "beam" then
                bm = mounts[i]
                break
            end
        end
        assert_eq(bm ~= nil, true, "Found beam mount")
        if bm then
            assert_eq(bm.arc, 90, "Beam arc")
            assert_eq(bm.range, 1200, "Beam range")
            assert_eq(bm.direction, -15, "Beam direction")
            assert_eq(bm.cycle_time, 8, "Beam cycle_time")
            assert_eq(bm.damage, 6, "Beam damage")
            assert_eq(bm.turret_arc, 0, "Beam turret_arc")
        end
    end

    -- Verify optional turrets on beam weapons
    if beam_count > 0 then
        local bm = findMountOfType(mounts, "beam")
        -- Non-turreted beam mounts default to no turret
        assert_eq(bm.turret_arc, 0, "Beam turret_arc default (no turret)")
        assert_eq(bm.turret_direction, 0, "Beam turret_direction default (no turret)")
        assert_eq(bm.turret_rotation_rate, 0, "Beam turret_rotation_rate default (no turret)")

        -- Optional turret via the entity API
        player:setBeamWeaponTurret(0, 120, -30, 4)
        assert_eq(player:getBeamWeaponTurretArc(0), 120, "Beam turret_arc via setBeamWeaponTurret")
        assert_eq(player:getBeamWeaponTurretDirection(0), -30, "Beam turret_direction via setBeamWeaponTurret")
        assert_eq(player:getBeamWeaponTurretRotationRate(0), 4, "Beam turret_rotation_rate via setBeamWeaponTurret")
        assert_eq(bm.turret_arc, 120, "Beam turret_arc persisted on mount")
        assert_eq(bm.turret_direction, -30, "Beam turret_direction persisted on mount")
        assert_eq(bm.turret_rotation_rate, 4, "Beam turret_rotation_rate persisted on mount")

        -- A turreted beam defined by a ship template
        local turret_ship = PlayerSpaceship()
        turret_ship:setTemplate("Nautilus")
        turret_ship:setFaction("Independent")
        turret_ship:setPosition(2000, 0)
        local turret_mounts = turret_ship.components.mounts
        assert_eq(turret_mounts ~= nil, true, "Turreted ship mounts component exists")
        local tbm = findMountOfType(turret_mounts, "beam")
        assert_eq(tbm.turret_arc, 90, "Turreted beam turret_arc from template")
        assert_eq(tbm.turret_direction, 35, "Turreted beam turret_direction from template")
        assert_eq(tbm.turret_rotation_rate, 6, "Turreted beam turret_rotation_rate from template")
    end

    -- Verify missile mount properties
    if missile_count > 0 then
        local mm = nil
        for i = 1, num_mounts do
            if mounts[i].type == "missile" then
                mm = mounts[i]
                break
            end
        end
        assert_eq(mm ~= nil, true, "Found missile mount")
        if mm then
            assert_eq(mm.load_time, 60, "Missile load_time")
            assert_eq(mm.direction, -1, "Missile direction")
            assert_eq(mm.state, "empty", "Missile state (Empty)")
            assert_eq(mm.missile_size, "medium", "Missile size (Medium)")
        end
    end

    -- Verify optional turrets on missile weapons
    if missile_count > 0 then
        local mm = findMountOfType(mounts, "missile")
        -- Non-turreted missile mounts default to no turret
        assert_eq(mm.turret_arc, 0, "Missile turret_arc default (no turret)")
        assert_eq(mm.turret_direction, 0, "Missile turret_direction default (no turret)")
        assert_eq(mm.turret_rotation_rate, 0, "Missile turret_rotation_rate default (no turret)")

        -- Turret fields are common to all mount types and settable at runtime
        mm.turret_arc = 180
        mm.turret_direction = 0
        mm.turret_rotation_rate = 3
        assert_eq(mm.turret_arc, 180, "Missile turret_arc set")
        assert_eq(mm.turret_direction, 0, "Missile turret_direction set")
        assert_eq(mm.turret_rotation_rate, 3, "Missile turret_rotation_rate set")
        mlog("Phobos M3 missile tube 0 is now turreted")
    end

    -- Test utility beam: create a ship and add a utility beam mount
    local util_ship = PlayerSpaceship()
    util_ship
        :setTemplate("Heracles")
        :setFaction("Independent")
        :setPosition(1000, 0)
        :setCallSign("UTIL")
    local util_mounts = util_ship.components.mounts
    assert_eq(util_mounts ~= nil, true, "Utility ship mounts component exists")
    local util_num = #util_mounts
    local util_found = false
    for i = 1, util_num do
        if util_mounts[i].type == "utility" then
            local um = util_mounts[i]
            util_found = true
            um.arc_color = {0, 255, 255, 128}
            assert_eq(um.max_arc, 90, "Utility max_arc")
            assert_eq(um.max_range, 2000, "Utility max_range")
            assert_eq(um.cycle_time, 6, "Utility cycle_time")
            assert_eq(um.strength, 1000, "Utility strength")
            mlog("Utility beam mount verified")
        end
    end
    assert_eq(util_found, true, "Found utility beam mount")

    -- Verify optional turrets on the utility beam
    local um = findMountOfType(util_mounts, "utility")
    assert_eq(um ~= nil, true, "Found utility mount for turret test")
    if um then
        -- Non-turreted utility beam mounts default to no turret
        assert_eq(um.turret_arc, 0, "Utility turret_arc default (no turret)")
        assert_eq(um.turret_direction, 0, "Utility turret_direction default (no turret)")
        assert_eq(um.turret_rotation_rate, 0, "Utility turret_rotation_rate default (no turret)")

        -- Turret fields are common to all mount types and settable at runtime
        um.turret_arc = 150
        um.turret_direction = 0
        um.turret_rotation_rate = 4
        assert_eq(um.turret_arc, 150, "Utility turret_arc set")
        assert_eq(um.turret_direction, 0, "Utility turret_direction set")
        assert_eq(um.turret_rotation_rate, 4, "Utility turret_rotation_rate set")
        mlog("Hylas utility beam is now turreted")
    end

    -- Test runtime mount property modification
    if beam_count > 0 then
        local bm = mounts[1]
        local orig_cooldown = bm.cooldown
        bm.cooldown = 2.5
        assert_eq(bm.cooldown, 2.5, "Cooldown can be set")
        bm.cooldown = orig_cooldown
    end

    if missile_count > 0 then
        -- Find missile mount
        local mm = nil
        for i = 1, num_mounts do
            if mounts[i].type == "missile" then
                mm = mounts[i]
                break
            end
        end
        if mm then
            -- Test type_allowed_mask via flags
            assert_eq(mm.allow_homing, true, "Missile allow_homing")
            mm.allow_homing = false
            assert_eq(mm.allow_homing, false, "Missile allow_homing cleared")
            mm.allow_homing = true
            assert_eq(mm.allow_homing, true, "Missile allow_homing restored")
        end
    end

    mlog("=== All Mounts component tests complete ===")
end
