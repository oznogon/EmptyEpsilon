-- Name: Fighter Collision Avoidance Test
-- Description: Validates that FighterAI dives at a target and evades without ramming the target or obstacles (mines, other ships) on the way.
-- Type: Development

min_target_dist = 1e9
min_mine_dist = 1e9
min_ship_dist = 1e9
pass_target = 300
pass_obstacle = 300

function init()
    setGameSpeed(4)

    -- Stationary enemy target the fighter is ordered to attack.
    target = CpuShip()
        :setTemplate("Adder MK5")
        :setFaction("Kraylor")
        :setPosition(2000, 0)
        :setRotation(180)
        :setCallSign("Target")
        :setScanned(true)
        :orderIdle()

    -- Friendly cruiser parked in the dive path.
    cruiser = CpuShip()
        :setTemplate("Vindicator")
        :setFaction("Human Navy")
        :setPosition(600, 0)
        :setRotation(0)
        :setCallSign("Cruiser")
        :orderIdle()

    -- Mine directly on the dive line.
    mine = Mine():setPosition(0, 0)

    -- Fighter ordered to attack the target; the direct line (-3000,0)->(2000,0)
    -- passes through the mine at (0,0) and the cruiser at (600,0).
    fighter = CpuShip()
        :setTemplate("MT52 Hornet")
        :setFaction("Human Navy")
        :setAI("fighter")
        :setPosition(-3000, 0)
        :setRotation(0)
        :setCallSign("Fighter")
        :setScanned(true)
        :orderAttack(target)

    timer = 0
    elapsed = 0
    log_interval = 3
    test_duration = 60

    print("=== Fighter Collision Avoidance Test ===")
    print("Fighter (MT52 Hornet, fighter AI) dives from (-3000,0) at target (2000,0).")
    print("Mine at (0,0) and friendly cruiser at (600,0) sit on the dive line.")
    print(string.format("PASS if fighter stays >%d from target and >%d from mine/cruiser.", pass_target, pass_obstacle))
end

function update(delta)
    elapsed = elapsed + delta
    timer = timer + delta

    local fx, fy = fighter:getPosition()
    local tx, ty = target:getPosition()
    local mx, my = 0, 0
    local cx, cy = cruiser:getPosition()

    min_target_dist = math.min(min_target_dist, distance(fx, fy, tx, ty))
    min_mine_dist = math.min(min_mine_dist, distance(fx, fy, mx, my))
    min_ship_dist = math.min(min_ship_dist, distance(fx, fy, cx, cy))

    if timer > log_interval then
        timer = 0
        print(string.format(
            "[t=%4.0fs] Fighter(%.0f,%.0f)  dist->target %.0f  ->mine %.0f  ->cruiser %.0f",
            elapsed, fx, fy,
            distance(fx, fy, tx, ty), distance(fx, fy, mx, my), distance(fx, fy, cx, cy)
        ))
        print(string.format(
            "    minima: target %.0f  mine %.0f  cruiser %.0f",
            min_target_dist, min_mine_dist, min_ship_dist
        ))
    end

    if elapsed >= test_duration then
        local ok = min_target_dist >= pass_target
            and min_mine_dist >= pass_obstacle
            and min_ship_dist >= pass_obstacle
        print("=== Fighter Collision Avoidance Test Summary ===")
        print(string.format("Fighter->target closest approach: %.0f", min_target_dist))
        print(string.format("Fighter->mine   closest approach: %.0f", min_mine_dist))
        print(string.format("Fighter->cruiser closest approach: %.0f", min_ship_dist))
        if ok then
            print("=== PASS: Fighter avoided target and obstacles ===")
        else
            print("=== FAIL: Fighter got too close to something ===")
        end
        shutdownGame()
    end
end
