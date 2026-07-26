--[[ Ship templates

Loads classes of ships from files.

These are:

- Stations: For different kinds of space stations, from tiny to huge.
- Starfighters: Smallest ships in the game.
- Frigates: Medium sized ships. Operate on a small crew.
- Destroyers: Larger combat-oriented ships.
- Corvettes: Small multirole ships and defense platforms.
- Battleships: Huge things. Everything in here is really really big, and
  generally really really deadly.
- Light carriers: Vessels that carry, deploy, and support starfighters.
- Auxiliaries: Non-combat support roles, such as freighters, transports, and
  tugs.

Some ship templates are strongly associated with certain factions and have their own subdirectories and file structures:

- Exuari
- Ktlitan

Player ships are generally large corvettes to small frigates.
]]
require("shiptemplates/satellites.lua")
require("shiptemplates/auxiliaries.lua")
require("shiptemplates/starfighters.lua")
require("shiptemplates/corvettes.lua")
require("shiptemplates/frigates.lua")
require("shiptemplates/destroyers.lua")
require("shiptemplates/cruisers.lua")
require("shiptemplates/light_carriers.lua")
require("shiptemplates/battleships.lua")
require("shiptemplates/stations.lua")

require("shiptemplates/exuari/starfighters.lua")
require("shiptemplates/exuari/corvettes.lua")
require("shiptemplates/exuari/frigates.lua")
require("shiptemplates/exuari/light_carriers.lua")

require("shiptemplates/ktlitan/auxiliaries.lua")
require("shiptemplates/ktlitan/starfighters.lua")
require("shiptemplates/ktlitan/corvettes.lua")
require("shiptemplates/ktlitan/frigates.lua")
require("shiptemplates/ktlitan/destroyers.lua")
require("shiptemplates/ktlitan/battleships.lua")
