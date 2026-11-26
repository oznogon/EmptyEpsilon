--[[ CPU Ship Diversification Utility

Created from a desire to have a more diverse set up ships flying around out there.
Some of these are simple tweaks to existing ships. Some are more radically changed.
The intent for the armed ships is for them to be mixed in with the stock armed ships.
I usually end up creating a list of CPU ship templates:

    ship_template = { --ordered by relative strength
        ["Gnat"] = {strength = 2, create = gnat},
        ["Lite Drone"] = {strength = 3, create = droneLite},
        ["Jacket Drone"] = {strength = 4, create = droneJacket},
        [ST.KTLITAN_DRONE] = {strength = 4, create = stockTemplate},
    }

I order them by relative strength. This is an arbitrary value I give each ship to
help create groups of ships that are a consistent degree of difficulty compared to
the player ship or ships in the game. It's the create portion that is more
interesting in this context. With the templates set up in a list like this with the
create function in the list, a ship can be spawned like this:

    local ship = ship_template[selected_template].create(enemyFaction,selected_template)

...where you specify selected_template and enemyFaction using whatever criteria your
scenario requires.

The ship creation function also adds the ship to the science database.

No global variables per se, just the function names themselves. These functions were
cloned from scenario to scenario until I put them in this document in an effort to
reduce the workload on the pull request reviewer.

Version 2.1 --]]
function stockTemplate(enemyFaction, template)
    local ship = CpuShip():setFaction(enemyFaction):setTemplate(template)
    ship:onTakingDamage(function(self, instigator)
        string.format("") --serious proton needs a global context
        if instigator ~= nil then
            self.damage_instigator = instigator
        end
    end)
    return ship
end
--------------------------------------------------------------------------------------------
--  Additional enemy ships with some modifications from the original template parameters  --
--------------------------------------------------------------------------------------------
function atlantisY42(enemyFaction)
    --Relative strength reference number: 60
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ATLANTIS_X23)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Atlantis Y42")
        :setShieldsMax(300, 200, 300, 200) --stronger shields (vs 200,200,200,200)
        :setShields(300, 200, 300, 200)
        :setImpulseMaxSpeed(65) --faster impulse (vs 30)
        :setRotationMaxSpeed(15) --faster maneuver (vs 3.5)
        :setBeamWeapon(2, 80, 190, 1500, 6, 8) --narrower (vs 100)
        :setBeamWeapon(3, 80, 170, 1500, 6, 8) --extra (vs 3 beams)
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
    local ships_key = _("scienceDB", "Ships")
    local corvette_key = _("scienceDB", "Corvette")
    local y42_key = _("scienceDB", "Atlantis Y42")
    local atlantis_key = _("scienceDB", "Atlantis X23")
    local atlantis_y42_db =
        queryScienceDatabase(ships_key, corvette_key, y42_key)
    if atlantis_y42_db == nil then
        local corvette_db = queryScienceDatabase(ships_key, corvette_key)
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry(y42_key)
            atlantis_y42_db =
                queryScienceDatabase(ships_key, corvette_key, y42_key)
            local tube_key = _("scienceDB", "Tube -90")
            local tube2_key = _("scienceDB", " Tube -90")
            local tube3_key = _("scienceDB", "Tube 90")
            local tube4_key = _("scienceDB", " Tube 90")
            local load_val = _("scienceDB", "10 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, corvette_key, atlantis_key), --base ship database entry
                atlantis_y42_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Atlantis Y42 improves on the Atlantis X23 with stronger shields, faster impulse and turn speeds, an extra beam in back and a larger missile stock]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube4_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 50 U", --jump range
                "battleship_destroyer_1_upgraded"
            )
        end
    end
    return ship
end
function barracuda(enemyFaction)
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Barracuda")
        :setHullMax(200) --stronger hull (vs 70)
        :setHull(200)
        :setShieldsMax(200, 100, 100) --stronger shields (vs 50,40)
        :setShields(200, 100, 100)
        :setImpulseMaxSpeed(75) --faster impulse (vs 60)
        :setRotationMaxSpeed(15) --faster maneuver (vs 10)
        :setWeaponTubeCount(16) --more (vs 2)
        :setWeaponTubeDirection(0, 5)
        :setTubeSize(0, "small")
        :setTubeLoadTime(0, 8)
        :setWeaponTubeExclusiveFor(0, "Homing")
        :setWeaponTubeDirection(1, -5)
        :setTubeSize(1, "small")
        :setTubeLoadTime(1, 8)
        :setWeaponTubeExclusiveFor(1, "Homing")
        :setWeaponTubeDirection(2, 0)
        :setTubeSize(2, "small")
        :setTubeLoadTime(2, 7)
        :setWeaponTubeExclusiveFor(2, "Homing")
        :setWeaponTubeDirection(3, 5)
        :setTubeSize(3, "small")
        :setTubeLoadTime(3, 6)
        :setWeaponTubeExclusiveFor(3, "EMP")
        :setWeaponTubeDirection(4, -5)
        :setTubeSize(4, "small")
        :setTubeLoadTime(4, 6)
        :setWeaponTubeExclusiveFor(4, "EMP")
        :setWeaponTubeDirection(5, 0)
        :setTubeSize(5, "small")
        :setTubeLoadTime(5, 5)
        :setWeaponTubeExclusiveFor(5, "EMP")
        :setWeaponTubeDirection(6, 5)
        :setTubeSize(6, "small")
        :setTubeLoadTime(6, 9)
        :setWeaponTubeExclusiveFor(6, "Nuke")
        :setWeaponTubeDirection(7, -5)
        :setTubeSize(7, "small")
        :setTubeLoadTime(7, 9)
        :setWeaponTubeExclusiveFor(7, "Nuke")
        :setWeaponTubeDirection(8, 0)
        :setTubeSize(8, "small")
        :setTubeLoadTime(8, 8)
        :setWeaponTubeExclusiveFor(8, "Nuke")
        :setWeaponTubeDirection(9, 5)
        :setTubeSize(9, "small")
        :setTubeLoadTime(9, 4)
        :setWeaponTubeExclusiveFor(9, "HVLI")
        :setWeaponTubeDirection(10, -5)
        :setTubeSize(10, "small")
        :setTubeLoadTime(10, 4)
        :setWeaponTubeExclusiveFor(10, "HVLI")
        :setWeaponTubeDirection(11, 0)
        :setTubeSize(11, "small")
        :setTubeLoadTime(11, 3)
        :setWeaponTubeExclusiveFor(11, "HVLI")
        :setWeaponTubeDirection(12, -10)
        :setTubeSize(12, "small")
        :setTubeLoadTime(12, 5)
        :setWeaponTubeExclusiveFor(12, "HVLI")
        :setWeaponTubeDirection(13, 10)
        :setTubeSize(13, "small")
        :setTubeLoadTime(13, 5)
        :setWeaponTubeExclusiveFor(13, "HVLI")
        :setWeaponTubeDirection(14, 0)
        :setTubeSize(14, "medium")
        :setTubeLoadTime(14, 5)
        :setWeaponTubeExclusiveFor(14, "Homing")
        :setWeaponTubeDirection(15, 0)
        :setTubeSize(15, "medium")
        :setTubeLoadTime(15, 10)
        :setWeaponTubeExclusiveFor(15, "Nuke")
        :setWeaponStorageMax("Homing", 32) --more (vs 6)
        :setWeaponStorage("Homing", 32)
        :setWeaponStorageMax("EMP", 20) --more (vs 0)
        :setWeaponStorage("EMP", 20)
        :setWeaponStorageMax("Nuke", 18) --more (vs 0)
        :setWeaponStorage("Nuke", 18)
        :setWeaponStorageMax("HVLI", 55) --more (vs 12)
        :setWeaponStorage("HVLI", 55)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local barracuda_key = _("scienceDB", "Barracuda")
    local barracuda_db =
        queryScienceDatabase(ships_key, frigate_key, barracuda_key)
    if barracuda_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then
            frigate_db:addEntry(barracuda_key)
            barracuda_db =
                queryScienceDatabase(ships_key, frigate_key, barracuda_key)
            local small_tubes_0_key = _("scienceDB", "Small tubes 0")
            local small_tubes_0_val =
                _("scienceDB", "7 sec / Homing, 8 sec / Nuke")
            local small_tubes_5_1_key = _("scienceDB", "Small tubes 5 & -5")
            local small_tubes_5_1_val =
                _("scienceDB", "8 sec / Homing, 9 sec / Nuke")
            local small_tube_0_key = _("scienceDB", "Small tube 0")
            local small_tube_0_val = _("scienceDB", "5 sec / EMP")
            local small_tubes_5_2_key = _("scienceDB", " Small tubes 5 & -5")
            local small_tubes_5_2_val = _("scienceDB", "6 sec / EMP")
            local small_tube_0_2_key = _("scienceDB", "  Small tube 0")
            local small_tube_0_2_val = _("scienceDB", "3 sec / HVLI")
            local small_tubes_5_3_key = _("scienceDB", "   Small tubes 5 & -5")
            local small_tubes_5_3_val = _("scienceDB", "4 sec / HVLI")
            local small_tubes_10_key = _("scienceDB", "Small tubes 10 & -10")
            local small_tubes_10_val = _("scienceDB", "5 sec / HVLI")
            local tube_0_key = _("scienceDB", "Tube 0")
            local tube_0_val = _("scienceDB", "5 sec / Homing")
            local tube_0_2_key = _("scienceDB", " Tube 0")
            local tube_0_2_val = _("scienceDB", "10 sec / Nuke")
            local phobos_t3_key = _("scienceDB", "Phobos T3")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_t3_key), --base ship database entry
                barracuda_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Barracuda is a variant of the Phobos T3 with massive upgrades to its shields, hull, missile weapons, and impulse system. It's designed to spray missiles at a prodigious rate.

