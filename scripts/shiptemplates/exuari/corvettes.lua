--[[ Exuari corvettes

Exuari corvettes are ships without FTL capabilities used to defend bases,
build the rear line in an assault, or deliver ordnance from a distance.
They are larger than frigates.
]]

local template = ShipTemplate()
    :setName("Guard")
    :setLocaleName(_("ship", "Guard"))
    :setClass(_("class", "Corvette"), _("subclass", "Escort"))
    :setModel("transport_1_1")
    :setRadarTrace("exuari_frigate_1.png")
    :setDescription(
    _(
        [[The Exuari Guard is not impressive, trying to be a alround escort or defense vessel. It has powering problems, causing the reload cycle of beams and missiles to take longer than expected. The Guard is equipped with turret beams and a large stock of different missiles, including homing missiles and mines.]]
    )
)
template:setHull(70)
template:setShields(50, 40)
template:setSpeed(55, 10, 10)
template:setBeamWeapon(0, 10, -15, 1200, 9, 6)
template:setBeamWeapon(1, 10, 15, 1200, 9, 6)
template:setBeamWeaponTurret(0, 180, -15, 5)
template:setBeamWeaponTurret(1, 180, 15, 5)
template:setTubes(3, 60.0)
template:setWeaponStorage("Mine", 6)
template:setWeaponStorage("HVLI", 20)
template:setWeaponStorage("Homing", 6)
template:setTubeDirection(0, -1):weaponTubeDisallowMissle(0, "Mine")
template:setTubeDirection(1, 1):weaponTubeDisallowMissle(1, "Mine")
template:setTubeDirection(2, 180):setWeaponTubeExclusiveFor(2, "Mine")

template = ShipTemplate()
    :setName("Sentinel")
    :setLocaleName(_("ship", "Sentinel"))
    :setClass(_("class", "Corvette"), _("subclass", "Anti-fighter"))
template:setModel("transport_3_1"):setRadarTrace("exuari_frigate_2.png")
template:setDescription(
    _(
        [[The Exuari Sentinel is an anti-fighter frigate. It has several rapid-firing, low-damage point-defense turret beams to quickly take out starfighters.]]
    )
)
template:setBeamWeapon(0, 20, -9, 1200, 3, 2)
template:setBeamWeapon(1, 20, 9, 1200, 3, 2)
template:setBeamWeapon(2, 20, 50, 1200, 3, 2)
template:setBeamWeapon(3, 20, -50, 1200, 3, 2)
template:setBeamWeaponTurret(0, 180, -9, 5)
template:setBeamWeaponTurret(1, 180, 9, 5)
template:setBeamWeaponTurret(2, 180, 50, 5)
template:setBeamWeaponTurret(3, 180, -50, 5)
template:setHull(70)
template:setShields(50, 40)
template:setSpeed(70, 15, 10)

template = ShipTemplate()
    :setName("Warden")
    :setLocaleName(_("ship", "Warden"))
    :setClass(_("class", "Corvette"), _("subclass", "Artillery"))
template:setModel("transport_4_1"):setRadarTrace("exuari_frigate_3.png")
template:setDescription(
    _(
        [[The Exuari Warden is a heavy artillery frigate, it fires bunches of missiles from forward facing tubes. Only a single point defense turret is present.]]
    )
)
template:setBeamWeapon(0, 20, 0, 1200, 3, 2)
template:setBeamWeaponTurret(0, 270, 0, 5)
template:setHull(50)
template:setShields(30, 30)
template:setSpeed(40, 6, 8)
template:setTubes(5, 15.0)
template:setWeaponStorage("HVLI", 15)
template:setWeaponStorage("Homing", 15)
template:setTubeDirection(0, 0)
template:setTubeDirection(1, -1)
template:setTubeDirection(2, 1)
template:setTubeDirection(3, -2)
template:setTubeDirection(4, 2)

template = ShipTemplate()
    :setName("Flash")
    :setLocaleName(_("ship", "Flash"))
    :setClass(_("class", "Corvette"), _("subclass", "Artillery"))
template:setModel("small_frigate_2"):setRadarTrace("exuari_2.png")
template:setDescription(
    _(
        [[The Exuari Flash is a special artillery sniper, built to deal a large amounts of damage quickly and from a distance before escaping. It's a basic freighter that carries nuclear weapons. Some say, this is what happens to freighters, when they fall into the hands of the Exuari.]]
    )
)
template:setHull(30)
template:setShields(30, 5, 5)
template:setSpeed(50, 6, 20)
template:setTubes(3, 25.0)
template:weaponTubeDisallowMissle(1, "Nuke"):weaponTubeDisallowMissle(2, "Nuke")
template:setWeaponStorage("Homing", 6)
template:setWeaponStorage("Nuke", 2)

local variation = template:copy("Ranger"):setLocaleName(_("ship", "Ranger"))
variation:setDescription(
    _(
        [[The Exuari Ranger is a special sniper, built to deal large amounts of damage over a large area and from a distance before escaping. It's a basic frigate that carries nuclear weapons, even though it's also one of the smallest of all frigate-class ships.]]
    )
)
variation:setSpeed(55, 6, 20)
variation:setTubes(1, 15.0)
variation:setTubeSize(0, "small")
variation:setWeaponStorage("Homing", 0)
variation:setWeaponStorage("Nuke", 4)

variation = template:copy("Buster"):setLocaleName(_("ship", "Buster"))
variation:setDescription(
    _(
        [[The Exuari Buster is a special sniper, built to deal a large amount of damage quickly and from a distance before escaping. It's a basic frigate that carries nuclear weapons, even though it's also one of the smallest of all frigate-class ships.]]
    )
)
variation:setSpeed(50, 6, 20)
variation:setTubes(1, 15.0)
variation:setTubeSize(0, "large")
variation:setWeaponStorage("Nuke", 1)
