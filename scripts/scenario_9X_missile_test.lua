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
    assert(hd.icon == "gui/icons/weapon-homing.png", "Homing icon should be weapon-homing.png")
    print("PASS: Homing data verified")

    local nd = nuke.components.missile_weapon_data
    assert(nd.damage_at_center == 160) assert(nd.blast_range == 1000)
    assert(nd.explodes_on_timeout == true) assert(nd.avoid_object_delay == 10)
    assert(nd.icon == "gui/icons/weapon-nuke.png", "Nuke icon should be weapon-nuke.png")
    print("PASS: Nuke data verified")

    local md = mine.components.missile_weapon_data
    assert(md.is_delayed_explode == true) assert(md.circle_collision == true)
    assert(md.no_lifetime_on_missile == true) assert(md.turnrate == 0)
    assert(md.speed == 100) assert(md.lifetime == 10)
    assert(md.icon == "gui/icons/weapon-mine.png", "Mine icon should be weapon-mine.png")
    print("PASS: Mine data verified")

    local ed = emp.components.missile_weapon_data
    assert(ed.explodes_on_timeout == true) assert(ed.damage_type == "emp")
    assert(ed.icon == "gui/icons/weapon-emp.png", "EMP icon should be weapon-emp.png")
    print("PASS: EMP data verified")

    local vd = hvli.components.missile_weapon_data
    assert(vd.fire_count == 5) assert(vd.turnrate == 0)
    assert(vd.speed == 500) assert(vd.lifetime == 13.5)
    assert(vd.icon == "gui/icons/weapon-hvli.png", "HVLI icon should be weapon-hvli.png")
    print("PASS: HVLI data verified")

    -- Create a custom missile type
    local custom = MissileWeaponData()
        :setName("TestMissile")
        :setIcon("gui/icons/weapon-hvli.png")
        :setSpeed(300):setTurnrate(5):setLifetime(20)
        :setColor(128, 128, 0, 255):setHomingRange(800)
        :setFireSound("sfx/test_fire.wav"):setRadarTrace("radar/blip.png")
        :setDamageAtCenter(50):setDamageAtEdge(10):setBlastRange(100)
        :setExplosionSfx("sfx/explosion.wav"):setRadarSignature(0.5, 0.5, 0.0)
        :setFireCount(2):setDamageType("Kinetic"):setOrder(99)
        :setLocaleName("Test Missile")

    assert(custom, "custom creation failed")
    assert(getMissileWeaponData("TestMissile"), "custom lookup failed")
    local td = getMissileWeaponData("TestMissile").components.missile_weapon_data
    assert(td.icon == "gui/icons/weapon-hvli.png", "TestMissile icon should be weapon-hvli.png")
    rebuildMissileWeaponData()
    print("PASS: Custom missile type created and registry rebuilt")
    assert(getMissileWeaponData("TestMissile"), "custom lookup failed after rebuild")
    td = getMissileWeaponData("TestMissile").components.missile_weapon_data
    assert(td.icon == "gui/icons/weapon-hvli.png", "TestMissile icon should persist after rebuild")
    print("PASS: Custom missile type accessible after registry rebuild")

    -- Create a missile type with Lua callbacks
    -- ref: missileWeaponData.cpp (on_spawn:276, on_collision:284, on_lifetime_expire:292, on_explode:300)
    local callback_missile = MissileWeaponData()
        :setName("CallbackMissile")
        :setIcon("gui/icons/weapon-homing.png")
        :setSpeed(300):setTurnrate(5):setLifetime(3)
        :setColor(255, 0, 0, 255):setHomingRange(800)
        :setDamageAtCenter(50):setDamageAtEdge(10):setBlastRange(200)
        :setFireCount(1):setDamageType("Kinetic"):setOrder(100)
        :setLocaleName("Callback Missile")
        :setPlayer(false)

    local cd = callback_missile.components.missile_weapon_data

    -- All 4 callbacks from MissileWeaponDataRegistry (missileWeaponData.cpp:276-305)
    cd.on_spawn = function(missile)
        print("on_spawn fired: missile=" .. tostring(missile))
    end

    cd.on_collision = function(missile, other)
        print("on_collision fired: missile=" .. tostring(missile) .. " other=" .. tostring(other))
    end

    cd.on_lifetime_expire = function(missile)
        print("on_lifetime_expire fired: " .. tostring(missile))
    end

    cd.on_explode = function(missile)
        print("on_explode fired: " .. tostring(missile))
    end

    rebuildMissileWeaponData()
    assert(getMissileWeaponData("CallbackMissile"), "CallbackMissile not found after rebuild")
    print("PASS: CallbackMissile type created with 4 Lua callbacks assigned")

    -- Verify callbacks are Lua functions on the component
    local cb_data = getMissileWeaponData("CallbackMissile").components.missile_weapon_data
    assert(type(cb_data.on_spawn) == "function", "on_spawn should be a function")
    assert(type(cb_data.on_collision) == "function", "on_collision should be a function")
    assert(type(cb_data.on_lifetime_expire) == "function", "on_lifetime_expire should be a function")
    assert(type(cb_data.on_explode) == "function", "on_explode should be a function")
    assert(cb_data.icon == "gui/icons/weapon-homing.png", "CallbackMissile icon should be weapon-homing.png")
    print("PASS: All 4 callback fields verified as Lua functions on the component")

    -- Create a ship that will fire SpawnTest missiles
    local spawn_test_missile = MissileWeaponData()
        :setName("SpawnTest")
        :setIcon("gui/icons/weapon-homing.png")
        :setSpeed(200):setTurnrate(5):setLifetime(30)
        :setDamageAtCenter(10):setDamageAtEdge(5):setBlastRange(50)

    spawn_test_count = 0
    spawn_test_missile.components.missile_weapon_data.on_spawn = function(missile)
        spawn_test_count = spawn_test_count + 1
        print("PASS: SpawnTest on_spawn fired! count=" .. tostring(spawn_test_count))
    end

    rebuildMissileWeaponData()

    -- Build a ship that fires SpawnTest missiles
    -- Make tube 0 exclusive to SpawnTest so AI doesn't auto-load other types
    spawn_test_ship = CpuShip()
        :setFaction("Human Navy")
        :setTemplate("MP52 Hornet")
        :setCallSign("SpawnTestShip")
        :setWeaponTubeCount(1)
        :setWeaponStorageMax("SpawnTest", 10)
        :setWeaponStorage("SpawnTest", 5)
        :setTubeLoadTime(0, 1.0)
        :setWeaponTubeExclusiveFor(0, "SpawnTest")

    -- Load SpawnTest (fires callback via MissileSystem::spawn after firing)
    commandLoadTube(spawn_test_ship, 0, "SpawnTest")

    -- Verify the callback binding is intact
    local std = getMissileWeaponData("SpawnTest").components.missile_weapon_data
    assert(type(std.on_spawn) == "function", "SpawnTest on_spawn should be a function")
    assert(std.icon == "gui/icons/weapon-homing.png", "SpawnTest icon should be weapon-homing.png")
    print("PASS: SpawnTest callback binding verified")

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

    -- Explicitly allow all non-Mine types on tubes 0-3, then verify
    for tube = 0, 3 do
        player:weaponTubeAllowMissle(tube, "Homing")
        player:weaponTubeAllowMissle(tube, "Nuke")
        player:weaponTubeAllowMissle(tube, "EMP")
        player:weaponTubeAllowMissle(tube, "HVLI")
        player:weaponTubeAllowMissle(tube, "TestMissile")
        player:weaponTubeDisallowMissle(tube, "Mine")
    end
    for tube = 0, 3 do
        assert(weaponTubeAllowMissile(player, tube, "Homing") == true, "FAIL: tube " .. tube .. " should allow Homing")
        assert(weaponTubeAllowMissile(player, tube, "Nuke") == true, "FAIL: tube " .. tube .. " should allow Nuke")
        assert(weaponTubeAllowMissile(player, tube, "Mine") == false, "FAIL: tube " .. tube .. " should NOT allow Mine")
        assert(weaponTubeAllowMissile(player, tube, "EMP") == true, "FAIL: tube " .. tube .. " should allow EMP")
        assert(weaponTubeAllowMissile(player, tube, "HVLI") == true, "FAIL: tube " .. tube .. " should allow HVLI")
        assert(weaponTubeAllowMissile(player, tube, "TestMissile") == true, "FAIL: tube " .. tube .. " should allow TestMissile")
    end
    print("PASS: First 4 tubes allow all missile types except Mine")

    print("=== ALL TESTS PASSED ===")
end

function update(delta)
    -- Tube states: "empty", "loading", "loaded", "unloading", "firing"
    if spawn_test_ship and not spawn_test_ship_fired then
        local tubes = spawn_test_ship.components.mounts
        if tubes and #tubes > 0 then
            local tube = tubes[1]
            if not spawn_test_fired and tube.state == "loaded" and spawn_test_count == 0 then
                commandFireTube(spawn_test_ship, 0, 0)
                spawn_test_fired = true
            end
            if spawn_test_fired then
                local msg = "PASS: on_spawn callback fires via C++ MissileSystem"
                assert(spawn_test_count > 0, "on_spawn should have been triggered")
                print(msg)
                spawn_test_ship_fired = true
            end
        end
    end
end