It barely qualifies as a frigate and is more like a small corvette.]]
                ),
                {
                    { key = small_tubes_0_key, value = small_tubes_0_val }, --torpedo tube direction and load speed
                    { key = small_tubes_5_1_key, value = small_tubes_5_1_val }, --torpedo tube direction and load speed
                    { key = small_tube_0_key, value = small_tube_0_val }, --torpedo tube direction and load speed
                    { key = small_tubes_5_2_key, value = small_tubes_5_2_val }, --torpedo tube direction and load speed
                    { key = small_tube_0_2_key, value = small_tube_0_2_val }, --torpedo tube direction and load speed
                    { key = small_tubes_5_3_key, value = small_tubes_5_3_val }, --torpedo tube direction and load speed
                    { key = small_tubes_10_key, value = small_tubes_10_val }, --torpedo tube direction and load speed
                    { key = tube_0_key, value = tube_0_val }, --torpedo tube direction and load speed
                    { key = tube_0_2_key, value = tube_0_2_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function cruiserdrone(enemyFaction)
    --Relative strength reference number: 23
    --courtesy of Black Wall scenario
    local cruiserdrone_key = _("scienceDB", "Cruiser Drone")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KARNACK)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName(cruiserdrone_key)
        :setHullMax(80)
        :setHull(80) -- stronger (vs 70)
        :setShieldsMax(60, 60)
        :setShields(60, 60) -- stronger (vs 40,40)
        :setImpulseMaxSpeed(70) -- faster (vs 60)
        :setRotationMaxSpeed(15) -- faster spin (vs 6)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local cruiser_key = _("scienceDB", "Cruiser")
    local cruiserdrone_db =
        queryScienceDatabase(ships_key, frigate_key, cruiserdrone_key)
    if cruiserdrone_db == nil then
        local ships_db = queryScienceDatabase(ships_key)
        if ships_db == nil then
            ships_db = ScienceDatabase():setName(ships_key)
            ships_db = queryScienceDatabase(ships_key)
        end
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db == nil then
            frigate_db = ships_db:addEntry(frigate_key)
            frigate_db = queryScienceDatabase(ships_key, frigate_key)
        end
        frigate_db:addEntry(cruiserdrone_key)
        cruiserdrone_db =
            queryScienceDatabase(ships_key, frigate_key, cruiserdrone_key)
        addShipToDatabase(
            queryScienceDatabase(ships_key, frigate_key, cruiser_key), --base ship database entry
            cruiserdrone_db, --modified ship database entry
            ship, --ship just created, long description on the next line
            _(
                "scienceDB",
                [[A Karnack cruiser modifed for target practice with stronger hull and shields, faster impulse, and better maneuverability. Some of these might have slipped out of the automated manufacturing facility to be refurbished for militia use.]]
            ),
            nil, --tube info
            nil, --jump
            "small_frigate_4"
        )
    end
    return ship
end
function cucaracha(enemyFaction)
    --Relative strength reference number: 36
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.APIS)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Cucaracha")
        :setShieldsMax(200, 50, 50, 50, 50, 50) --stronger shields (vs 20)
        :setShields(200, 50, 50, 50, 50, 50)
        :setHullMax(100) --stronger hull (vs 50)
        :setHull(100)
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setAcceleration(30) --faster acceleration (vs 15)
        :setBeamWeapon(0, 60, 0, 1500, 6, 10) --extra rear facing beam
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local cucaracha_key = _("scienceDB", "Cucaracha")
    local tug_key = _("scienceDB", "Apis")
    local cucaracha_db =
        queryScienceDatabase(ships_key, no_class_key, cucaracha_key)
    if cucaracha_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(cucaracha_key)
            cucaracha_db =
                queryScienceDatabase(ships_key, no_class_key, cucaracha_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, tug_key), --base ship database entry
                cucaracha_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Cucaracha is a tug modified for agility, with heavy shields and a heavy beam weapon. It's designed to be difficult to squash.]]
                ),
                nil,
                nil, --jump range
                "space_tug"
            )
        end
    end
    return ship
end
function dreadnought2(enemyFaction)
    --courtesy of Black Wall scenario
    --Relative strength reference number: 85
    local dreadnought2_key = _("scienceDB", "Dreadnought II")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.DREADNOUGHT)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName(dreadnought2_key)
        :setHullMax(200)
        :setHull(200) --stronger (vs 70)
        :setShieldsMax(100, 100, 100, 100, 100) --weaker (vs 300x5)
        :setImpulseMaxSpeed(90) --faster (vs 30)
        :setRotationMaxSpeed(4) --faster (vs 1.5)
        :setWeaponTubeCount(1) --more (vs 0)
        :setTubeLoadTime(0, 15)
        :setWeaponStorageMax("Homing", 8)
        :setWeaponStorage("Homing", 8)
    local ships_key = _("scienceDB", "Ships")
    local dreadnought_class_key = _("scienceDB", "Dreadnought")
    local dreadnought_ship_key = _("scienceDB", "Dreadnought")
    local dreadnought2_db =
        queryScienceDatabase(ships_key, dreadnought_class_key, dreadnought2_key)
    if dreadnought2_db == nil then
        local ships_db = queryScienceDatabase(ships_key)
        if ships_db == nil then
            ships_db = ScienceDatabase():setName(ships_key)
            ships_db = queryScienceDatabase(ships_key)
        end
        local dreadnought_class_db =
            queryScienceDatabase(ships_key, dreadnought_class_key)
        if dreadnought_class_db == nil then
            dreadnought_class_db = ships_db:addEntry(dreadnought_class_key)
            dreadnought_class_db =
                queryScienceDatabase(ships_key, dreadnought_class_key)
        end
        dreadnought_class_db:addEntry(dreadnought2_key)
        dreadnought2_db = queryScienceDatabase(
            ships_key,
            dreadnought_class_key,
            dreadnought2_key
        )
        local tube_key = _("scienceDB", "Tube 0")
        local load_val = _("scienceDB", "15 sec")
        addShipToDatabase(
            queryScienceDatabase(
                ships_key,
                dreadnought_class_key,
                dreadnought_ship_key
            ), --base ship database entry
            dreadnought2_db, --modified ship database entry
            ship, --ship just created, long description on the next line
            _(
                "scienceDB",
                [[A Dreadnought modified to have a stronger hull, weaker shields, and impulse and turn speeds that are about three times faster. A homing missile tube has also been added.]]
            ),
            {
                { key = tube_key, value = load_val }, --torpedo tube direction and load speed
            },
            nil, --jump
            "battleship_destroyer_1_upgraded"
        )
    end
    return ship
end
function droneHeavy(enemyFaction)
    --Relative strength reference number: 5
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Heavy Drone")
        :setHullMax(40) --stronger hull (vs 30)
        :setHull(40)
        :setImpulseMaxSpeed(110) --slower impulse (vs 120)
        :setBeamWeapon(0, 40, 0, 600, 4, 8) --stronger (vs 6) beam
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local heavy_drone_key = _("scienceDB", "Heavy Drone")
    local ktlitan_key = _("scienceDB", "Ktlitan Drone")
    local drone_heavy_db =
        queryScienceDatabase(ships_key, no_class_key, heavy_drone_key)
    if drone_heavy_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(heavy_drone_key)
            drone_heavy_db =
                queryScienceDatabase(ships_key, no_class_key, heavy_drone_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                drone_heavy_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The heavy drone has a stronger hull and beam weapon than the normal Ktlitan Drone, but it also moves slower]]
                ),
                nil, --misc key value pairs
                nil, --jump
                "sci_fi_alien_ship_4"
            )
        end
    end
    return ship
end
function droneJacket(enemyFaction)
    --Relative strength reference number: 4
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Jacket Drone")
        :setShieldsMax(20) --stronger shields (vs none)
        :setShields(20)
        :setImpulseMaxSpeed(110) --slower impulse (vs 120)
        :setBeamWeapon(0, 40, 0, 600, 4, 4) --weaker (vs 6) beam
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local jacket_drone_key = _("scienceDB", "Jacket Drone")
    local ktlitan_key = _("scienceDB", "Ktlitan Drone")
    local drone_jacket_db =
        queryScienceDatabase(ships_key, no_class_key, jacket_drone_key)
    if drone_jacket_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(jacket_drone_key)
            drone_jacket_db =
                queryScienceDatabase(ships_key, no_class_key, jacket_drone_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                drone_jacket_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Jacket Drone is a Ktlitan Drone with a shield. It's also slightly slower and has a slightly weaker beam due to the shield's energy requirements.]]
                ),
                nil, --misc key value pairs
                nil, --jump
                "sci_fi_alien_ship_4"
            )
        end
    end
    return ship
end
function droneLite(enemyFaction)
    --Relative strength reference number: 3
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Lite Drone")
        :setHullMax(20) --weaker hull (vs 30)
        :setHull(20)
        :setImpulseMaxSpeed(130) --faster impulse (vs 120)
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setBeamWeapon(0, 40, 0, 600, 4, 4) --weaker (vs 6) beam
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local lite_drone_key = _("scienceDB", "Lite Drone")
    local ktlitan_key = _("scienceDB", "Ktlitan Drone")
    local drone_lite_db =
        queryScienceDatabase(ships_key, no_class_key, lite_drone_key)
    if drone_lite_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(lite_drone_key)
            drone_lite_db =
                queryScienceDatabase(ships_key, no_class_key, lite_drone_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                drone_lite_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The lite drone was pieced together from scavenged parts of various damaged Ktlitan drones. Compared to a Ktlitan drone, a lite drone has a weaker hull and beam weapon, but a faster turn rate and impulse speed.]]
                ),
                nil, --misc key value pairs
                nil, --jump
                "sci_fi_alien_ship_4"
            )
        end
    end
    return ship
end
function enforcer(enemyFaction)
    --Relative strength reference number: 75
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.BLOCKADE_RUNNER)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Enforcer")
        :setRadarTrace("ktlitan_destroyer.png") --different radar trace
        :setWarpDrive(true) --warp (vs none)
        :setWarpSpeed(600)
        :setImpulseMaxSpeed(100) --faster impulse (vs 60)
        :setRotationMaxSpeed(20) --faster maneuver (vs 15)
        :setShieldsMax(200, 100, 100) --stronger shields (vs 100,150)
        :setShields(200, 100, 100)
        :setHullMax(100) --stronger hull (vs 70)
        :setHull(100)
        :setBeamWeapon(0, 30, 5, 1500, 6, 10) --narrower (vs 60), longer (vs 1000), stronger (vs 8)
        :setBeamWeapon(1, 30, -5, 1500, 6, 10)
        :setBeamWeapon(2, 0, 0, 0, 0, 0) --fewer (vs 4)
        :setBeamWeapon(3, 0, 0, 0, 0, 0)
        :setWeaponTubeCount(3) --more (vs 0)
        :setTubeSize(0, "large") --large (vs normal)
        :setWeaponTubeDirection(1, -15)
        :setWeaponTubeDirection(2, 15)
        :setTubeLoadTime(0, 18)
        :setTubeLoadTime(1, 12)
        :setTubeLoadTime(2, 12)
        :setWeaponStorageMax("Homing", 18) --more (vs 0)
        :setWeaponStorage("Homing", 18)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local enforcer_key = _("scienceDB", "Enforcer")
    local blockade_runner_key = _("scienceDB", "Blockade Runner")
    local enforcer_db =
        queryScienceDatabase(ships_key, frigate_key, enforcer_key)
    if enforcer_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(enforcer_key)
            enforcer_db =
                queryScienceDatabase(ships_key, frigate_key, enforcer_key)
            local tube_key = _("scienceDB", "Large tube 0")
            local tube2_key = _("scienceDB", "Tube -15")
            local tube3_key = _("scienceDB", "Tube 15")
            local load_val = _("scienceDB", "18 sec")
            local load2_val = _("scienceDB", "12 sec")
            addShipToDatabase(
                queryScienceDatabase(
                    ships_key,
                    frigate_key,
                    blockade_runner_key
                ), --base ship database entry
                enforcer_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Enforcer is a highly modified Blockade Runner with a warp drive, stronger shields and hull, boosted impulse engines, and improved turning speed. Three fore-facing missile tubes were also added to fire large homing missiles. This variant removes the Blockade Runner's aft-facing beams to strengthen its fore beams.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load2_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load2_val }, --torpedo tube direction and load speed
                },
                nil, --jump
                "battleship_destroyer_3_upgraded"
            )
            enforcer_db:setImage("radar/ktlitan_destroyer.png") --override default radar image
        end
    end
    return ship
