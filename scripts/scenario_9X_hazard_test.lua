-- Name: Pathfinding Hazard Test
-- Description: Tests AI avoidance of black holes, mines, and asteroids with AvoidObject components.
-- Type: Development

function init()
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Atlantis X23")
        :setPosition(-3000, -2000)
        :setCallSign("Player")

    -- Black hole directly in the path
    BlackHole():setPosition(0, 0)
    print("Black hole at (0,0) with avoid_object range 7000")

    -- Mines in front of the black hole (closer to ship start)
    for i = 1, 5 do
        local angle = math.rad(i * 72)
        Mine():setPosition(-1000 + math.cos(angle) * 400, 0 + math.sin(angle) * 400)
    end

    -- Asteroid cluster on the other side
    for n = 1, 10 do
        local x = 500 + n * 100
        Asteroid():setPosition(x, math.random(-400, 400))
    end

    -- Ship ordered to fly directly through the hazard field
    ally = CpuShip()
        :setTemplate("Phobos T3")
        :setFaction("Human Navy")
        :setPosition(-3000, 0)
        :setRotation(0)
        :setCallSign("Ally")
        :setScanned(true)
        :orderFlyTowards(3000, 0)

    timer = 0
    elapsed = 0
    log_interval = 3
    local ax, ay = ally:getPosition()
    print(string.format("AI ship at (%.0f, %.0f) ordered to (3000, 0). Direct path goes through black hole.", ax, ay))
end

function update(delta)
    timer = timer + delta
    elapsed = elapsed + delta
    if timer > log_interval then
        timer = 0
        local ax, ay = ally:getPosition()
        local dist = distance(ax, ay, 3000, 0)
        print(string.format("[t=%.0fs] Position: (%.0f, %.0f)  dist: %.0f", elapsed, ax, ay, dist))
        if dist < 500 then
            print("=== PASS: Ally reached the target. ===")
        end
    end
end
