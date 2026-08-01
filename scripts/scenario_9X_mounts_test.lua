-- Name: Mounts Test
-- Description: Test scenario for the unified Mounts component. Verifies beam weapon, missile weapon, and utility beam mounts.
-- Type: Development

local function log(msg)
    print("[MountsTest] " .. msg)
end

local function assert_eq(actual, expected, name)
    if actual ~= expected then
        log("FAIL: " .. name .. " expected=" .. tostring(expected) .. " got=" .. tostring(actual))
        return false
    end
    log("PASS: " .. name .. " = " .. tostring(actual))
    return true
end

function init()
    log("=== Mounts Component Test ===")

    -- Create a test ship
    local player = PlayerSpaceship()
    player:setTemplate("Phobos T3")
    player:setFaction("Independent")
    player:setPosition(0, 0)

    -- Verify the entity has the mounts component
    local mounts = player:getComponent("mounts")
    assert_eq(mounts ~= nil, true, "Mounts component exists")
    local num_mounts = mounts.mounts:len()
    log("Total mounts: " .. num_mounts)

    -- Count mounts by type
    local beam_count = 0
    local missile_count = 0
    for i = 0, num_mounts - 1 do
        local t = mounts.mounts[i].type
        if t == 0 then beam_count = beam_count + 1
        elseif t == 1 then missile_count = missile_count + 1
        end
    end
    log("Beam mounts: " .. beam_count .. ", Missile mounts: " .. missile_count)

    -- Verify beam weapon mount properties
    if beam_count > 0 then
        local bm = nil
        for i = 0, num_mounts - 1 do
            if mounts.mounts[i].type == 0 then
                bm = mounts.mounts[i]
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

    -- Verify missile mount properties
    if missile_count > 0 then
        local mm = nil
        for i = 0, num_mounts - 1 do
            if mounts.mounts[i].type == 1 then
                mm = mounts.mounts[i]
                break
            end
        end
        assert_eq(mm ~= nil, true, "Found missile mount")
        if mm then
            assert_eq(mm.load_time, 60, "Missile load_time")
            assert_eq(mm.direction, -1, "Missile direction")
            assert_eq(mm.state, 0, "Missile state (Empty)")
            assert_eq(mm.missile_size, 1, "Missile size (Medium)")
        end
    end

    -- Test utility beam: create a ship and add a utility beam mount
    local util_ship = CpuShip()
    util_ship:setTemplate("Hylas")
    util_ship:setFaction("Independent")
    util_ship:setPosition(1000, 0)
    util_ship:setCallSign("UTIL")
    local util_mounts = util_ship:getComponent("mounts")
    assert_eq(util_mounts ~= nil, true, "Utility ship mounts component exists")
    local util_num = util_mounts.mounts:len()
    local util_found = false
    for i = 0, util_num - 1 do
        if util_mounts.mounts[i].type == 2 then
            local um = util_mounts.mounts[i]
            util_found = true
            assert_eq(um.max_arc, 90, "Utility max_arc")
            assert_eq(um.max_range, 2000, "Utility max_range")
            assert_eq(um.cycle_time, 6, "Utility cycle_time")
            assert_eq(um.strength, 1000, "Utility strength")
            log("Utility beam mount verified")
        end
    end
    assert_eq(util_found, true, "Found utility beam mount")

    -- Test runtime mount property modification
    if beam_count > 0 then
        local bm = mounts.mounts[0]
        local orig_cooldown = bm.cooldown
        bm.cooldown = 2.5
        assert_eq(bm.cooldown, 2.5, "Cooldown can be set")
        bm.cooldown = orig_cooldown
    end

    if missile_count > 0 then
        -- Find missile mount
        local mm = nil
        for i = 0, num_mounts - 1 do
            if mounts.mounts[i].type == 1 then
                mm = mounts.mounts[i]
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

    log("=== All Mounts component tests complete ===")
    log("Test scenario ran successfully.")
end
