--[[ Battleships

Battleships are the largest and most powerful combat vessels. They usually
deploy 6 or more shield segments, and many require a crew of more than 250 to
operate.
]]

-- Odin
local template = ShipTemplate()
    :setName("Odin")
    :setLocaleName(_("ship", "Odin"))
    :setClass(_("class", "Battleship"), _("subclass", "Dreadnought"))
    :setModel("space_station_2")
    :setRadarTrace("largestation.png")
    :setDescription(
        _(
            [[The Odin is a "ship" so large and unique that it's almost a class of its own.

The ship is often nicknamed the "all-father", a name that aptly describes the many roles it can fulfill. It's both a supply station and an extremely heavily armored and shielded weapon station capable of annihilating small fleets on its own.

Odin's core contains the largest jump drive ever created. About 150 support crew are needed to operate the jump drive alone, and it takes 5 days of continuous operation to power it.

Due to the enormous cost of this dreadnought, only the richest star systems can build and maintain an Odin, much less a fleet of them.

This machine's primary tactic is to jump into an unsuspecting enemy system and destroy everything before they know what hit them. Despite the extreme cost, it's effective and destructive.]]
        )
    )
    :setJumpDrive(true)
    :setTubes(16, 3.0)
    :setWeaponStorage("Homing", 1000)
    :setHull(2000)
    :setShields(1200, 1200, 1200, 1200, 1200, 1200)
    :setSpeed(0, 1, 0)

for n = 0, 15 do
    template
        :setBeamWeapon(n, 90, n * 22.5, 3200, 3, 10)
        :setTubeDirection(n, n * 22.5)
        :setTubeSize(n, "large")
end

-- Dreadnought
template = ShipTemplate()
    :setName("Dreadnought")
    :setLocaleName(_("ship", "Dreadnought"))
    :setModel("battleship_destroyer_1_upgraded")
    :setClass(_("class", "Battleship"), _("subclass", "Dreadnought"))
    :setRadarTrace("dread.png")
    :setDescription(
        _(
            [[The Dreadnought is a flying fortress. It's slow and maneuvers poorly, but packs an array of forward-facing beam weapons. Attacking it head-on is suicidal.]]
        )
    )
    :setBeam(0, 90, -25, 1500.0, 6.0, 8)
    :setBeam(1, 90, 25, 1500.0, 6.0, 8)
    :setBeam(2, 100, -60, 1000.0, 6.0, 8)
    :setBeam(3, 100, 60, 1000.0, 6.0, 8)
    :setBeam(4, 30, 0, 2000.0, 6.0, 8)
    :setBeam(5, 100, 180, 1200.0, 6.0, 8)
    :setHull(70)
    :setShields(300, 300, 300, 300, 300)
    :setSpeed(30, 1.5, 5)