end
function farco3(enemyFaction)
    --Relative strength reference number: 16
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Farco 3")
        :setShieldsMax(60, 40) --stronger shields (vs 50, 40)
        :setShields(60, 40)
        :setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local farco_key = _("scienceDB", "Farco 3")
    local phobos_key = _("scienceDB", "Phobos T3")
    local farco_3_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
    if farco_3_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(farco_key)
            farco_3_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "60 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                farco_3_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 3, the beams are longer and faster and the shields are slightly stronger.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function farco5(enemyFaction)
    --Relative strength reference number: 16
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Farco 5")
        :setShieldsMax(60, 40) --stronger shields (vs 50, 40)
        :setShields(60, 40)
        :setTubeLoadTime(0, 30) --faster (vs 60)
        :setTubeLoadTime(0, 30)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local farco_key = _("scienceDB", "Farco 5")
    local phobos_key = _("scienceDB", "Phobos T3")
    local farco_5_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
    if farco_5_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(farco_key)
            farco_5_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "30 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                farco_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 5, the tubes load faster and the shields are slightly stronger.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function farco8(enemyFaction)
    --Relative strength reference number: 19
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Farco 8")
        :setShieldsMax(80, 50) --stronger shields (vs 50, 40)
        :setShields(80, 50)
        :setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
        :setTubeLoadTime(0, 30) --faster (vs 60)
        :setTubeLoadTime(0, 30)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local farco_key = _("scienceDB", "Farco 8")
    local phobos_key = _("scienceDB", "Phobos T3")
    local farco_8_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
    if farco_8_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(farco_key)
            farco_8_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "30 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                farco_8_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 8, the beams are longer and faster, the tubes load faster and the shields are stronger.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function farco11(enemyFaction)
    --Relative strength reference number: 21
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Farco 11")
        :setShieldsMax(80, 50) --stronger shields (vs 50, 40)
        :setShields(80, 50)
        :setRotationMaxSpeed(15) --faster maneuver (vs 10)
        :setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
        :setBeamWeapon(2, 20, 0, 1800, 5.0, 4.0) --additional sniping beam
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local farco_key = _("scienceDB", "Farco 11")
    local phobos_key = _("scienceDB", "Phobos T3")
    local farco_11_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
    if farco_11_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(farco_key)
            farco_11_db =
                queryScienceDatabase(ships_key, frigate_key, farco_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "60 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                farco_11_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 11, the maneuver speed is faster, the beams are longer and faster, there's an added longer sniping beam and the shields are stronger.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function farco13(enemyFaction)
    --Relative strength reference number: 24
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Farco 13")
        :setShieldsMax(90, 70) --stronger shields (vs 50, 40)
        :setShields(90, 70)
        :setRotationMaxSpeed(15) --faster maneuver (vs 10)
        :setBeamWeapon(0, 90, -15, 1500, 5.0, 6.0) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 5.0, 6.0)
        :setBeamWeapon(2, 20, 0, 1800, 5.0, 4.0) --additional sniping beam
        :setTubeLoadTime(0, 30) --faster (vs 60)
        :setTubeLoadTime(0, 30)
        :setWeaponStorageMax("Homing", 16) --more (vs 6)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 30) --more (vs 20)
        :setWeaponStorage("HVLI", 30)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local farco_key = _("scienceDB", "Farco 13")
    local phobos_key = _("scienceDB", "Phobos T3")
    local farco_13_db = queryScienceDatabase(ships_key, frigate_key, farco_key)
    if farco_13_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(farco_key)
            farco_13_db =
                queryScienceDatabase(ships_key, frigate_key, farco_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "30 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                farco_13_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Farco models are evolutionary changes to the Phobos T3. In the case of the Farco 13, the maneuver speed is faster, the beams are longer and faster, there's an added longer sniping beam, the tubes load faster, there are more missiles and the shields are stronger.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function fighter2(enemyFaction)
    --courtesy of Black Wall scenario
    --Relative strength reference number: 9
    local fighter2_key = _("scienceDB", "Riposte II")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.RIPOSTE)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName(fighter2_key)
        :setBeamWeapon(0, 60, 0, 1000.0, 4.0, 6) --more damage (vs 4)
        :setHullMax(60)
        :setHull(60) --stronger hull (vs 30)
        :setShieldsMax(50)
        :setShields(50) --stronger shields (vs 30)
        :setImpulseMaxSpeed(100) --slower impulse (vs 120)
        :setWeaponTubeCount(1) --more tubes (vs 0)
        :setTubeLoadTime(0, 8)
        :setWeaponStorageMax("Homing", 2)
        :setWeaponStorage("Homing", 2)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local fighter_key = _("scienceDB", "Riposte")
    local fighter2_db =
        queryScienceDatabase(ships_key, starfighter_key, fighter2_key)
    if fighter2_db == nil then
        local ships_db = queryScienceDatabase(ships_key)
        if ships_db == nil then
            ships_db = ScienceDatabase():setName(ships_key)
            ships_db = queryScienceDatabase(ships_key)
        end
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db == nil then
            starfighter_db = ships_db:addEntry(starfighter_key)
            starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        end
        starfighter_db:addEntry(fighter2_key)
        fighter2_db =
            queryScienceDatabase(ships_key, starfighter_key, fighter2_key)
        local tube_key = _("scienceDB", "Tube 0")
        local load_val = _("scienceDB", "8 sec")
        addShipToDatabase(
            queryScienceDatabase(ships_key, starfighter_key, fighter_key), --base ship database entry
            fighter2_db, --modified ship database entry
            ship, --ship just created, long description on the next line
            _(
                "scienceDB",
                [[Ripostes are weak, nimble interceptors with a single beam weapon that become a greater threat when they engage in larger groups. They're often deployed in reconnaissance, patrol, and outpost-defense roles.]]
            ) .. _(
                [[The Riposte II is a more powerful version with stronger beams, hull, and shields and an added homing missile tube. These additions reduce its speed, however.]]
            ),
            {
                { key = tube_key, value = load_val }, --torpedo tube direction and load speed
            },
            nil, --jump
            "small_fighter_1"
        )
    end
    return ship
end
function gnat(enemyFaction)
    --Relative strength reference number: 2
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_DRONE)
        :setTypeName("Gnat")
        :setHullMax(15) --weaker hull (vs 30)
        :setHull(15)
        :setImpulseMaxSpeed(140) --faster impulse (vs 120)
        :setRotationMaxSpeed(25) --faster maneuver (vs 10)
        :setBeamWeapon(0, 40, 0, 600, 4, 3) --weaker (vs 6) beam
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local gnat_key = _("scienceDB", "Gnat")
    local ktlitan_key = _("scienceDB", "Ktlitan Drone")
    local gnat_db = queryScienceDatabase(ships_key, no_class_key, gnat_key)
    if gnat_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(gnat_key)
            gnat_db = queryScienceDatabase(ships_key, no_class_key, gnat_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                gnat_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Gnat is a nimbler version of the Ktlitan Drone. It has half the hull strength, but it moves and turns faster.]]
                ),
                nil, --misc key value pairs
                nil, --jump range
                "sci_fi_alien_ship_4"
            )
        end
    end
    return ship
end
function gunship2(enemyFaction)
    --courtesy of Black Wall scenario
    --Relative strength reference number: 20
    local gunship2_key = _("scienceDB", "Gunship II")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADV_GUNSHIP)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName(gunship2_key)
        :setBeamWeapon(0, 50, -15, 1000.0, 6.0, 10) --more damage (vs 8)
        :setBeamWeapon(1, 50, 15, 1000.0, 6.0, 10)
        :setHullMax(90)
        :setHull(90) --weaker hull (vs 100)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Corvette")
    local adv_gunship_key = _("scienceDB", "Adv. Gunship")
    local gunship2_db =
        queryScienceDatabase(ships_key, frigate_key, gunship2_key)
    if gunship2_db == nil then
        local ships_db = queryScienceDatabase(ships_key)
        if ships_db == nil then
            ships_db = ScienceDatabase():setName(ships_key)
            ships_db = queryScienceDatabase(ships_key)
        end
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db == nil then
            frigate_db = ships_db:addEntry(frigate_key)
            frigate_db = queryScienceDatabase(ships_key, frigate_key)
        end
        frigate_db:addEntry(gunship2_key)
        gunship2_db = queryScienceDatabase(ships_key, frigate_key, gunship2_key)
        local tube_key = _("scienceDB", "Tube 0")
        local tube2_key = _("scienceDB", " Tube 0")
        local load_val = _("scienceDB", "8 sec")
        addShipToDatabase(
            queryScienceDatabase(ships_key, frigate_key, adv_gunship_key), --base ship database entry
            gunship2_db, --modified ship database entry
            ship, --ship just created, long description on the next line
            _(
                [[The Advanced Gunship corvette adds a second homing missile tube to damage targets at range, and dual front-firing beams to finish its foes off. It's designed to quickly take out enemies weaker then itself.]]
            ) .. _(
                [[Version II has stronger beams but a weaker hull.]]                
            ),
            {
                { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
            },
            nil, --jump
            "battleship_destroyer_4_upgraded"
        )
    end
    return ship
end
function hornetFX64(enemyFaction)
    --Relative strength reference number: 8
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.MT52_HORNET)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("FX64 Hornet")
        :setBeamWeapon(0, 15, 0, 1500.0, 4.0, 6.0) --longer and stronger beam (vs 700 & 2)
        :setRotationMaxSpeed(43) --faster maneuver (vs 30)
        :setImpulseMaxSpeed(180) --faster impulse (vs 120)
        :setHullMax(20) --weaker hull (vs 30)
        :setHull(20)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local fx64_hornet_key = _("scienceDB", "FX64 Hornet")
    local hornet_key = _("scienceDB", "MT52 Hornet")
    local hornet_fx64_db =
        queryScienceDatabase(ships_key, starfighter_key, fx64_hornet_key)
    if hornet_fx64_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry(fx64_hornet_key)
            hornet_fx64_db = queryScienceDatabase(
                ships_key,
                starfighter_key,
                fx64_hornet_key
            )
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, hornet_key), --base ship database entry
                hornet_fx64_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The FX64 Hornet is similar to the MT52 and MU52 models. Compared to other Hornet models, its beam weapon has a longer but narrower range and does more damage, its maximum impulse speed and turn rate are faster, and its hull is weaker.]]
                ),
                nil, --misc key value pairs
                nil, --jump
                "WespeScoutYellow"
            )
        end
    end
    return ship
end
function hornetMT55(enemyFaction)
    --Relative strength reference number: 6
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.MT52_HORNET)
        :orderRoaming()
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("MT55 Hornet")
        :setRotationMaxSpeed(29) --slower maneuver (vs 30)
        :setImpulseMaxSpeed(135) --faster impulse (vs 120)
        :setAcceleration(40) --faster acceleration (vs 25)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local mt55_hornet_key = _("scienceDB", "MT55 Hornet")
    local hornet_key = _("scienceDB", "MT52 Hornet")
    local hornet_mt55_db =
        queryScienceDatabase(ships_key, starfighter_key, mt55_hornet_key)
    if hornet_mt55_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then
            starfighter_db:addEntry(mt55_hornet_key)
            hornet_mt55_db = queryScienceDatabase(
                ships_key,
                starfighter_key,
                mt55_hornet_key
            )
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, hornet_key), --base ship database entry
                hornet_mt55_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The MT55 Hornet is similar to the other Hornet models. Its impulse speed is faster but is slower to turn.]]
                ),
                nil,
                nil,
                "WespeScoutYellow"
            )
        end
    end
    return ship
