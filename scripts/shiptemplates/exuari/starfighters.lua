--[[               Exuari Starfighters
Small single-seat Exuari spacecraft designed for quick strikes and swarm tactics.
These are not naval ships; they are starfighters.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Dagger")
    :setLocaleName(_("ship", "Dagger"))
    :setClass(_("class", "Starfighter"), _("subclass", "Interceptor"))
template:setModel("small_fighter_1")
template:setRadarTrace("exuari_fighter.png")
template:setDescription(
    _(
        "The Exuari fighter 'Dagger' is a single-seated spacecraft, very quick and agile, that does not do a lot of damage, but usually comes in larger groups. They are able to dodge most missiles and attack undefended areas of their enemies ships. However most of the Exuari fighter pilots expect their own death and do not care much about the enemies weapons ranges. Fighters are easy to take out, but should not be underestimated."
    )
)
--                  Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 60, 0, 1000.0, 4.0, 4)
template:setHull(30)
template:setShields(30)
template:setSpeed(120, 30, 25)
template:setDefaultAI("fighter")

local variation = template:copy("Blade"):setLocaleName(_("ship", "Blade"))
variation:setClass(
    _("class", "Starfighter"),
    _("subclass", "Interceptor")
)
variation:setModel("dark_fighter_6")
variation:setDescription(
    _(
        "The Exuari interceptor 'Blade' is a improved fighter, originaly designed to hunt down rougue fighters. Nowadays Blades are often seen as the first attack wave of a larger assault, closely followed by Daggers. Blade pilots are often considered as fearless, but most of them are just consumed by their instinct for hunting."
    )
)
variation:setBeam(0, 60, 0, 1000.0, 4.0, 4)
variation:setBeam(1, 60, 0, 1000.0, 4.0, 4)
variation:setSpeed(130, 35, 30)

template = ShipTemplate()
    :setName("Gunner")
    :setLocaleName(_("ship", "Gunner"))
    :setClass(_("class", "Starfighter"), _("subclass", "Bomber"))
template:setModel("small_fighter_1")
template:setRadarTrace("exuari_fighter.png")
template:setDescription(
    _(
        "The Exuari light bomber 'Gunner' is a single-seated spacecraft, designed to circumvent their enemies defense lines and bring its deadly load to slow moving targets. Gunners are not as agile as other fighters, but still faster than most capitol ships. A group of Gunners can do a lot of damage to a single stationary target if not destroyed before their target is inside their weapons range. Piloting a Gunner is considered to be a recreational (and often lethal) activity within the Exuari society, so don't expect experienced pilots."
    )
)
template:setBeam(0, 60, 0, 1000.0, 4.0, 4)
template:setHull(40)
template:setShields(30)
template:setSpeed(70, 20, 15)
template:setDefaultAI("fighter")
template:setTubes(1, 60.0)
template:setTubeSize(0, "small")
template:setWeaponStorage("HVLI", 1)

variation = template:copy("Shooter"):setLocaleName(_("ship", "Shooter"))
variation:setClass(_("class", "Starfighter"), _("subclass", "Bomber"))
variation:setDescription(
    _(
        "The Exuari bomber 'Shooter' carries two rounds of HVLIs. To keep the vessel at low costs, it has no automatic missile recharge system, so the single pilot has to load the second round manually. Shooter pilots tend to stay on the battlefield, even without ammunition and enjoy death spreading. Due to it's long reload cycle a Shooter may easily be destroyed between its attack runs."
    )
)
variation:setTubeSize(0, "medium")
variation:setWeaponStorage("HVLI", 2)

variation = template:copy("Jagger"):setLocaleName(_("ship", "Jagger"))
variation:setClass(
    _("class", "Starfighter"),
    _("subclass", "Bomber")
)
variation:setDescription(
    _(
        "The Exuari heavy bomber 'Jagger' carries just a single round of improved HVLIs. Those are considered to be hull-penetrating and cause multiple times the damage of Gunner HVLIs."
    )
)
variation:setTubeSize(0, "large")
