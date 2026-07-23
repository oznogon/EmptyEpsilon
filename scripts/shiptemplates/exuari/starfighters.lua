--[[ Exuari starfighters

Small single-seat Exuari starfighters designed for quick strikes and swarm tactics.
]]

-- Dagger
local template = ShipTemplate()
    :setName("Dagger")
    :setLocaleName(_("ship", "Dagger"))
    :setClass(
        _("class", "Starfighter"),
        _("subclass", "Interceptor")
    )
    :setModel("small_fighter_1")
    :setRadarTrace("exuari_fighter.png")
    :setDescription(
        _(
            [[The Exuari fighter designated "Dagger" is a very quick and agile single-seated spacecraft. Its weapons don't deal much damage, but Daggers usually attack in larger groups. They can dodge most missiles and attack undefended areas of their enemies' ships.

However, most Exuari fighter pilots expect their own death and don't care much about their enemies' weapons ranges. These fighters are easy to take out individually, but shouldn't be underestimated in large group.]]
        )
    )
    :setBeam(0, 60, 0, 1000.0, 4.0, 4)
    :setHull(30)
    :setShields(30)
    :setSpeed(120, 30, 25)
    :setDefaultAI("fighter")

-- Blade
local variation = template
    :copy("Blade")
    :setLocaleName(_("ship", "Blade"))
    :setModel("dark_fighter_6")
    :setDescription(
        _(
            [[The Exuari interceptor designated "Blade" is a improved fighter originally designed to hunt rogue fighters. Blades now often lead the first attack wave of a larger assault, closely followed by Daggers. Blade pilots are just as fearless as Dagger pilots, but most are simply consumed by their instinct to hunt.]]
        )
    )
    :setBeam(1, 60, 0, 1000.0, 4.0, 4)
    :setSpeed(130, 35, 30)

-- Gunner
template = ShipTemplate()
    :setName("Gunner")
    :setLocaleName(_("ship", "Gunner"))
    :setClass(
        _("class", "Starfighter"),
        _("subclass", "Bomber")
    )
    :setModel("small_fighter_1")
    :setRadarTrace("exuari_fighter.png")
    :setDescription(
        _(
            [[The Exuari light bomber designated "Gunner" is a single-seated spacecraft designed to circumvent their enemies' defensive lines and bring its deadly load to bear on slow-moving targets. Gunners aren't as agile as other fighters, but are still faster than most capital ships. A group of Gunners can quickly damage a single stationary target if not destroyed before their target is inside their weapons range.

Piloting a Gunner is considered a recreational, and often lethal, activity within Exuari society, so don't expect experienced pilots.]]
        )
    )
    :setBeam(0, 60, 0, 1000.0, 4.0, 4)
    :setHull(40)
    :setShields(30)
    :setSpeed(70, 20, 15)
    :setDefaultAI("fighter")
    :setTubes(1, 60.0)
    :setTubeSize(0, "small")
    :setWeaponStorage("HVLI", 1)

-- Shooter
variation = template
    :copy("Shooter")
    :setLocaleName(_("ship", "Shooter"))
    :setDescription(
        _(
            [[The Exuari bomber designated "Shooter" carries two rounds of HVLIs. To keep the vessel at low costs, it has no automatic missile recharge system, so the single pilot has to load the second round manually. Shooter pilots tend to stay on the battlefield, even without ammunition, to enjoy death spreading. Due to its long reload cycle, a Shooter can easily be destroyed between its attack runs.]]
        )
    )
    :setTubeSize(0, "medium")
    :setWeaponStorage("HVLI", 2)

-- Jagger
variation = template
    :copy("Jagger")
    :setLocaleName(_("ship", "Jagger"))
    :setDescription(
        _(
            [[The Exuari heavy bomber designated "Jagger" carries just a single round of improved armor-penetrating HVLIs that cause multiple times the damage of Gunner HVLIs.]]
        )
    )
    :setTubeSize(0, "large")