end
function hornetMV52(enemyFaction)
    --Relative strength reference number: 6
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.MT52_HORNET)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("MV52 Hornet")
        :setBeamWeapon(0, 30, 0, 1000.0, 4.0, 3.0) --longer and stronger beam (vs 700 & 2)
        :setRotationMaxSpeed(31) --faster maneuver (vs 30)
        :setImpulseMaxSpeed(130) --faster impulse (vs 120)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local mv52_hornet_key = _("scienceDB", "MV52 Hornet")
    local hornet_key = _("scienceDB", "MT52 Hornet")
    local hornet_mv52_db =
        queryScienceDatabase(ships_key, starfighter_key, mv52_hornet_key)
    if hornet_mv52_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry(mv52_hornet_key)
            hornet_mv52_db = queryScienceDatabase(
                ships_key,
                starfighter_key,
                mv52_hornet_key
            )
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, hornet_key), --base ship database entry
                hornet_mv52_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The MV52 Hornet is similar to the MT52 and MU52 models. Compared to other Hornet models, the beam does more damage, its maximum impulse speed is faster, it turns faster than the MT52, but it's slower than the MU52.]]
                ),
                nil, --misc key value pairs
                nil, --jump
                "WespeScoutYellow"
            )
        end
    end
    return ship
end
function hurricane(enemyFaction)
    --Relative strength reference number: 46
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F8)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Hurricane")
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 40000)
        :setWeaponTubeCount(8) --more (vs 3)
        :setWeaponTubeExclusiveFor(1, "HVLI") --only HVLI (vs any)
        :setWeaponTubeDirection(1, 0) --forward (vs -90)
        :setTubeSize(3, "large")
        :setWeaponTubeDirection(3, -90)
        :setTubeSize(4, "small")
        :setWeaponTubeExclusiveFor(4, "Homing")
        :setWeaponTubeDirection(4, -15)
        :setTubeSize(5, "small")
        :setWeaponTubeExclusiveFor(5, "Homing")
        :setWeaponTubeDirection(5, 15)
        :setWeaponTubeExclusiveFor(6, "Homing")
        :setWeaponTubeDirection(6, -30)
        :setWeaponTubeExclusiveFor(7, "Homing")
        :setWeaponTubeDirection(7, 30)
        :setWeaponStorageMax("Homing", 24) --more (vs 5)
        :setWeaponStorage("Homing", 24)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local hurricane_key = _("scienceDB", "Hurricane")
    local pirahna_key = _("scienceDB", "Piranha F8")
    local hurricane_db =
        queryScienceDatabase(ships_key, frigate_key, hurricane_key)
    if hurricane_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(hurricane_key)
            hurricane_db =
                queryScienceDatabase(ships_key, frigate_key, hurricane_key)
            local tube_key = _("scienceDB", "Large tube 0")
            local tube2_key = _("scienceDB", "Tube 0")
            local tube3_key = _("scienceDB", "Large tube 90")
            local tube4_key = _("scienceDB", "Large tube -90")
            local tube5_key = _("scienceDB", "Small tube -15")
            local tube6_key = _("scienceDB", "Small tube 15")
            local tube7_key = _("scienceDB", "Tube -30")
            local tube8_key = _("scienceDB", "Tube 30")
            local load_val = _("scienceDB", "12 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, pirahna_key), --base ship database entry
                hurricane_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Hurricane is designed to jump in and shower the target with missiles. It is based on the Piranha F8, but with a jump drive, five more weapon tubes mounted in various directions and sizes, and lots more missiles to shoot.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube4_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube5_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube6_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube7_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube8_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 40 U", --jump range
                "HeavyCorvetteRed"
            )
        end
    end
    return ship
end
function jade5(enemyFaction)
    --Relative strength reference number: 15
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADDER_MK5)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Jade 5")
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 35000)
        :setBeamWeapon(2, 70, -30, 600, 5.0, 2.0) --adjust beam direction to match starboard side (vs -35)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local jade5_key = _("scienceDB", "Jade 5")
    local adder_key = _("scienceDB", "Adder MK5")
    local jade_5_db =
        queryScienceDatabase(ships_key, starfighter_key, jade5_key)
    if jade_5_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry(jade5_key)
            jade_5_db =
                queryScienceDatabase(ships_key, starfighter_key, jade5_key)
            local tube_key = _("scienceDB", "Small tube 0")
            local load_val = _("scienceDB", "15 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, adder_key), --base ship database entry
                jade_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Conversions R Us purchased a number of Adder MK 5 ships at auction and added jump drives to them to produce the Jade 5]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 35 U", --jump range
                "AdlerLongRangeScoutYellow"
            )
        end
    end
    return ship
end
function k2breaker(enemyFaction)
    --Relative strength reference number: 55
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_BREAKER)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("K2 Breaker")
        :setHullMax(200) --stronger hull (vs 120)
        :setHull(200)
        :setWeaponTubeCount(3) --more (vs 1)
        :setTubeSize(0, "large") --large (vs normal)
        :setWeaponTubeDirection(1, -30)
        :setWeaponTubeDirection(2, 30)
        :setWeaponTubeExclusiveFor(0, "HVLI") --only HVLI (vs any)
        :setWeaponStorageMax("Homing", 16) --more (vs 0)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 8) --more (vs 5)
        :setWeaponStorage("HVLI", 8)
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local k2_key = _("scienceDB", "K2 Breaker")
    local ktlitan_key = _("scienceDB", "Ktlitan Breaker")
    local k2_breaker_db = queryScienceDatabase(ships_key, no_class_key, k2_key)
    if k2_breaker_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(k2_key)
            k2_breaker_db =
                queryScienceDatabase(ships_key, no_class_key, k2_key)
            local tube_key = _("scienceDB", "Large tube 0")
            local tube2_key = _("scienceDB", "Tube -30")
            local tube3_key = _("scienceDB", "Tube 30")
            local load_val = _("scienceDB", "13 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                k2_breaker_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The K2 Breaker designers took the Ktlitan Breaker and beefed up the hull, added two bracketing tubes, enlarged the center tube and added more missiles to shoot. Should be good for a couple of enemy ships]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump
                "sci_fi_alien_ship_2"
            )
        end
    end
    return ship
end
function k2fighter(enemyFaction)
    --Relative strength reference number: 7
    local k2_key = _("scienceDB", "K2 Fighter")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_FIGHTER)
        :setTypeName(k2_key)
        :setBeamWeapon(0, 60, 0, 1200.0, 2.5, 6) --beams cycle faster (vs 4.0)
        :setHullMax(65) --weaker hull (vs 70)
        :setHull(65)
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local ktlitan_key = _("scienceDB", "Ktlitan Fighter")
    local k2_fighter_db = queryScienceDatabase(ships_key, no_class_key, k2_key)
    if k2_fighter_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(k2_key)
            k2_fighter_db =
                queryScienceDatabase(ships_key, no_class_key, k2_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                k2_fighter_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Enterprising designers published this design specification based on salvaged Ktlitan Fighters. Comparatively, it's got beams that cycle faster, but the hull is a bit weaker.]]
                ),
                nil, --misc key value pairs
                nil, --jump range
                "sci_fi_alien_ship_1"
            )
        end
    end
    return ship
end
function k3fighter(enemyFaction)
    --Relative strength reference number: 8
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.KTLITAN_FIGHTER)
        :setTypeName("K3 Fighter")
        :setBeamWeapon(0, 60, 0, 1200.0, 2.5, 9) --beams cycle faster and damage more (vs 4.0 & 6)
        :setHullMax(60) --weaker hull (vs 70)
        :setHull(60)
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local k3_key = _("scienceDB", "K3 Fighter")
    local ktlitan_key = _("scienceDB", "Ktlitan Fighter")
    local k3_fighter_db = queryScienceDatabase(ships_key, no_class_key, k3_key)
    if k3_fighter_db == nil then
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db ~= nil then --added for translation issues
            no_class_db:addEntry(k3_key)
            k3_fighter_db =
                queryScienceDatabase(ships_key, no_class_key, k3_key)
            addShipToDatabase(
                queryScienceDatabase(ships_key, no_class_key, ktlitan_key), --base ship database entry
                k3_fighter_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Enterprising designers published this design specification based on salvaged Ktlitan Fighters. Comparatively, it's got beams that are stronger and that cycle faster, but the hull is weaker.]]
                ),
                nil, --misc key value pairs
                nil, --jump range
                "sci_fi_alien_ship_1"
            )
        end
    end
    return ship
end
function maniapak(enemyFaction)
    --Relative strength reference number: 34
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADDER_MK5)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Maniapak")
        :setRadarTrace("exuari_fighter.png") --different radar trace
        :setImpulseMaxSpeed(70) --slower impulse (vs 80)
        :setWeaponTubeCount(9) --more (vs 1)
        :setWeaponTubeDirection(0, 0)
        :setWeaponTubeDirection(1, -10)
        :setWeaponTubeDirection(2, 10)
        :setWeaponTubeDirection(3, 0)
        :setWeaponTubeDirection(4, -12)
        :setWeaponTubeDirection(5, 12)
        :setWeaponTubeDirection(6, 0)
        :setWeaponTubeDirection(7, -15)
        :setWeaponTubeDirection(8, 15)
        :setTubeSize(0, "small")
        :setTubeSize(1, "small")
        :setTubeSize(2, "small")
        :setTubeSize(6, "large")
        :setTubeSize(7, "large")
        :setTubeSize(8, "large")
        :setTubeLoadTime(0, 15)
        :setTubeLoadTime(1, 16)
        :setTubeLoadTime(2, 17)
        :setTubeLoadTime(3, 18)
        :setTubeLoadTime(4, 19)
        :setTubeLoadTime(5, 20)
        :setTubeLoadTime(6, 21)
        :setTubeLoadTime(7, 22)
        :setTubeLoadTime(8, 23)
        :setWeaponStorageMax("Homing", 27) --more (vs 0)
        :setWeaponStorage("Homing", 27)
        :setWeaponStorageMax("EMP", 18) --more (vs 0)
        :setWeaponStorage("EMP", 18)
        :setWeaponStorageMax("Nuke", 27) --more (vs 0)
        :setWeaponStorage("Nuke", 27)
        :setWeaponStorageMax("HVLI", 36) --more (vs 4)
        :setWeaponStorage("HVLI", 36)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local maniapak_key = _("scienceDB", "Maniapak")
    local adder_key = _("scienceDB", "Adder MK5")
    local maniapak_db =
        queryScienceDatabase(ships_key, starfighter_key, maniapak_key)
    if maniapak_db == nil then
        local fighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if fighter_db ~= nil then
            fighter_db:addEntry(maniapak_key)
            maniapak_db =
                queryScienceDatabase(ships_key, starfighter_key, maniapak_key)
            local tube_key = _("scienceDB", "Small tube 0")
            local tube2_key = _("scienceDB", "Small tube -10")
            local tube3_key = _("scienceDB", "Small tube 10")
            local tube4_key = _("scienceDB", "Tube 0")
            local tube5_key = _("scienceDB", "Tube -12")
            local tube6_key = _("scienceDB", "Tube 12")
            local tube7_key = _("scienceDB", "Large tube 0")
            local tube8_key = _("scienceDB", "Large tube -15")
            local tube9_key = _("scienceDB", "Large tube 15")
            local load_val = _("scienceDB", "15 sec")
            local load2_val = _("scienceDB", "16 sec")
            local load3_val = _("scienceDB", "17 sec")
            local load4_val = _("scienceDB", "18 sec")
            local load5_val = _("scienceDB", "19 sec")
            local load6_val = _("scienceDB", "20 sec")
            local load7_val = _("scienceDB", "21 sec")
            local load8_val = _("scienceDB", "22 sec")
            local load9_val = _("scienceDB", "23 sec")
            local storage_key = _("scienceDB", "Missile Storage")
            local storage_val = _("scienceDB", "H:27 E:18 N:27 L:36")
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, adder_key), --base ship database entry
                maniapak_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Maniapak is an extreme modification of an Adder MK5 and a Blade. A maniacal designer was tasked with packing as many missiles as possible in this tiny starfighter frame. This record has yet to be beaten. Unfortunately, this ship is often a danger to friends as well as foes.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube size, direction and load speed
                    { key = tube2_key, value = load2_val }, --torpedo tube size, direction and load speed
                    { key = tube3_key, value = load3_val }, --torpedo tube size, direction and load speed
                    { key = tube4_key, value = load4_val },
                    { key = tube5_key, value = load5_val },
                    { key = tube6_key, value = load6_val },
                    { key = tube7_key, value = load7_val },
                    { key = tube8_key, value = load8_val },
                    { key = tube9_key, value = load9_val },
                    { key = storage_key, value = storage_val },
                },
                nil,
                "AdlerLongRangeScoutYellow"
            )
            maniapak_db:setImage("radar/exuari_fighter.png") --override default radar image
        end
    end
    return ship
