--[[               Exuari Frigates
Exuari strike frigates are warp-drive equipped vessels built for quick strikes.
They are fast and agile, but lack rear shields. These ships operate as
raiders and skirmishers rather than front-line combatants.
----------------------------------------------------------]]

-- Racer
local template = ShipTemplate()
    :setName("Racer")
    :setLocaleName(_("ship", "Racer"))
    :setClass(_("class", "Frigate"), _("subclass", "Strike"))
    :setModel("small_frigate_1")
    :setRadarTrace("exuari_1.png")
    :setDescription(
        _(
            "The Exuari alpha striker 'Racer' is a warp-drive equipped Figter build for quick strikes. This spacecraft runs on a small crew and is often used as scout, interceptor or to perform preemptive attacks. It's fast, it's agile, but the striker beams do not cause an extreme amount of damage. Like all strikers, it lacks in rear shields."
        )
    )
    :setBeam(0, 40, -5, 1000.0, 6.0, 6)
    :setBeam(1, 40, 5, 1000.0, 6.0, 6)
    :setHull(50)
    :setShields(50, 30)
    :setSpeed(70, 12, 12)
    :setWarpSpeed(600)

-- Hunter
local variation = template
    :copy("Hunter")
    :setLocaleName(_("ship", "Hunter"))
variation
    :setDescription(
        _(
            "The Exuari beta striker 'Hunter' is a warp-drive equipped reinforement fighter. This spacecraft runs on a small crew and is often sent into battle to aid other Exuari ships when they engage in combat. It has an extra pair of striker beams and improved front shields. It's fast, it's agile, and can clean up what is left of the enemies fleet after an initial strike."
        )
    )
    :setModel("small_frigate_4")
    :setRadarTrace("exuari_4.png")
    :setBeam(2, 50, -15, 1000.0, 6.0, 6)
    :setBeam(3, 50, 15, 1000.0, 6.0, 6)
    :setShields(80, 30)
    :setWarpSpeed(400)

-- Strike
variation = template
    :copy("Strike")
    :setLocaleName(_("ship", "Strike"))
variation
    :setDescription(
        _(
            "The Exuari gamma striker 'Strike' is a warp-drive equipped tactical bomber build for quick strikes against strong shielded targets. This spacecraft runs on a small crew and is equipped with HVLIs and an EMP. It's fast, it's agile, and can do a great amount of damage in short time."
        )
    )
    :setModel("small_frigate_3")
    :setRadarTrace("exuari_3.png")
    :setTubes(1, 10.0)
    :setWeaponStorage("EMP", 1)
    :setWeaponStorage("HVLI", 2)
    :setWarpSpeed(300)

-- Dash
variation = template
    :copy("Dash")
    :setLocaleName(_("ship", "Dash"))
variation
    :setDescription(
        _(
            "The Exuari delta striker 'Dash' is a warp-drive equipped endurance bomber build for prolonged strikes. This spacecraft runs on a small crew and combines reinforced front shields with a good amount of HVLIs. It's fast, it's agile, and can take some damage."
        )
    )
    :setModel("small_frigate_5")
    :setRadarTrace("exuari_5.png")
    :setTubes(1, 10.0)
    :setWeaponStorage("HVLI", 4)
    :setHull(70)
    :setShields(80, 30)
    :setWarpSpeed(200)
