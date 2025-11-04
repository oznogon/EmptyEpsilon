carrier = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Benedict")

for i=1,10 do
  local fighter = CpuShip()
    :setFaction("Human Navy")
    :setTemplate("Striker")
    :setScannedByFaction("Human Navy", true)
    :setWeaponTubeCount(7)
  fighter
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
  moveEntityToInternalBay(fighter, carrier)
end

for i=1,10 do
  local fighter = CpuShip()
    :setFaction("Kraylor")
    :setPosition(2000,2000)
    :setTemplate("Striker")
    :setScannedByFaction("Human Navy", true)
end