end
function phobosR2(enemyFaction)
    --Relative strength reference number: 13
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Phobos R2")
        :setWeaponTubeCount(1) --one tube (vs 2)
        :setWeaponTubeDirection(0, 0)
        :setImpulseMaxSpeed(55) --slower impulse (vs 60)
        :setRotationMaxSpeed(15) --faster maneuver (vs 10)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local phobos_r2_key = _("scienceDB", "Phobos R2")
    local phobos_key = _("scienceDB", "Phobos T3")
    local phobos_r2_db =
        queryScienceDatabase(ships_key, frigate_key, phobos_r2_key)
    if phobos_r2_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(phobos_r2_key)
            phobos_r2_db =
                queryScienceDatabase(ships_key, frigate_key, phobos_r2_key)
            local tube_key = _("scienceDB", "Tube 0")
            local load_val = _("scienceDB", "60 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                phobos_r2_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Phobos R2 model is similar to the Phobos T3. It's got a faster turn speed, but only one missile tube]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function phobosT4(enemyFaction)
    --Relative strength reference number: 18
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PHOBOS_T3)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Phobos T4")
        :setRotationMaxSpeed(20) --faster maneuver (vs 10)
        :setShieldsMax(80, 30) --stronger shields (vs 50,40)
        :setShields(80, 30)
        :setBeamWeapon(0, 90, -15, 1500, 6, 6) --longer (vs 1200), faster (vs 8)
        :setBeamWeapon(1, 90, 15, 1500, 6, 6)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local t4_key = _("scienceDB", "Phobos T4")
    local phobos_key = _("scienceDB", "Phobos T3")
    local phobos_t4_db = queryScienceDatabase(ships_key, frigate_key, t4_key)
    if phobos_t4_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(t4_key)
            phobos_t4_db = queryScienceDatabase(ships_key, frigate_key, t4_key)
            local tube_key = _("scienceDB", "Tube -1")
            local tube2_key = _("scienceDB", "Tube 1")
            local load_val = _("scienceDB", "60 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, phobos_key), --base ship database entry
                phobos_t4_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Phobos T4 makes some simple improvements on the Phobos T3: faster maneuver, stronger front shields, though weaker rear shields and longer and faster beam weapons]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AtlasHeavyFighterYellow"
            )
        end
    end
    return ship
end
function predator(enemyFaction)
    --Relative strength reference number: 42
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F8)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Predator")
        :setShieldsMax(100, 100) --stronger shields (vs 30,30)
        :setShields(100, 100)
        :setHullMax(80) --stronger hull (vs 70)
        :setHull(80)
        :setImpulseMaxSpeed(65) --faster impulse (vs 40)
        :setRotationMaxSpeed(15) --faster maneuver (vs 6)
        :setJumpDrive(true)
        :setJumpDriveRange(5000, 35000)
        :setBeamWeapon(0, 90, 0, 1000, 6, 4) --more (vs 0)
        :setBeamWeapon(1, 90, 180, 1000, 6, 4)
        :setWeaponTubeCount(8) --more (vs 3)
        :setWeaponTubeDirection(0, -60)
        :setWeaponTubeDirection(1, -90)
        :setWeaponTubeDirection(2, -90)
        :setWeaponTubeDirection(3, 60)
        :setWeaponTubeDirection(4, 90)
        :setWeaponTubeDirection(5, 90)
        :setWeaponTubeDirection(6, -120)
        :setWeaponTubeDirection(7, 120)
        :setWeaponTubeExclusiveFor(0, "Homing")
        :setWeaponTubeExclusiveFor(1, "Homing")
        :setWeaponTubeExclusiveFor(2, "Homing")
        :setWeaponTubeExclusiveFor(3, "Homing")
        :setWeaponTubeExclusiveFor(4, "Homing")
        :setWeaponTubeExclusiveFor(5, "Homing")
        :setWeaponTubeExclusiveFor(6, "Homing")
        :setWeaponTubeExclusiveFor(7, "Homing")
        :setWeaponStorageMax("Homing", 32) --more (vs 5)
        :setWeaponStorage("Homing", 32)
        :setWeaponStorageMax("HVLI", 0) --less (vs 10)
        :setWeaponStorage("HVLI", 0)
        :setRadarTrace("missile_cruiser.png") --different radar trace
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local predator_key = _("scienceDB", "Predator")
    local pirahna_key = _("scienceDB", "Piranha F8")
    local predator_db =
        queryScienceDatabase(ships_key, frigate_key, predator_key)
    if predator_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(predator_key)
            predator_db =
                queryScienceDatabase(ships_key, frigate_key, predator_key)
            local tube_key = _("scienceDB", "Large tube -60")
            local tube2_key = _("scienceDB", "Tube -90")
            local tube3_key = _("scienceDB", "Large tube -90")
            local tube4_key = _("scienceDB", "Large tube 60")
            local tube5_key = _("scienceDB", "Tube 90")
            local tube6_key = _("scienceDB", "Large tube 90")
            local tube7_key = _("scienceDB", "Tube -120")
            local tube8_key = _("scienceDB", "Tube 120")
            local load_val = _("scienceDB", "12 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, pirahna_key), --base ship database entry
                predator_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Predator is a significantly improved Piranha F8. Stronger shields and hull, faster impulse and turning speeds, a jump drive, beam weapons, eight missile tubes pointing in six directions and a large number of homing missiles to shoot.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube4_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube5_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube6_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube7_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube8_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 35 U" --jump range
            )
            predator_db:setImage("radar/missile_cruiser.png") --override default radar image
            predator_db:setModelDataName("HeavyCorvetteRed")
        end
    end
    return ship
end
function shepherd(enemyFaction)
    --Relative strength reference number: 6
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.RIPOSTE)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Shepherd")
        :setBeamWeapon(0, 10, 0, 3000, 4, 4) --narrower (vs 60), longer (vs 1000)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local shepherd_key = _("scienceDB", "Shepherd")
    local fighter_key = _("scienceDB", "Riposte")
    local shepherd_db =
        queryScienceDatabase(ships_key, starfighter_key, shepherd_key)
    if shepherd_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then
            starfighter_db:addEntry(shepherd_key)
            shepherd_db =
                queryScienceDatabase(ships_key, starfighter_key, shepherd_key)
            local exuari_key = _("scienceDB", "Exuari")
            local dagger_key = _("scienceDB", "Dagger")
            addShipToDatabase(
                queryScienceDatabase(ships_key, exuari_key, dagger_key), --base ship database entry
                shepherd_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Shepherd is a Fighter with a long narrow beam. Tactical recommendation: hack the impulse engines]]
                ),
                nil, --misc key value pairs
                nil, --jump range
                "small_fighter_1"
            )
        end
    end
    return ship
end
function starhammerIII(enemyFaction)
    --Relative strength reference number: 85
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.STARHAMMER_II)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Starhammer III")
        :setBeamWeapon(4, 60, 180, 1500, 8, 11) --extra rear facing beam
        :setTubeSize(0, "large")
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 36) --more (vs 20)
        :setWeaponStorage("HVLI", 36)
    local ships_key = _("scienceDB", "Ships")
    local corvette_key = _("scienceDB", "Corvette")
    local starhammer3_key = _("scienceDB", "Starhammer III")
    local starhammer2_key = _("scienceDB", "Starhammer II")
    local starhammer_iii_db =
        queryScienceDatabase(ships_key, corvette_key, starhammer3_key)
    if starhammer_iii_db == nil then
        local corvette_db = queryScienceDatabase(ships_key, corvette_key)
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry(starhammer3_key)
            starhammer_iii_db =
                queryScienceDatabase(ships_key, corvette_key, starhammer3_key)
            local tube_key = _("scienceDB", "Large tube 0")
            local tube2_key = _("scienceDB", "Tube 0")
            local load_val = _("scienceDB", "10 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, corvette_key, starhammer2_key), --base ship database entry
                starhammer_iii_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The designers of the Starhammer III modified the Starhammer II to add a rear-facing beam, enlarge one of the missile tubes, and increase its missile stocks.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 50 U", --jump range
                "battleship_destroyer_4_upgraded"
            )
        end
    end
    return ship
end
function starhammerV(enemyFaction)
    --Relative strength reference number: 90
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.STARHAMMER_II)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Starhammer V")
        :setImpulseMaxSpeed(65) --faster impulse (vs 35)
        :setRotationMaxSpeed(15) --faster maneuver (vs 6)
        :setShieldsMax(450, 350, 250, 250, 350) --stronger shields (vs 450, 350, 150, 150, 350)
        :setShields(450, 350, 250, 250, 350)
        :setBeamWeapon(4, 60, 180, 1500, 8, 11) --extra rear facing beam
        :setWeaponStorageMax("Homing", 16) --more (vs 4)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("HVLI", 36) --more (vs 20)
        :setWeaponStorage("HVLI", 36)
    local ships_key = _("scienceDB", "Ships")
    local corvette_key = _("scienceDB", "Corvette")
    local starhammerV_key = _("scienceDB", "Starhammer V")
    local starhammer2_key = _("scienceDB", "Starhammer II")
    local starhammer_v_db =
        queryScienceDatabase(ships_key, corvette_key, starhammerV_key)
    if starhammer_v_db == nil then
        local corvette_db = queryScienceDatabase(ships_key, corvette_key)
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry(starhammerV_key)
            starhammer_v_db =
                queryScienceDatabase(ships_key, corvette_key, starhammerV_key)
            local tube_key = _("scienceDB", "Tube 0")
            local tube2_key = _("scienceDB", " Tube 0")
            local load_val = _("scienceDB", "10 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, corvette_key, starhammer2_key), --base ship database entry
                starhammer_v_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Starhammer V recognizes common modifications made in the field to the Starhammer II: stronger shields, faster impulse and turning speeds, additional rear beam and more missiles to shoot. These changes make the Starhammer V a force to be reckoned with.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                },
                "5 - 50 U", --jump range
                "battleship_destroyer_4_upgraded"
            )
        end
    end
    return ship
