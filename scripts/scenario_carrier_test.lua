--[[
entity = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
entity.components.docking_bay = {
    berths = {
        {type = "storage", move_time = 5.0, transfer_rate = 1.0},
        {type = "storage", move_time = 5.0, transfer_rate = 1.0},
        {type = "storage", move_time = 5.0, transfer_rate = 1.0},
        {type = "storage", move_time = 10.0, transfer_rate = 2.0},
        {type = "storage", move_time = 10.0, transfer_rate = 2.0},
        {type = "storage", move_time = 15.0, transfer_rate = 1.5},
        {type = "storage", move_time = 15.0, transfer_rate = 1.5},
        {type = "storage", move_time = 20.0, transfer_rate = 0.5},
        {type = "storage", move_time = 10.0, transfer_rate = 1.0}
    }
}
interval = 5.0
elapsed = 0.0
--]]

carrier = PlayerSpaceship()
    :setFaction("Human Navy")
    :setTemplate("Benedict")
fighter_classes = {
    "Striker",
    "MT52 Hornet",
    "MU52 Hornet",
    "Adder MK5",
    "Adder MK6",
    "Adder MK7",
    "Adder MK8",
    "Adder MK9",
    "WX-Lindworm",
    "ZX-Lindworm"
}

player_fighter = PlayerSpaceship()
    :setFaction("Human Navy")
    :setTemplate("Striker")
    :setCallSign("Player fighter")
    :setWeaponTubeCount(7)
    :weaponTubeAllowMissle(0,"Homing")
    :weaponTubeAllowMissle(1,"Nuke")
    :weaponTubeAllowMissle(2,"Nuke")
    :weaponTubeAllowMissle(3,"EMP")
    :weaponTubeAllowMissle(4,"EMP")
    :weaponTubeAllowMissle(5,"HVLI")
    :weaponTubeAllowMissle(6,"Homing")
    :setWeaponStorageMax("Homing", 4)
    :setWeaponStorageMax("Nuke", 4)
    :setWeaponStorageMax("EMP", 4)
    :setWeaponStorageMax("HVLI", 4)
    :setWeaponStorageMax("Mine", 4)
    :setWeaponStorage("Homing", math.random(1,4))
    :setWeaponStorage("Nuke", math.random(1,4))
    :setWeaponStorage("EMP", math.random(1,4))
    :setWeaponStorage("HVLI", math.random(1,4))
    :setWeaponStorage("Mine", math.random(1,4))
player_fighter
    :setHull(math.random(10, player_fighter:getHullMax()))
moveEntityToInternalBay(player_fighter, carrier)

for i=1,9 do
    local fighter = CpuShip()
        :setFaction("Human Navy")
        :setTemplate(fighter_classes[i])
        :setScannedByFaction("Human Navy", true)
        :setWeaponTubeCount(7)
        :weaponTubeAllowMissle(0,"Homing")
        :weaponTubeAllowMissle(1,"Nuke")
        :weaponTubeAllowMissle(2,"Nuke")
        :weaponTubeAllowMissle(3,"EMP")
        :weaponTubeAllowMissle(4,"EMP")
        :weaponTubeAllowMissle(5,"HVLI")
        :weaponTubeAllowMissle(6,"Homing")
        :setWeaponStorageMax("Homing", 4)
        :setWeaponStorageMax("Nuke", 4)
        :setWeaponStorageMax("EMP", 4)
        :setWeaponStorageMax("HVLI", 4)
        :setWeaponStorageMax("Mine", 4)
        :setWeaponStorage("Homing", math.random(1,4))
        :setWeaponStorage("Nuke", math.random(1,4))
        :setWeaponStorage("EMP", math.random(1,4))
        :setWeaponStorage("HVLI", math.random(1,4))
        :setWeaponStorage("Mine", math.random(1,4))
    fighter
        :setHull(math.random(10, fighter:getHullMax()))
    moveEntityToInternalBay(fighter, carrier)
end
--[[
for i=1,10 do
  local fighter = CpuShip()
    :setFaction("Kraylor")
    :setPosition(2000,2000)
    :setTemplate("Striker")
    :setScannedByFaction("Human Navy", true)
end

function update(delta)
    elapsed = elapsed + delta
    if elapsed > interval then
        entity.components.docking_bay = {
            berths = {
                {type = "hangar", move_time = 5.0, transfer_rate = 1.0},
                {type = "hangar", move_time = 5.0, transfer_rate = 1.0},
                {type = "energy", move_time = 5.0, transfer_rate = 1.0},
                {type = "missiles", move_time = 10.0, transfer_rate = 2.0},
                {type = "thermal", move_time = 10.0, transfer_rate = 2.0},
                {type = "repair", move_time = 15.0, transfer_rate = 1.5},
                {type = "storage", move_time = 15.0, transfer_rate = 1.5},
                {type = "storage", move_time = 20.0, transfer_rate = 0.5},
                {type = "storage", move_time = 10.0, transfer_rate = 1.0}
            }
        }
    end
end
--]]