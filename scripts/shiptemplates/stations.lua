-- Space station templates

local template = ShipTemplate()
    :setName("Small Station")
    :setLocaleName(_("Small Station"))
    :setModel("space_station_4")
    :setType("station")
    :setRadarTrace("smallstation.png")
    :setDescription(
        _(
            [[Stations of this size are often used as research outposts, listening stations, and security checkpoints. Crews turn over frequently in a small station's cramped accommodatations, but they are small enough to look like ships on many long-range sensors, and organized raiders sometimes take advantage of this by placing small stations in nebulae to serve as raiding bases. They are lightly shielded and vulnerable to swarming assaults.]]
        )
    )
    :setHull(150)
    :setShields(300)

template = ShipTemplate()
    :setName("Medium Station")
    :setLocaleName(_("Medium Station"))
    :setModel("space_station_3")
    :setType("station")
    :setRadarTrace("mediumstation.png")
    :setDescription(
        _(
            [[Large enough to accommodate small crews for extended periods of times, stations of this size are often trading posts, refuelling bases, mining operations, and forward military bases. While their shields are strong, concerted attacks by many ships can bring them down quickly.]]
        )
    )
    :setHull(400)
    :setShields(800)

template = ShipTemplate()
    :setName("Large Station")
    :setLocaleName(_("Large Station"))
    :setModel("space_station_2")
    :setType("station")
    :setRadarTrace("largestation.png")
    :setDescription(
        _(
            [[These spaceborne communities often represent permanent bases in a sector. Stations of this size can be military installations, commercial hubs, deep-space settlements, and small shipyards. Only a concentrated attack can penetrate a large station's shields, and its hull can withstand all but the most powerful weaponry.]]
        )
    )
    :setHull(500)
    :setShields(1000, 1000, 1000)

template = ShipTemplate()
    :setName("Huge Station")
    :setLocaleName(_("Huge Station"))
    :setModel("space_station_1")
    :setType("station")
    :setRadarTrace("hugestation.png")
    :setDescription(
        _(
            [[The size of a sprawling town, stations at this scale represent a faction's center of spaceborne power in a region. They serve many functions at once and represent an extensive investment of time, money, and labor. A huge station's shields and thick hull can keep it intact long enough for reinforcements to arrive, even when faced with an ongoing siege or massive, perfectly coordinated assault.]]
        )
    )
    :setHull(800)
    :setShields(1200, 1200, 1200, 1200)

-- Defense platform
template = ShipTemplate()
    :setName("Defense platform")
    :setLocaleName(_("ship", "Defense platform"))
    :setClass(_("class", "Platform"), _("subclass", "Defense"))
    :setModel("space_station_4")
    :setRadarTrace("smallstation.png")
    :setDescription(
        _(
            [[This stationary defense platform operates like a station, with docking and resupply functions, but is armed with powerful beam weapons and can slowly rotate. Larger systems often use these platforms to resupply patrol ships.]]
        )
    )
    :setHull(150)
    :setShields(120, 120, 120, 120, 120, 120)
    :setSpeed(0, 0.5, 0)
    :setDockClasses(_("class", "Starfighter"), _("class", "Frigate"))
    :setBeam(0, 30, 0, 4000.0, 1.5, 20)
    :setBeam(1, 30, 60, 4000.0, 1.5, 20)
    :setBeam(2, 30, 120, 4000.0, 1.5, 20)
    :setBeam(3, 30, 180, 4000.0, 1.5, 20)
    :setBeam(4, 30, 240, 4000.0, 1.5, 20)
    :setBeam(5, 30, 300, 4000.0, 1.5, 20)

-- Weapons platform
variant = template
    :copy("Weapons platform")
    :setLocaleName(_("ship", "Weapons platform"))
    :setRadarTrace("piranha.png")
    :setDescription(
        _(
            [[This stationary weapons platform resembles a station armed with powerful beam weapons, and it can slowly rotate. Unlike defense platforms, weapons platforms lack docking bays and have a more vulnerable hull.]]
        )
    )
    :setHull(70)
    :setDockClasses()