end
function tempest(enemyFaction)
    --Relative strength reference number: 30
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.PIRANHA_F12)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Tempest")
        :setWeaponTubeCount(10) --four more tubes (vs 6)
        :setWeaponTubeDirection(0, -88) --5 per side
        :setWeaponTubeDirection(1, -89) --slight angle spread
        :setWeaponTubeDirection(3, 88) --3 for HVLI each side
        :setWeaponTubeDirection(4, 89) --2 for homing and nuke each side
        :setWeaponTubeDirection(6, -91)
        :setWeaponTubeDirection(7, -92)
        :setWeaponTubeDirection(8, 91)
        :setWeaponTubeDirection(9, 92)
        :setWeaponTubeExclusiveFor(7, "HVLI")
        :setWeaponTubeExclusiveFor(9, "HVLI")
        :setWeaponStorageMax("Homing", 16) --more (vs 6)
        :setWeaponStorage("Homing", 16)
        :setWeaponStorageMax("Nuke", 8) --more (vs 0)
        :setWeaponStorage("Nuke", 8)
        :setWeaponStorageMax("HVLI", 34) --more (vs 20)
        :setWeaponStorage("HVLI", 34)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local tempest_key = _("scienceDB", "Tempest")
    local pirahna_key = _("scienceDB", "Piranha F12")
    local tempest_db = queryScienceDatabase(ships_key, frigate_key, tempest_key)
    if tempest_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(tempest_key)
            tempest_db =
                queryScienceDatabase(ships_key, frigate_key, tempest_key)
            local tube_key = _("scienceDB", "Large tube -88")
            local tube2_key = _("scienceDB", "Tube -89")
            local tube3_key = _("scienceDB", "Large tube -90")
            local tube4_key = _("scienceDB", "Large tube 88")
            local tube5_key = _("scienceDB", "Tube 89")
            local tube6_key = _("scienceDB", "Large tube 90")
            local tube7_key = _("scienceDB", "Tube -91")
            local tube8_key = _("scienceDB", "Tube -92")
            local tube9_key = _("scienceDB", "Tube 91")
            local tube10_key = _("scienceDB", "Tube 92")
            local load_val = _("scienceDB", "15 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, pirahna_key), --base ship database entry
                tempest_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Loosely based on the Piranha F12, the Tempest adds four more broadside tubes (two on each side), more HVLIs, more homing missiles and 8 nukes.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube4_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube5_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube6_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube7_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube8_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube9_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube10_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump
                "HeavyCorvetteRed"
            )
        end
    end
    return ship
end
function touchy(enemyFaction)
    --Relative strength reference number: 7
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.RIPOSTE)
        :onTakingDamage(function(self, instigator)
            string.format("") --serious proton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Touchy")
        :setBeamWeapon(0, 12, 0, 2200, 9.0, 9.0) --narrower (vs 60), longer (vs 1000), slower (vs 4),  stronger (vs 4)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local touchy_key = _("scienceDB", "Touchy")
    local touchy_db =
        queryScienceDatabase(ships_key, starfighter_key, touchy_key)
    if touchy_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then
            starfighter_db:addEntry(touchy_key)
            touchy_db =
                queryScienceDatabase(ships_key, starfighter_key, touchy_key)
            local exuari_key = _("scienceDB", "Exuari")
            local dagger_key = _("scienceDB", "Dagger")
            addShipToDatabase(
                queryScienceDatabase(ships_key, exuari_key, dagger_key), --base ship database entry
                touchy_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Touchy is a Riposte-model fighter with a highly modified beam weapon made narrower, longer, slower, and stronger.]]
                ),
                nil, --misc key value pairs
                nil, --jump range
                "small_fighter_1"
            )
        end
    end
    return ship
end
function tyr(enemyFaction)
    --Relative strength reference number: 150
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.BATTLESTATION)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Tyr")
        :setImpulseMaxSpeed(50) --faster impulse (vs 30)
        :setRotationMaxSpeed(10) --faster maneuver (vs 1.5)
        :setShieldsMax(400, 300, 300, 400, 300, 300) --stronger shields (vs 300, 300, 300, 300, 300)
        :setShields(400, 300, 300, 400, 300, 300)
        :setHullMax(100) --stronger hull (vs 70)
        :setHull(100)
        :setBeamWeapon(0, 90, -60, 2500, 6, 8) --stronger beams, broader coverage
        :setBeamWeapon(1, 90, -120, 2500, 6, 8)
        :setBeamWeapon(2, 90, 60, 2500, 6, 8)
        :setBeamWeapon(3, 90, 120, 2500, 6, 8)
        :setBeamWeapon(4, 90, -60, 2500, 6, 8)
        :setBeamWeapon(5, 90, -120, 2500, 6, 8)
        :setBeamWeapon(6, 90, 60, 2500, 6, 8)
        :setBeamWeapon(7, 90, 120, 2500, 6, 8)
        :setBeamWeapon(8, 90, -60, 2500, 6, 8)
        :setBeamWeapon(9, 90, -120, 2500, 6, 8)
        :setBeamWeapon(10, 90, 60, 2500, 6, 8)
        :setBeamWeapon(11, 90, 120, 2500, 6, 8)
    local ships_key = _("scienceDB", "Ships")
    local dreadnought_key = _("scienceDB", "Dreadnought")
    local tyr_key = _("scienceDB", "Tyr")
    local battlestation_key = _("scienceDB", "Battlestation")
    local tyr_db = queryScienceDatabase(ships_key, dreadnought_key, tyr_key)
    if tyr_db == nil then
        local corvette_db = queryScienceDatabase(ships_key, dreadnought_key)
        if corvette_db ~= nil then --added for translation issues
            corvette_db:addEntry(tyr_key)
            tyr_db = queryScienceDatabase(ships_key, dreadnought_key, tyr_key)
            addShipToDatabase(
                queryScienceDatabase(
                    ships_key,
                    dreadnought_key,
                    battlestation_key
                ), --base ship database entry
                tyr_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Tyr is the shipyard's answer to Admiral Konstatz's casual statement that the Battlestation model was too slow to be effective. The shipyards improved on the Battlestation by fitting the Tyr with more than twice the impulse speed and more than six times the turn speed. They threw in stronger shields and hull and wider beam coverage just to show that they could.]]
                ),
                nil,
                "5 - 50 U", --jump range
                "Ender Battlecruiser"
            )
        end
    end
    return ship
