-- Name: Missile Weapon Data Test
-- Description: Tests Lua-driven MissileWeaponData loading, registry, tube masks, and ship storage
-- Type: Development

function init()
    -- Check that factions still have their names
    local human_navy = getFactionInfo("Human Navy")
    assert(human_navy, "Human Navy not found")
    local hn_data = human_navy.components.faction_info
    assert(hn_data, "Human Navy faction_info missing")
    assert(hn_data.name == "Human Navy", "FAIL: Human Navy name")
    assert(hn_data.locale_name ~= "", "FAIL: Human Navy locale_name empty")
    print("PASS: Faction names still work")

    print("=== MissileWeaponData Test Suite ===")

    assert(type(getMissileWeaponData) == "function", "getMissileWeaponData not available")
    assert(type(__missile_weapon_data) == "table", "__missile_weapon_data table missing")

    print("Loaded missile types:")
    for k, v in pairs(__missile_weapon_data) do
        print("  " .. tostring(k))
    end

    local homing = getMissileWeaponData("Homing")
    local nuke = getMissileWeaponData("Nuke")
    local mine = getMissileWeaponData("Mine")
    local emp = getMissileWeaponData("EMP")
    local hvli = getMissileWeaponData("HVLI")

    assert(homing, "Homing not found")
    assert(nuke, "Nuke not found")
    assert(mine, "Mine not found")
    assert(emp, "EMP not found")
    assert(hvli, "HVLI not found")
    print("PASS: All 5 default missile types loaded")

    local hd = homing.components.missile_weapon_data
    assert(hd.name == "Homing") assert(hd.speed == 200)
    assert(hd.turnrate == 10) assert(hd.lifetime == 27)
    assert(hd.homing_range == 1200) assert(hd.damage_at_center == 35)
    assert(hd.damage_at_edge == 5) assert(hd.blast_range == 30)
    assert(hd.fire_count == 1) assert(hd.explodes_on_timeout == false)
    assert(hd.is_delayed_explode == false)
    print("PASS: Homing data verified")

    local nd = nuke.components.missile_weapon_data
    assert(nd.damage_at_center == 160) assert(nd.blast_range == 1000)
    assert(nd.explodes_on_timeout == true) assert(nd.avoid_object_delay == 10)
    print("PASS: Nuke data verified")

    local md = mine.components.missile_weapon_data
    assert(md.is_delayed_explode == true) assert(md.circle_collision == true)
    assert(md.no_lifetime_on_missile == true) assert(md.turnrate == 0)
    assert(md.speed == 100) assert(md.lifetime == 10)
    print("PASS: Mine data verified")

    local ed = emp.components.missile_weapon_data
    assert(ed.explodes_on_timeout == true) assert(ed.damage_type == "EMP")
    print("PASS: EMP data verified")

    local vd = hvli.components.missile_weapon_data
    assert(vd.fire_count == 5) assert(vd.turnrate == 0)
    assert(vd.speed == 500) assert(vd.lifetime == 13.5)
    print("PASS: HVLI data verified")

    -- Create a custom missile type
    local custom = MissileWeaponData()
        :setName("TestMissile")
        :setSpeed(300):setTurnrate(5):setLifetime(20)
        :setColor(128, 128, 0, 255):setHomingRange(800)
        :setFireSound("sfx/test_fire.wav"):setRadarTrace("radar/blip.png")
        :setDamageAtCenter(50):setDamageAtEdge(10):setBlastRange(100)
        :setExplosionSfx("sfx/explosion.wav"):setRadarSignature(0.5, 0.5, 0.0)
        :setFireCount(2):setDamageType("Kinetic"):setOrder(99)
        :setLocaleName("Test Missile")

    assert(custom, "custom creation failed")
    assert(getMissileWeaponData("TestMissile"), "custom lookup failed")
    rebuildMissileWeaponData()
    print("PASS: Custom missile type created and registry rebuilt")
    assert(getMissileWeaponData("TestMissile"), "custom lookup failed after rebuild")
    print("PASS: Custom missile type accessible after registry rebuild")

    assert(findMissileWeaponData("Homing"), "findMissileWeaponData(Homing) failed")
    print("PASS: findMissileWeaponData C++ binding works")

    -- Create a ship with missile tubes using the standard API
    local ship = CpuShip()
        :setFaction("Human Navy")
        :setTemplate("Flavia")
        :setCallSign("TestShip")
        :setWeaponTubeCount(2)
        :setWeaponStorageMax("Homing", 20)
        :setWeaponStorage("Homing", 15)
        :setWeaponStorageMax("TestMissile", 10)
        :setWeaponStorage("TestMissile", 7)
        :setWeaponStorageMax("Nuke", 5)
        :setWeaponStorage("Nuke", 3)
        :weaponTubeAllowMissle(0, "Homing")
        :weaponTubeAllowMissle(0, "TestMissile")
        :weaponTubeAllowMissle(1, "Nuke")
        :setWeaponTubeExclusiveFor(1, "TestMissile")

    -- Verify storage via Entity methods (uses C++ globals internally)
    local homing_stock = ship:getWeaponStorage("Homing")
    local homing_max = ship:getWeaponStorageMax("Homing")
    local nuke_stock = ship:getWeaponStorage("Nuke")
    print("Homing stock/max: " .. tostring(homing_stock) .. "/" .. tostring(homing_max))
    print("Nuke stock: " .. tostring(nuke_stock))
    assert(homing_stock == 15, "FAIL: homing stock should be 15")
    assert(homing_max == 20, "FAIL: homing max should be 20")
    assert(nuke_stock == 3, "FAIL: nuke stock should be 3")
    print("PASS: Default type storage via Entity methods")

    -- Verify custom type storage works via Entity methods
    local custom_stock = ship:getWeaponStorage("TestMissile")
    local custom_max = ship:getWeaponStorageMax("TestMissile")
    print("TestMissile stock/max: " .. tostring(custom_stock) .. "/" .. tostring(custom_max))
    assert(custom_stock == 7, "FAIL: TestMissile stock should be 7")
    assert(custom_max == 10, "FAIL: TestMissile max should be 10")
    print("PASS: Custom type storage via Entity methods")

    -- Verify tube masks via C++ globals (Entity methods are setters, not getters)
    assert(weaponTubeAllowMissile(ship, 0, "Homing") == true, "FAIL: tube 0 should allow Homing")
    assert(weaponTubeAllowMissile(ship, 0, "TestMissile") == true, "FAIL: tube 0 should allow TestMissile")
    assert(weaponTubeAllowMissile(ship, 1, "TestMissile") == true, "FAIL: tube 1 should allow TestMissile")
    assert(weaponTubeAllowMissile(ship, 1, "Nuke") == false, "FAIL: tube 1 should disallow Nuke after exclusive")
    assert(weaponTubeAllowMissile(ship, 1, "Homing") == false, "FAIL: tube 1 should disallow Homing after exclusive")
    print("PASS: Tube masks work for custom types via C++ globals")

    -- Verify C++ globals work directly
    assert(getWeaponStorage(ship, "TestMissile") == 7, "FAIL: global getWeaponStorage")
    assert(getWeaponStorageMax(ship, "TestMissile") == 10, "FAIL: global getWeaponStorageMax")
    print("PASS: C++ storage globals produce correct values")

    assert(weaponTubeAllowMissile(ship, 1, "TestMissile") == true, "FAIL: global weaponTubeAllowMissile")
    assert(weaponTubeAllowMissile(ship, 1, "Homing") == false, "FAIL: global weaponTubeAllowMissile")
    print("PASS: C++ tube mask globals produce correct values")

    -- Create a player ship with 5 tubes (4 forward, 1 rear-facing exclusively for mines)
    local player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Atlantis")
        :setCallSign("TestPlayer")
        :setWeaponTubeCount(5)
        :setWeaponStorageMax("Homing", 30):setWeaponStorage("Homing", 25)
        :setWeaponStorageMax("Nuke", 10):setWeaponStorage("Nuke", 8)
        :setWeaponStorageMax("Mine", 15):setWeaponStorage("Mine", 12)
        :setWeaponStorageMax("EMP", 8):setWeaponStorage("EMP", 6)
        :setWeaponStorageMax("HVLI", 20):setWeaponStorage("HVLI", 18)
        :setWeaponStorageMax("TestMissile", 12):setWeaponStorage("TestMissile", 9)
    :setWeaponTubeDirection(4, 180):setWeaponTubeExclusiveFor(4, "Mine")

    -- Verify player ship stocks
    assert(player:getWeaponStorage("Homing") == 25, "FAIL: player Homing stock")
    assert(player:getWeaponStorage("Nuke") == 8, "FAIL: player Nuke stock")
    assert(player:getWeaponStorage("Mine") == 12, "FAIL: player Mine stock")
    assert(player:getWeaponStorage("EMP") == 6, "FAIL: player EMP stock")
    assert(player:getWeaponStorage("HVLI") == 18, "FAIL: player HVLI stock")
    assert(player:getWeaponStorage("TestMissile") == 9, "FAIL: player TestMissile stock")
    print("PASS: Player ship stocks verified")

    -- Verify tube 4 is exclusively mines (rear-facing)
    assert(weaponTubeAllowMissile(player, 4, "Mine") == true, "FAIL: tube 4 should allow Mines")
    assert(weaponTubeAllowMissile(player, 4, "Homing") == false, "FAIL: tube 4 should NOT allow Homing")
    assert(weaponTubeAllowMissile(player, 4, "Nuke") == false, "FAIL: tube 4 should NOT allow Nuke")
    assert(weaponTubeAllowMissile(player, 4, "EMP") == false, "FAIL: tube 4 should NOT allow EMP")
    assert(weaponTubeAllowMissile(player, 4, "HVLI") == false, "FAIL: tube 4 should NOT allow HVLI")
    assert(weaponTubeAllowMissile(player, 4, "TestMissile") == false, "FAIL: tube 4 should NOT allow TestMissile")
    print("PASS: Tube 4 exclusively allows Mines")

    -- Verify first 4 tubes allow all types (default)
    for tube = 0, 3 do
        assert(weaponTubeAllowMissile(player, tube, "Homing") == true, "FAIL: tube " .. tube .. " should allow Homing")
        assert(weaponTubeAllowMissile(player, tube, "Nuke") == true, "FAIL: tube " .. tube .. " should allow Nuke")
        assert(weaponTubeAllowMissile(player, tube, "Mine") == true, "FAIL: tube " .. tube .. " should allow Mine")
        assert(weaponTubeAllowMissile(player, tube, "EMP") == true, "FAIL: tube " .. tube .. " should allow EMP")
        assert(weaponTubeAllowMissile(player, tube, "HVLI") == true, "FAIL: tube " .. tube .. " should allow HVLI")
        assert(weaponTubeAllowMissile(player, tube, "TestMissile") == true, "FAIL: tube " .. tube .. " should allow TestMissile")
    end
    print("PASS: First 4 tubes allow all missile types")

    print("=== ALL TESTS PASSED ===")
end

function update(delta)
end
