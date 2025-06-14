--[[                  Tug
Tugs are small ships with a powerful reactor and tractor beam, and few or no weapons.
They rely on carrier ships or space stations, and are invaluable for recovering or salvaging disabled, abandoned, or derelict ships.
Tugs deployed into hazardous areas might have shields, and those tasked with salvaging partially operational ships might have shield-draining beams or EMP launchers. 
----------------------------------------------------------]]

local template = ShipTemplate():setName("Hylas"):setLocaleName(_("ship", "Hylas")):setClass(_("class", "Tug")):setModel("battleship_destroyer_1_upgraded")
template:setDescription(_([[The Hylas is the smallest functional model of tug. Its powerful reactor is almost entirely dedicated to its tractor beam, leaving only minimal impulse engines to slowly move it and the objects it tows.]]))
template:setRadarTrace("tug.png")
template:setHull(40)
template:setSpeed(30, 5, 8)
--[[                   arc, max_arc, bearing, range, max_range, cycle_time, strength]]
template:setTractorBeam(18,     180,       0,  3000,      5000,        6.0, 10.0)

local variation = template:copy("Hylas"):setName("Heracles"):setLocaleName(_("playerShip", "Heracles")):setType("playership")
variation:setDescription(_([[The Heracles tug model is a Hylas suited for carrier use in deep-space operations. Improvements include a stronger hull, minimal shield system, full sensor suite, and a shield-disrupting beam for use on abandoned hostile or unknown ships.]]))
variation:setShields(100)
variation:setHull(100)
variation:setBeamWeapon(0, 90, 0, 1000, 2, 1)

variation:addRoomSystem(1, 0, 2, 1, "Maneuver");
variation:addRoomSystem(1, 1, 2, 1, "BeamWeapons");
variation:addRoom(2, 2, 2, 1);

variation:addRoomSystem(0, 3, 1, 2, "RearShield");
variation:addRoomSystem(1, 3, 2, 2, "Reactor");
variation:addRoomSystem(3, 3, 2, 2, "Warp");
variation:addRoomSystem(5, 3, 1, 2, "JumpDrive");
variation:addRoomSystem(6, 3, 2, 1, "TractorBeam");
variation:addRoom(6, 4, 2, 1);
variation:addRoomSystem(8, 3, 1, 2, "FrontShield");

variation:addRoom(2, 5, 2, 1);
variation:addRoomSystem(1, 6, 2, 1, "MissileSystem");
variation:addRoomSystem(1, 7, 2, 1, "Impulse");

variation:addDoor(1, 1, true);
variation:addDoor(2, 2, true);
variation:addDoor(3, 3, true);
variation:addDoor(1, 3, false);
variation:addDoor(3, 4, false);
variation:addDoor(3, 5, true);
variation:addDoor(2, 6, true);
variation:addDoor(1, 7, true);
variation:addDoor(5, 3, false);
variation:addDoor(6, 3, false);
variation:addDoor(6, 4, false);
variation:addDoor(8, 3, false);
variation:addDoor(8, 4, false);

--Airlock doors
--variation:addDoor(2, 2, false);
--variation:addDoor(2, 5, false);