end
function waddle5(enemyFaction)
    --Relative strength reference number: 15
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.ADDER_MK5)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Waddle 5")
        :setWarpDrive(true)
        :setBeamWeapon(2, 70, -30, 600, 5.0, 2.0) --adjust beam direction to match starboard side (vs -35)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local waddle5_key = _("scienceDB", "Waddle 5")
    local adder_key = _("scienceDB", "Adder MK5")
    local waddle_5_db =
        queryScienceDatabase(ships_key, starfighter_key, waddle5_key)
    if waddle_5_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry(waddle5_key)
            waddle_5_db =
                queryScienceDatabase(ships_key, starfighter_key, waddle5_key)
            local tube_key = _("scienceDB", "Small tube 0")
            local load_val = _("scienceDB", "15 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, adder_key), --base ship database entry
                waddle_5_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[Conversions R Us purchased a number of Adder MK 5 ships at auction and added warp drives to them to produce the Waddle 5.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "AdlerLongRangeScoutYellow"
            )
        end
    end
    return ship
end
function weaponsplatform2(enemyFaction)
    --courtesy of Black Wall scenario
    --Relative strength reference number: 50
    local platform2_key = _("scienceDB", "Weapons platform II")
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.WEAPONS_PLATFORM)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName(platform2_key)
        :setBeamWeapon(0, 30, 0, 4000.0, 3.5, 10) --slower cycle (vs 1.5), less damage (vs 20)
        :setBeamWeapon(1, 30, 60, 4000.0, 3.5, 10)
        :setBeamWeapon(2, 30, 120, 4000.0, 3.5, 10)
        :setBeamWeapon(3, 30, 180, 4000.0, 3.5, 10)
        :setBeamWeapon(4, 30, 240, 4000.0, 3.5, 10)
        :setBeamWeapon(5, 30, 300, 4000.0, 3.5, 10)
        :setHullMax(170)
        :setHull(170) --stronger hull (vs 70)
    local ships_key = _("scienceDB", "Ships")
    local no_class_key = _("scienceDB", "No Class")
    local platform_key = _("scienceDB", "Weapons platform")
    local platform2_db =
        queryScienceDatabase(ships_key, no_class_key, platform2_key)
    if platform2_db == nil then
        local ships_db = queryScienceDatabase(ships_key)
        if ships_db == nil then
            ships_db = ScienceDatabase():setName(ships_key)
            ships_db = queryScienceDatabase(ships_key)
        end
        local no_class_db = queryScienceDatabase(ships_key, no_class_key)
        if no_class_db == nil then
            no_class_db = ships_db:addEntry(no_class_key)
            no_class_db = queryScienceDatabase(ships_key, no_class_key)
        end
        no_class_db:addEntry(platform2_key)
        platform2_db =
            queryScienceDatabase(ships_key, no_class_key, platform2_key)
        addShipToDatabase(
            queryScienceDatabase(ships_key, no_class_key, platform_key), --base ship database entry
            platform2_db, --modified ship database entry
            ship, --ship just created, long description on the next line
            _(
                "scienceDB",
                [[The weapons platform is a stationary platform with beam weapons. It's extremely slow to turn, but its beam weapons deal significant damage. The weapons platform II is a modification of the original design with a stronger hull, but moves slower and has weaker beams.]]
            ),
            nil, --tube info
            nil, --jump
            "space_cruiser_4"
        )
    end
    return ship
end
function whirlwind(enemyFaction)
    --Relative strength reference number: 26
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.STORM)
        :onTakingDamage(function(self, instigator)
            string.format("") -- SeriousProton needs a global context
            if instigator ~= nil then
                self.damage_instigator = instigator
            end
        end)
        :setTypeName("Whirlwind")
        :setWeaponTubeCount(9) --more (vs 5)
        :setWeaponTubeDirection(0, -90) --3 left, 3 right, 3 front (vs 5 front)
        :setWeaponTubeDirection(1, -92)
        :setWeaponTubeDirection(2, -88)
        :setWeaponTubeDirection(3, 90)
        :setWeaponTubeDirection(4, 92)
        :setWeaponTubeDirection(5, 88)
        :setWeaponTubeDirection(6, 0)
        :setWeaponTubeDirection(7, 2)
        :setWeaponTubeDirection(8, -2)
        :setWeaponStorageMax("Homing", 36) --more (vs 15)
        :setWeaponStorage("Homing", 36)
        :setWeaponStorageMax("HVLI", 36) --more (vs 15)
        :setWeaponStorage("HVLI", 36)
    local ships_key = _("scienceDB", "Ships")
    local frigate_key = _("scienceDB", "Frigate")
    local whirlwind_key = _("scienceDB", "Whirlwind")
    local storm_key = _("scienceDB", "Storm")
    local whirlwind_db =
        queryScienceDatabase(ships_key, frigate_key, whirlwind_key)
    if whirlwind_db == nil then
        local frigate_db = queryScienceDatabase(ships_key, frigate_key)
        if frigate_db ~= nil then --added for translation issues
            frigate_db:addEntry(whirlwind_key)
            whirlwind_db =
                queryScienceDatabase(ships_key, frigate_key, whirlwind_key)
            local tube_key = _("scienceDB", "Tube -90")
            local tube2_key = _("scienceDB", "Tube -92")
            local tube3_key = _("scienceDB", "Tube -88")
            local tube4_key = _("scienceDB", "Tube  90")
            local tube5_key = _("scienceDB", "Tube  92")
            local tube6_key = _("scienceDB", "Tube  88")
            local tube7_key = _("scienceDB", "Tube   0")
            local tube8_key = _("scienceDB", "Tube   2")
            local tube9_key = _("scienceDB", "Tube  -2")
            local load_val = _("scienceDB", "15 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, frigate_key, storm_key), --base ship database entry
                whirlwind_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The Whirlwind is a heavy artillery cruiser that adds tubes and missiles to the Storm hull. Expect to see lots of missiles.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube4_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube5_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube6_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube7_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube8_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube9_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump range
                "HeavyCorvetteYellow"
            )
        end
    end
    return ship
end
function wzLindworm(enemyFaction)
    --Relative strength reference number: 9
    local ship = CpuShip()
        :setFaction(enemyFaction)
        :setTemplate(ST.WX_LINDWORM)
        :setTypeName("WZ-Lindworm")
        :setWeaponStorageMax("Nuke", 2) --more nukes (vs 0)
        :setWeaponStorage("Nuke", 2)
        :setWeaponStorageMax("Homing", 4) --more homing (vs 1)
        :setWeaponStorage("Homing", 4)
        :setWeaponStorageMax("HVLI", 12) --more HVLI (vs 6)
        :setWeaponStorage("HVLI", 12)
        :setRotationMaxSpeed(12) --slower maneuver (vs 15)
        :setHullMax(45) --weaker hull (vs 50)
        :setHull(45)
    local ships_key = _("scienceDB", "Ships")
    local starfighter_key = _("scienceDB", "Starfighter")
    local wzlindworm_key = _("scienceDB", "WZ-Lindworm")
    local worm_key = _("scienceDB", "WX-Lindworm")
    local wz_lindworm_db =
        queryScienceDatabase(ships_key, starfighter_key, wzlindworm_key)
    if wz_lindworm_db == nil then
        local starfighter_db = queryScienceDatabase(ships_key, starfighter_key)
        if starfighter_db ~= nil then --added for translation issues
            starfighter_db:addEntry(wzlindworm_key)
            wz_lindworm_db =
                queryScienceDatabase(ships_key, starfighter_key, wzlindworm_key)
            local tube_key = _("scienceDB", "Small tube 0")
            local tube2_key = _("scienceDB", "Small tube 1")
            local tube3_key = _("scienceDB", "Small tube -1")
            local load_val = _("scienceDB", "15 sec")
            addShipToDatabase(
                queryScienceDatabase(ships_key, starfighter_key, worm_key), --base ship database entry
                wz_lindworm_db, --modified ship database entry
                ship, --ship just created, long description on the next line
                _(
                    "scienceDB",
                    [[The WZ-Lindworm is essentially the stock WX-Lindworm with additional HVLIs, homing missiles, and nukes. They had to remove some of the armor to fit the additional missiles, so the hull is weaker. Also, the WZ turns a little more slowly than the WX.]]
                ),
                {
                    { key = tube_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube2_key, value = load_val }, --torpedo tube direction and load speed
                    { key = tube3_key, value = load_val }, --torpedo tube direction and load speed
                },
                nil, --jump
                "LindwurmFighterYellow"
            )
        end
    end
    return ship
end
-- unarmed ships
function spaceSedan(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.PERSONNEL_JUMP_FREIGHTER_3)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local sedan_key = _("scienceDB", "Space Sedan")
    ship:setTypeName(sedan_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    addFreighter(sedan_key, ship) --update science database if applicable
    return ship
end
function courier(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.PERSONNEL_FREIGHTER_1)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local courier_key = _("scienceDB", "Courier")
    ship:setTypeName(courier_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
        :setWarpDrive(true)
        :setWarpSpeed(1500)
        :setRotationMaxSpeed(20)
    addFreighter(courier_key, ship) --update science database if applicable
    return ship
end
function workWagon(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.EQUIPMENT_FREIGHTER_2)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local wagon_key = _("scienceDB", "Work Wagon")
    ship:setTypeName(wagon_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
        :setWarpDrive(true)
        :setWarpSpeed(200)
    addFreighter(wagon_key, ship) --update science database if applicable
    return ship
end
function omnibus(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.PERSONNEL_JUMP_FREIGHTER_5)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local omnibus_key = _("scienceDB", "Omnibus")
    ship:setTypeName(omnibus_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
    addFreighter(omnibus_key, ship) --update science database if applicable
    return ship
end
function ladenLorry(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.GOODS_FREIGHTER_2)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local lorry_key = _("scienceDB", "Laden Lorry")
    ship:setTypeName(lorry_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
        :setWarpDrive(true)
        :setWarpSpeed(150)
    addFreighter(lorry_key, ship) --update science database if applicable
    return ship
end
function physicsResearch(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.GARBAGE_FREIGHTER_3)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local physics_key = _("scienceDB", "Physics Research")
    ship:setTypeName(physics_key)
        :setCommsScript("")
        :setCommsFunction(commsShip)
        :setImpulseMaxSpeed(65) --faster impulse (vs 45)
        :setRotationMaxSpeed(10) --faster maneuver (vs 6)
        :setShieldsMax(80, 80) --stronger shields (vs 50, 50)
        :setShields(80, 80)
    addFreighter(physics_key, ship) --update science database if applicable
    return ship
end
function serviceJonque(enemyFaction)
    --Relative strength reference number: 1
    local ship = CpuShip()
        :setTemplate(ST.GARBAGE_JUMP_FREIGHTER_4)
    if enemyFaction ~= nil then
        ship:setFaction(enemyFaction)
    end
    local jonque_key = _("scienceDB", "Service Jonque")
    ship:setTypeName(jonque_key)
        :setCommsScript("")
        :setCommsFunction(commsServiceJonque)
    addFreighter(jonque_key, ship) --update science database if applicable
    return ship
end
-- science database update functions
function genericFreighterScienceInfo(specific_freighter_db, base_db, ship)
    local freighter_key = _("scienceDB", "Freighter")
    local subclass_key = _("scienceDB", "Sub-class")
    local size_key = _("scienceDB", "Size")
    specific_freighter_db:setImage("radar/transport.png")
    specific_freighter_db:setKeyValue(subclass_key, freighter_key)
    specific_freighter_db:setKeyValue(size_key, base_db:getKeyValue(size_key))
    local shields = ship:getShieldCount()
    if shields > 0 then
        local shield_string = ""
        for i = 1, shields do
            if shield_string == "" then
                shield_string =
                    string.format("%i", math.floor(ship:getShieldMax(i - 1)))
            else
                shield_string = string.format(
                    "%s/%i",
                    shield_string,
                    math.floor(ship:getShieldMax(i - 1))
                )
            end
        end
        specific_freighter_db:setKeyValue("Shield", shield_string)
    end
    specific_freighter_db:setKeyValue(
        "Hull",
        string.format("%i", math.floor(ship:getHullMax()))
    )
    specific_freighter_db:setKeyValue(
        "Move speed",
        string.format("%.1f u/min", ship:getImpulseMaxSpeed() * 60 / 1000)
    )
    specific_freighter_db:setKeyValue(
        "Turn speed",
        string.format("%.1f deg/sec", ship:getRotationMaxSpeed())
    )
    if ship:hasJumpDrive() then
        local base_jump_range = base_db:getKeyValue("Jump range")
        if base_jump_range ~= nil and base_jump_range ~= "" then
            specific_freighter_db:setKeyValue("Jump range", base_jump_range)
        else
            specific_freighter_db:setKeyValue("Jump range", "5 - 50 u")
        end
    end
    if ship:hasWarpDrive() then
        specific_freighter_db:setKeyValue(
            "Warp Speed",
            string.format("%.1f u/min", ship:getWarpSpeed() * 60 / 1000)
        )
    end
end
function addFreighters()
    local ships_key = _("scienceDB", "Ships")
    local freighter_key = _("scienceDB", "Freighter")
    local freighter_db = queryScienceDatabase(ships_key, freighter_key)
    if freighter_db == nil then
        local ship_db = queryScienceDatabase(ships_key)
        ship_db:addEntry(freighter_key)
        freighter_db = queryScienceDatabase(ships_key, freighter_key)
        freighter_db:setImage("radar/transport.png")
        freighter_db:setLongDescription(
            _(
                "scienceDB",
                [[Small, medium, and large scale transport ships. These are the working ships that keep commerce going in any sector. They might carry personnel, goods, cargo, equipment, garbage, fuel, research material, etc.]]
            )
        )
    end
    return freighter_db
end
function addFreighter(freighter_type, ship)
    local ships_key = _("scienceDB", "Ships")
    local freighter_key = _("scienceDB", "Freighter")
    local corvette_key = _("scienceDB", "Corvette")
    local sedan_key = _("scienceDB", "Space Sedan")
    local omnibus_key = _("scienceDB", "Omnibus")
    local jonque_key = _("scienceDB", "Service Jonque")
    local courier_key = _("scienceDB", "Courier")
    local wagon_key = _("scienceDB", "Work Wagon")
    local lorry_key = _("scienceDB", "Laden Lorry")
    local physics_key = _("scienceDB", "Physics Research")
    local freighter_db = addFreighters()
    if freighter_type ~= nil then
        if freighter_type == sedan_key then
            local space_sedan_db =
                queryScienceDatabase(ships_key, freighter_key, sedan_key)
            if space_sedan_db == nil then
                local pjf3_key = _("scienceDB", "Personnel Jump Freighter 3")
                freighter_db:addEntry(sedan_key)
                space_sedan_db =
                    queryScienceDatabase(ships_key, freighter_key, sedan_key)
                genericFreighterScienceInfo(
                    space_sedan_db,
                    queryScienceDatabase(ships_key, corvette_key, pjf3_key),
                    ship
                )
                space_sedan_db:setModelDataName("transport_1_3")
                space_sedan_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[The Space Sedan was built around a surplus Personnel Jump Freighter 3. It's modified to provide relatively low-cost transportation primarily for people, but also has a limited amount of cargo space.]]
                    )
                )
            end
        elseif freighter_type == omnibus_key then
            local omnibus_db =
                queryScienceDatabase(ships_key, freighter_key, omnibus_key)
            if omnibus_db == nil then
                local pjf5_key = _("scienceDB", "Personnel Jump Freighter 5")
                freighter_db:addEntry(omnibus_key)
                omnibus_db =
                    queryScienceDatabase(ships_key, freighter_key, omnibus_key)
                genericFreighterScienceInfo(
                    omnibus_db,
                    queryScienceDatabase(ships_key, corvette_key, pjf5_key),
                    ship
                )
                omnibus_db:setModelDataName("transport_1_5")
                omnibus_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[The Omnibus is a Personnel Jump Freighter 5 modified to transport large numbers of passengers of various types along with their luggage and any associated cargo.]]
                    )
                )
            end
        elseif freighter_type == jonque_key then
            local service_jonque_db =
                queryScienceDatabase(ships_key, freighter_key, jonque_key)
            if service_jonque_db == nil then
                local ejf4_key = _("scienceDB", "Equipment Jump Freighter 4")
                freighter_db:addEntry(jonque_key)
                service_jonque_db =
                    queryScienceDatabase(ships_key, freighter_key, jonque_key)
                genericFreighterScienceInfo(
                    service_jonque_db,
                    queryScienceDatabase(
                        ships_key,
                        corvette_key,
                        ST.EQUIPMENT_JUMP_FREIGHTER_4
                    ),
                    ship
                )
                service_jonque_db:setModelDataName("transport_4_4")
                service_jonque_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[The Service Jonque is an Equipment Jump Freighter 4 modified to carry spare parts and equipment as well as the necessary repair personnel. It operates wherever it's needed in order to repair stations and ships.]]
                    )
                )
            end
        elseif freighter_type == courier_key then
            local courier_db =
                queryScienceDatabase(ships_key, freighter_key, courier_key)
            if courier_db == nil then
                local pf1_key = _("scienceDB", "Personnel Freighter 1")
                freighter_db:addEntry(courier_key)
                courier_db =
                    queryScienceDatabase(ships_key, freighter_key, courier_key)
                genericFreighterScienceInfo(
                    courier_db,
                    queryScienceDatabase(ships_key, corvette_key, pf1_key),
                    ship
                )
                courier_db:setModelDataName("transport_1_1")
                courier_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[The Courier is a souped-up Personnel Freighter 1 designed to deliver people and messages very quickly.]]
                    )
                )
            end
        elseif freighter_type == wagon_key then
            local work_wagon_db =
                queryScienceDatabase(ships_key, freighter_key, wagon_key)
            if work_wagon_db == nil then
                local ef2_key = _("scienceDB", "Equipment Freighter 2")
                freighter_db:addEntry(wagon_key)
                work_wagon_db =
                    queryScienceDatabase(ships_key, freighter_key, wagon_key)
                genericFreighterScienceInfo(
                    work_wagon_db,
                    queryScienceDatabase(ships_key, corvette_key, ef2_key),
                    ship
                )
                work_wagon_db:setModelDataName("transport_4_2")
                work_wagon_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[The Work Wagon is a conversion of an Equipment Freighter 2 designed to carry equipment and parts where they are needed for repair or construction.]]
                    )
                )
            end
        elseif freighter_type == lorry_key then
            local laden_lorry_db =
                queryScienceDatabase(ships_key, freighter_key, lorry_key)
            if laden_lorry_db == nil then
                local gf3_key = _("scienceDB", "Goods Freighter 3")
                freighter_db:addEntry(lorry_key)
                laden_lorry_db =
                    queryScienceDatabase(ships_key, freighter_key, lorry_key)
                genericFreighterScienceInfo(
                    laden_lorry_db,
                    queryScienceDatabase(ships_key, corvette_key, gf3_key),
                    ship
                )
                laden_lorry_db:setModelDataName("transport_2_3")
                laden_lorry_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[As a side contract, Conversion R Us put together the Laden Lorry from some recently acquired Goods Freighter 3 hulls. The added warp drive makes for a more versatile goods carrying vessel.]]
                    )
                )
            end
        elseif freighter_type == physics_key then
            local physics_research_db =
                queryScienceDatabase(ships_key, freighter_key, physics_key)
            if physics_research_db == nil then
                local garf3_key = _("scienceDB", "Garbage Freighter 3")
                freighter_db:addEntry(physics_key)
                physics_research_db =
                    queryScienceDatabase(ships_key, freighter_key, physics_key)
                genericFreighterScienceInfo(
                    physics_research_db,
                    queryScienceDatabase(ships_key, corvette_key, garf3_key),
                    ship
                )
                physics_research_db:setModelDataName("transport_3_3")
                physics_research_db:setLongDescription(
                    _(
                        "scienceDB",
                        [[Conversion R Us cleaned up and converted excess freighter hulls into Physics Research vessels. The reduced weight improved the impulse speed and maneuverability.]]
                    )
                )
            end
        end
    end
