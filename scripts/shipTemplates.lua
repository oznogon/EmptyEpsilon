--[[
Base of the ship templates, from here different classes of ships are included to be used within the game.
Each sub-file defines its own set of ship classes.

These are:
* Stations: For different kinds of space stations, from tiny to huge.
* Starfighters: Smallest ships in the game.
* Frigates: Medium sized ships. Operate on a small crew.
* Destroyers: Larger combat-oriented ships.
* Corvettes: Small multirole ships and defense platforms.
* Battleships: Huge things. Everything in here is really really big, and generally really really deadly.
* Light Carriers: Vessels that carry, deploy, and support starfighters.
* Auxiliaries: Non-combat support roles: freighters, transports, tugs.
* Exuari: Ships with a similar style, designed (but not limited) for the Exuari faction.
* Ktlitan: Alien Ktlitan swarm ships.

Player ships are in general large frigates to small corvette class
--]]
require("shiptemplates/stations.lua")
require("shiptemplates/starFighters.lua")
require("shiptemplates/satellites.lua")

require("shiptemplates/frigates.lua")
require("shiptemplates/destroyers.lua")
require("shiptemplates/corvettes.lua")
require("shiptemplates/battleships.lua")
require("shiptemplates/light_carriers.lua")
require("shiptemplates/auxiliaries.lua")

require("shiptemplates/exuari/starfighters.lua")
require("shiptemplates/exuari/frigates.lua")
require("shiptemplates/exuari/corvettes.lua")
require("shiptemplates/exuari/light_carriers.lua")

require("shiptemplates/ktlitan/starfighters.lua")
require("shiptemplates/ktlitan/frigates.lua")
require("shiptemplates/ktlitan/corvettes.lua")
require("shiptemplates/ktlitan/destroyers.lua")
require("shiptemplates/ktlitan/auxiliaries.lua")
require("shiptemplates/ktlitan/battleships.lua")

--For now, we add our old ship templates as well. These should be removed at some point.
require("shiptemplates/OLD.lua")
