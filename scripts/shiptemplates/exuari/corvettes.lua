--[[ Exuari corvettes

Exuari corvettes defend bases, build the rear line in an assault, or deliver
ordnance from a distance. They are larger than frigates and lack FTL capabilities.
]]

local template = ShipTemplate()
    :setName("Guard")
    :setLocaleName(_("ship", "Guard"))
    :setClass(_("class", "Corvette"), _("subclass", "Escort"))
    :setModel("transport_1_1")
    :setRadarTrace("exuari_frigate_1.png")
    :setDescription(
        _(
            [[The Exuari Guard is an all-around escort and defense corvette. Power issues cause its beam and missile systems to take longer than expected to rearm after firing. The Guard is equipped with turreted beams and a diverse and large stock of missiles, including homing missiles and mines.]]
        )
    )
    :setHull(70)
    :setShields(50, 40)
    :setSpeed(55, 10, 10)
    :setBeamWeapon(0, 10, -15, 1200, 9, 6)
    :setBeamWeapon(1, 10, 15, 1200, 9, 6)
    :setBeamWeaponTurret(0, 180, -15, 5)
    :setBeamWeaponTurret(1, 180, 15, 5)
    :setTubes(3, 60.0)
    :setWeaponStorage("Mine", 6)
    :setWeaponStorage("HVLI", 20)
    :setWeaponStorage("Homing", 6)
    :setTubeDirection(0, -1)
    :weaponTubeDisallowMissle(0, "Mine")
    :setTubeDirection(1, 1)
    :weaponTubeDisallowMissle(1, "Mine")
    :setTubeDirection(2, 180)
    :setWeaponTubeExclusiveFor(2, "Mine")

template = ShipTemplate()
    :setName("Sentinel")
    :setLocaleName(_("ship", "Sentinel"))
    :setClass(_("class", "Corvette"), _("subclass", "Anti-fighter"))
    :setModel("transport_3_1")
    :setRadarTrace("exuari_frigate_2.png")
    :setDescription(
        _(
            [[The Exuari Sentinel is an anti-fighter frigate. It has several rapid-firing, low-damage point-defense turret beams to quickly take out starfighters.]]
        )
    )
    :setBeamWeapon(0, 20, -9, 1200, 3, 2)
    :setBeamWeapon(1, 20, 9, 1200, 3, 2)
    :setBeamWeapon(2, 20, 50, 1200, 3, 2)
    :setBeamWeapon(3, 20, -50, 1200, 3, 2)
    :setBeamWeaponTurret(0, 180, -9, 5)
    :setBeamWeaponTurret(1, 180, 9, 5)
    :setBeamWeaponTurret(2, 180, 50, 5)
    :setBeamWeaponTurret(3, 180, -50, 5)
    :setHull(70)
    :setShields(50, 40)
    :setSpeed(70, 15, 10)

template = ShipTemplate()
    :setName("Warden")
    :setLocaleName(_("ship", "Warden"))
    :setClass(_("class", "Corvette"), _("subclass", "Artillery"))
    :setModel("transport_4_1")
    :setRadarTrace("exuari_frigate_3.png")
    :setDescription(
        _(
            [[The Exuari Warden is a heavy artillery corvette that fires volleys of missiles from forward-facing tubes. It has only a single point-defense turret beam weapon.]]
        )
    )
    :setBeamWeapon(0, 20, 0, 1200, 3, 2)
    :setBeamWeaponTurret(0, 270, 0, 5)
    :setHull(50)
    :setShields(30, 30)
    :setSpeed(40, 6, 8)
    :setTubes(5, 15.0)
    :setWeaponStorage("HVLI", 15)
    :setWeaponStorage("Homing", 15)
    :setTubeDirection(0, 0)
    :setTubeDirection(1, -1)
    :setTubeDirection(2, 1)
    :setTubeDirection(3, -2)
    :setTubeDirection(4, 2)

template = ShipTemplate()
    :setName("Flash")
    :setLocaleName(_("ship", "Flash"))
    :setClass(_("class", "Corvette"), _("subclass", "Artillery"))
    :setModel("small_frigate_2")
    :setRadarTrace("exuari_2.png")
    :setDescription(
        _(
            [[The Exuari Flash is a special artillery sniper designed to deal large amounts of damage quickly and from a distance before escaping. Its simple design consists of a freighter hull full of nuclear weapons, and rumors suggest that the Exuari refit captured freighters into Flashes.]]
        )
    )
    :setHull(30)
    :setShields(30, 5, 5)
    :setSpeed(50, 6, 20)
    :setTubes(3, 25.0)
    :weaponTubeDisallowMissle(1, "Nuke")
    :weaponTubeDisallowMissle(2, "Nuke")
    :setWeaponStorage("Homing", 6)
    :setWeaponStorage("Nuke", 2)

local variation = template
    :copy("Ranger")
    :setLocaleName(_("ship", "Ranger"))
    :setDescription(
        _(
            [[The Exuari Ranger is a special artillery sniper designed to deal large amounts of damage quickly and from a distance before escaping. Despite being a basic design and among the smallest corvette-class ships, it also carries nuclear weapons.]]
        )
    )
    :setSpeed(55, 6, 20)
    :setTubes(1, 15.0)
    :setTubeSize(0, "small")
    :setWeaponStorage("Homing", 0)
    :setWeaponStorage("Nuke", 4)

variation = template
    :copy("Buster")
    :setLocaleName(_("ship", "Buster"))
variation
    :setDescription(
        _(
            [[The Exuari Buster is a special artillery sniper designed to deal large amounts of damage quickly and from a distance before escaping. Despite being a basic design and among the smallest corvette-class ships, it also carries nuclear weapons.]]
        )
    )
    :setSpeed(50, 6, 20)
    :setTubes(1, 15.0)
    :setTubeSize(0, "large")
    :setWeaponStorage("Nuke", 1)