end
function clarifyExistingScience()
    local weapons_key = _("scienceDB", "Weapons")
    local weapons_db = queryScienceDatabase(weapons_key)
    if weapons_db == nil then
        weapons_db = ScienceDatabase():setName(weapons_key)
    end
    weapons_db:setLongDescription(
        _(
            "scienceDB",
            "This database only covers the basic versions of the missiles used throughout the galaxy.\n\nIt has been reported that some battleships started using larger variations of those missiles. Small fighters and even frigates should not have too much trouble dodging them, but space captains of bigger ships should be wary of their doubled damage potential.\n\nSmaller variations of these missiles have become common in the galaxy, too. Fighter pilots praise their speed and maneuverability, because it gives them an edge against small and fast-moving targets. They only deal half the damage of their basic counterparts, but what good is a missile if it does not hit its target?\n\nSome ships in your fleet have been equipped with these different sized weapons tubes. In some cases, the weapons officer might see a banner on the weapons console describing these tubes using the following shorthand:\n    S = Small\n    M = Medium (the normal sized missile tube)\n    L = Large\nThese letters describe the tube sizes in order from top to bottom."
        )
    )
end

function addShipToDatabase(
    base_db,
    modified_db,
    ship,
    description,
    tube_directions,
    jump_range,
    model_name
)
    max_repeat_loop = 300
    modified_db:setLongDescription(description)
    if base_db ~= nil then
        modified_db:setImage(base_db:getImage())
        local class_key = _("scienceDB", "Class")
        local subclass_key = _("scienceDB", "Sub-class")
        local size_key = _("scienceDB", "Size")
        modified_db:setKeyValue(class_key, base_db:getKeyValue(class_key))
        modified_db:setKeyValue(subclass_key, base_db:getKeyValue(subclass_key))
        modified_db:setKeyValue(size_key, base_db:getKeyValue(size_key))
    end
    local shields = ship:getShieldCount()
    if shields > 0 then
        local shield_string = ""
        for i = 1, shields do
            if shield_string == "" then
                shield_string =
                    string.format("%i", math.floor(ship:getShieldMax(i - 1)))
            else
                shield_string = string.format(
                    "%s/%i",
                    shield_string,
                    math.floor(ship:getShieldMax(i - 1))
                )
            end
        end
        local shield_key = _("scienceDB", "Shield")
        modified_db:setKeyValue(shield_key, shield_string)
    end
    local hull_key = _("scienceDB", "Hull")
    local move_speed_key = _("scienceDB", "Move speed")
    local reverse_move_speed_key = _("scienceDB", "Reverse move speed")
    local turn_speed_key = _("scienceDB", "Turn speed")
    local impulse_forward, impulse_reverse = ship:getImpulseMaxSpeed()
    modified_db:setKeyValue(
        hull_key,
        string.format("%i", math.floor(ship:getHullMax()))
    )
    modified_db:setKeyValue(
        move_speed_key,
        string.format(_("scienceDB", "%.1f u/min"), impulse_forward * 60 / 1000)
    )
    modified_db:setKeyValue(
        reverse_move_speed_key,
        string.format(_("scienceDB", "%.1f u/min"), impulse_reverse * 60 / 1000)
    )
    modified_db:setKeyValue(
        turn_speed_key,
        string.format(
            _("scienceDB", "%.1f deg/sec"),
            ship:getRotationMaxSpeed()
        )
    )
    if ship:hasJumpDrive() then
        local jump_range_key = _("scienceDB", "Jump range")
        if jump_range == nil then
            local base_jump_range = nil
            if base_db ~= nil then
                base_jump_range = base_db:getKeyValue(jump_range_key)
            end
            if base_jump_range ~= nil and base_jump_range ~= "" then
                modified_db:setKeyValue(jump_range_key, base_jump_range)
            else
                modified_db:setKeyValue(jump_range_key, "5 - 50 u")
            end
        else
            modified_db:setKeyValue(jump_range_key, jump_range)
        end
    end
    if ship:hasWarpDrive() then
        local ward_speed_key = _("scienceDB", "Warp Speed")
        modified_db:setKeyValue(
            ward_speed_key,
            string.format(
                _("scienceDB", "%.1f u/min"),
                ship:getWarpSpeed() * 60 / 1000
            )
        )
    end
    local key = ""
    if ship:getBeamWeaponRange(0) > 0 then
        local bi = 0
        local count_repeat_loop = 0
        local no_more_beams = false
        repeat
            local beam_direction = ship:getBeamWeaponDirection(bi)
            if beam_direction > 315 and beam_direction < 360 then
                beam_direction = beam_direction - 360
            end
            local beam_dir =
                string.format("%.1f", ship:getBeamWeaponDirection(bi))
            if ship:getBeamWeaponDirection(bi) % 1 == 0 then
                beam_dir = string.format("%i", ship:getBeamWeaponDirection(bi))
            end
            local beam_arc = string.format("%.1f", ship:getBeamWeaponArc(bi))
            if ship:getBeamWeaponArc(bi) % 1 == 0 then
                beam_arc = string.format("%i", ship:getBeamWeaponArc(bi))
            end
            key = string.format(
                _("scienceDB", "Beam weapon %s:%s"),
                beam_dir,
                beam_arc
            )
            while modified_db:getKeyValue(key) ~= "" do
                key = " " .. key
            end
            modified_db:setKeyValue(
                key,
                string.format(
                    _("scienceDB", "%.1f Dmg / %.1f sec"),
                    ship:getBeamWeaponDamage(bi),
                    ship:getBeamWeaponCycleTime(bi)
                )
            )
            bi = bi + 1
            count_repeat_loop = count_repeat_loop + 1
            no_more_beams = false
            if ship:getBeamWeaponRange(bi) == nil then
                no_more_beams = true
            elseif ship:getBeamWeaponRange(bi) < 1 then
                no_more_beams = true
            end
        until no_more_beams or count_repeat_loop > max_repeat_loop
        if count_repeat_loop > max_repeat_loop then
            print("repeated too many times when going through beams")
        end
    end
    local tubes = ship:getWeaponTubeCount()
    if tubes > 0 then
        if tube_directions ~= nil then
            for i = 1, #tube_directions do
                modified_db:setKeyValue(
                    tube_directions[i].key,
                    tube_directions[i].value
                )
            end
        end
        local missile_types = { "Homing", "Nuke", "Mine", "EMP", "HVLI" }
        for index, missile_type in ipairs(missile_types) do
            local max_storage = ship:getWeaponStorageMax(missile_type)
            if max_storage > 0 then
                modified_db:setKeyValue(
                    string.format(_("scienceDB", "Storage %s"), missile_type),
                    string.format("%i", max_storage)
                )
            end
        end
    end
    if model_name ~= nil then
        modified_db:setModelDataName(model_name)
    end
end
