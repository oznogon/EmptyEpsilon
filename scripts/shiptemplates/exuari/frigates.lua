--[[               Exuari Frigates
Exuari strike frigates are warp-drive equipped vessels built for quick strikes.
They are fast and agile, but lack rear shields. These ships operate as
raiders and skirmishers rather than front-line combatants.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Racer")
    :setLocaleName(_("ship", "Racer"))
    :setClass(_("class", "Frigate"), _("subclass", "Strike"))
template:setModel("small_frigate_1"):setRadarTrace("exuari_1.png")
template:setDescription(
    _(
        "The Exuari alpha striker 'Racer' is a warp-drive equipped Figter build for quick strikes. This spacecraft runs on a small crew and is often used as scout, interceptor or to perform preemptive attacks. It's fast, it's agile, but the striker beams do not cause an extreme amount of damage. Like all strikers, it lacks in rear shields."
    )
)
--                  Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 40, -5, 1000.0, 6.0, 6)
template:setBeam(1, 40, 5, 1000.0, 6.0, 6)
template:setHull(50)
template:setShields(50, 30)
template:setSpeed(70, 12, 12)
template:setWarpSpeed(600)

local variation = template:copy("Hunter"):setLocaleName(_("ship", "Hunter"))
variation:setDescription(
    _(
        "The Exuari beta striker 'Hunter' is a warp-drive equipped reinforement fighter. This spacecraft runs on a small crew and is often sent into battle to aid other Exuari ships when they engage in combat. It has an extra pair of striker beams and improved front shields. It's fast, it's agile, and can clean up what is left of the enemies fleet after an initial strike."
    )
)
variation:setModel("small_frigate_4"):setRadarTrace("exuari_4.png")
variation:setBeam(2, 50, -15, 1000.0, 6.0, 6)
variation:setBeam(3, 50, 15, 1000.0, 6.0, 6)
variation:setShields(80, 30)
variation:setWarpSpeed(400)

variation = template:copy("Strike"):setLocaleName(_("ship", "Strike"))
variation:setDescription(
    _(
        "The Exuari gamma striker 'Strike' is a warp-drive equipped tactical bomber build for quick strikes against strong shielded targets. This spacecraft runs on a small crew and is equipped with HVLIs and an EMP. It's fast, it's agile, and can do a great amount of damage in short time."
    )
)
variation:setModel("small_frigate_3"):setRadarTrace("exuari_3.png")
variation:setTubes(1, 10.0)
variation:setWeaponStorage("EMP", 1)
variation:setWeaponStorage("HVLI", 2)
variation:setWarpSpeed(300)

variation = template:copy("Dash"):setLocaleName(_("ship", "Dash"))
variation:setDescription(
    _(
        "The Exuari delta striker 'Dash' is a warp-drive equipped endurance bomber build for prolonged strikes. This spacecraft runs on a small crew and combines reinforced front shields with a good amount of HVLIs. It's fast, it's agile, and can take some damage."
    )
)
variation:setModel("small_frigate_5"):setRadarTrace("exuari_5.png")
variation:setTubes(1, 10.0)
variation:setWeaponStorage("HVLI", 4)
variation:setHull(70)
variation:setShields(80, 30)
variation:setWarpSpeed(200)
