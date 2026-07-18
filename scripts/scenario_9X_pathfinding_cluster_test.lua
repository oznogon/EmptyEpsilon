-- Name: Pathfinding Cluster Test
-- Description: Validates that the AI pathfinder finds and navigates through a narrow gap in a dense obstacle cluster.
-- Type: Development

function init()
    player = PlayerSpaceship()
        :setFaction("Human Navy")
        :setTemplate("Atlantis X23")
        :setPosition(-3000, 0)
        :setCallSign("Player")

    -- Two large obstacles blocking the direct line from (-3000, 300) to (3000, 0).
    -- SpaceStation at (0, -400) with radius ~800 means it covers up to y=400.
    -- SpaceStation at (0, 600) with radius ~800 means it covers down to y=-200.
    -- These overlap slightly and create a narrow passable corridor.
    SpaceStation()
        :setTemplate("Medium Station")
        :setFaction("Independent")
        :setPosition(0, -400)
        :setRotation(0)
    SpaceStation()
        :setTemplate("Medium Station")
        :setFaction("Independent")
        :setPosition(0, 600)
        :setRotation(0)

    -- A few asteroids scattered to add noise
    for n = 1, 15 do
        Asteroid():setPosition(math.random(-500, 500), math.random(-300, 500))
    end

    -- CPU ally on the left side (y=300), ordered to fly to the right side
    -- The direct line passes between the two stations.
    ally = CpuShip()
        :setTemplate("Phobos T3")
        :setFaction("Human Navy")
        :setPosition(-3000, 300)
        :setRotation(0)
        :setCallSign("Ally")
        :setScanned(true)
        :orderFlyTowards(3000, 0)

    timer = 0
    elapsed = 0
    log_interval = 3
    local ax, ay = ally:getPosition()
    print(
        string.format(
            "Pathfinding Cluster Test: AI at (%.0f, %.0f) must navigate to (3000, 0)",
            ax,
            ay
        )
    )
    print("Medium Stations at (0,-400) and (0,600) with scattered asteroids.")
end

function update(delta)
    timer = timer + delta
    elapsed = elapsed + delta
    if timer > log_interval then
        timer = 0
        local ax, ay = ally:getPosition()
        local dist = distance(ax, ay, 3000, 0)
        print(
            string.format(
                "[t=%.0fs] Position: (%.0f, %.0f)  dist to target: %.0f",
                elapsed,
                ax,
                ay,
                dist
            )
        )
        if dist < 500 then
            print("=== PASS: Ally reached the target. ===")
        end
    end
end
