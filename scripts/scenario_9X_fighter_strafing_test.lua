-- Name: Fighter Strafing Avoidance Test
-- Description: Validates that fighter AI avoids obstacles (mines, asteroids) on its strafing approach to a target.
-- Type: Development

function init()
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Atlantis X23")
        :setPosition(-5000, -2000)
        :setCallSign("Player")

    -- Enemy target at a fixed position
    target_pos_x = 3000
    target_pos_y = 0
    CpuShip()
        :setTemplate("Adder MK5")
        :setFaction("Kraylor")
        :setPosition(target_pos_x, target_pos_y)
        :setRotation(180)
        :setCallSign("Target")
        :setScanned(true)

    -- Obstacles placed DIRECTLY in the fighter's approach path.
    -- The fighter at (-4000, 0) flying to (3000, 0) must go through x=0 to reach the target.
    -- A mine at (0, 0) is directly in the path.
    Mine():setPosition(0, 0)
    -- An asteroid at (1000, 0) is also in the path.
    Asteroid():setPosition(1000, 0)
    -- Another mine at (-1000, 0)
    Mine():setPosition(-1000, 0)

    -- Fighter ordered to attack the target
    fighter = CpuShip()
        :setTemplate("MT52 Hornet")
        :setFaction("Human Navy")
        :setPosition(-4000, 0)
        :setRotation(0)
        :setCallSign("Fighter")
        :setScanned(true)
        :orderFlyTowards(target_pos_x, target_pos_y)

    timer = 0
    elapsed = 0
    log_interval = 2
    print("Fighter at (-4000, 0) ordered to fly to target at (3000, 0).")
    print(
        "Mines at (-1000, 0) and (0, 0), asteroid at (1000, 0) — directly in path."
    )
    print("Fighter should route around them, not fly straight through.")
end

function update(delta)
    timer = timer + delta
    elapsed = elapsed + delta
    if timer > log_interval then
        timer = 0
        local fx, fy = fighter:getPosition()
        local dist = distance(fx, fy, target_pos_x, target_pos_y)
        print(
            string.format(
                "[t=%.0fs] Fighter: (%.0f, %.0f)  dist to target: %.0f",
                elapsed,
                fx,
                fy,
                dist
            )
        )
        if dist < 500 then
            print("Fighter reached attack range of target.")
        end
    end
end
