--[[               Exuari Light Carriers
Exuari carriers are large spacecraft with many defensive features.
They serve as mobile bases for Exuari strike groups, carrying fighters,
frigates, and supplies into battle. They are equipped with slow impulse
drives and can dock smaller ships for refuel and repair.
----------------------------------------------------------]]

local template = ShipTemplate()
    :setName("Ryder")
    :setLocaleName(_("ship", "Ryder"))
    :setModel("Ender Battlecruiser")
    :setClass(_("class", "Light Carrier"), _("subclass", "Escort"))
template:setRadarTrace("battleship.png")
template:setDescription(
    _(
        "The Exuari 'Ryder' is a large carrier spacecraft with many defensive features. It can be docked by smaller ships to refuel or carry them. Unlike a station it is equipped with a slow impulse drive and capable of interstellar travel. It is used as a habitation for Exuari crews and has a hangar bay. A commom Exuari assault strategy is to keep a Ryder off the sensor range of the desired target, while fighters and artillery start from the carrier."
    )
)
--                  Arc, Dir, Range, CycleTime, Dmg
template:setBeam(0, 20, -90, 1200.0, 6.1, 4):setBeamWeaponTurret(0, 160, -90, 5)
template:setBeam(1, 20, -90, 1200.0, 6.0, 4):setBeamWeaponTurret(1, 160, -90, 5)
template:setBeam(2, 20, 90, 1200.0, 6.1, 4):setBeamWeaponTurret(2, 160, 90, 5)
template:setBeam(3, 20, 90, 1200.0, 6.0, 4):setBeamWeaponTurret(3, 160, 90, 5)
template:setBeam(4, 20, -90, 1200.0, 5.9, 4):setBeamWeaponTurret(4, 160, -90, 5)
template:setBeam(5, 20, -90, 1200.0, 6.2, 4):setBeamWeaponTurret(5, 160, -90, 5)
template:setBeam(6, 20, 90, 1200.0, 5.9, 4):setBeamWeaponTurret(6, 160, 90, 5)
template:setBeam(7, 20, 90, 1200.0, 6.2, 4):setBeamWeaponTurret(7, 160, 90, 5)
template:setBeam(8, 20, -90, 1200.0, 6.1, 4):setBeamWeaponTurret(8, 160, -90, 5)
template:setBeam(9, 20, -90, 1200.0, 6.0, 4):setBeamWeaponTurret(9, 160, -90, 5)
template:setBeam(10, 20, 90, 1200.0, 6.1, 4):setBeamWeaponTurret(10, 160, 90, 5)
template:setBeam(11, 20, 90, 1200.0, 6.0, 4):setBeamWeaponTurret(11, 160, 90, 5)
template:setHull(100)
template:setShields(250)
template:setSpeed(20, 1.5, 3)
template:setDockClasses(_("class", "Starfighter"), _("class", "Frigate"), _("class", "Corvette"))
template:setSharesEnergyWithDocked(true)
template:setRepairDocked(true)
template:setRestocksMissilesDocked(true)
template:setRestocksScanProbes(true)

local variation = template:copy("Fortress"):setLocaleName(_("ship", "Fortress"))
variation:setDescription(
    _(
        "The Exuari Fortress is a huge carrier with many defensive features. It can be docked by smaller ships to refuel or carry them. Unlike a station it is equipped with a slow impulse drive. The shields of this base carrier are saied to be undestroyable."
    )
)
--                  Arc, Dir, Range, CycleTime, Dmg
variation
    :setBeam(0, 20, -90, 2400.0, 6.1, 4)
    :setBeamWeaponTurret(0, 160, -90, 5)
variation
    :setBeam(1, 20, -90, 2400.0, 6.0, 4)
    :setBeamWeaponTurret(1, 160, -90, 5)
variation:setBeam(2, 20, 90, 2400.0, 6.1, 4):setBeamWeaponTurret(2, 160, 90, 5)
variation:setBeam(3, 20, 90, 2400.0, 6.0, 4):setBeamWeaponTurret(3, 160, 90, 5)
variation
    :setBeam(4, 20, -90, 2400.0, 5.9, 4)
    :setBeamWeaponTurret(4, 160, -90, 5)
variation
    :setBeam(5, 20, -90, 2400.0, 6.2, 4)
    :setBeamWeaponTurret(5, 160, -90, 5)
variation:setBeam(6, 20, 90, 2400.0, 5.9, 4):setBeamWeaponTurret(6, 160, 90, 5)
variation:setBeam(7, 20, 90, 2400.0, 6.2, 4):setBeamWeaponTurret(7, 160, 90, 5)
variation
    :setBeam(8, 20, -90, 2400.0, 6.1, 4)
    :setBeamWeaponTurret(8, 160, -90, 5)
variation
    :setBeam(9, 20, -90, 2400.0, 6.0, 4)
    :setBeamWeaponTurret(9, 160, -90, 5)
variation
    :setBeam(10, 20, 90, 2400.0, 6.1, 4)
    :setBeamWeaponTurret(10, 160, 90, 5)
variation
    :setBeam(11, 20, 90, 2400.0, 6.0, 4)
    :setBeamWeaponTurret(11, 160, 90, 5)
variation:setShields(2500)
