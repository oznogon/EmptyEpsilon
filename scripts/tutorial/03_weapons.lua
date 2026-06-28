-- Name: Weapons
-- Description: <h3><color=#C0C0FF>Tutorial: Weapons</>
--- 
--- This tutorial covers how the <color=#C0C0FF>Weapons</> officer manages a ship's offensive and defensive systems. This includes loading, unloading, aiming, and firing weapon tubes; targeting beam weapons; and setting beam and shield frequencies, if applicable.
---
--- To begin this tutorial, click the <color=#C0C0FF>Start tutorial</> button at the bottom right of this screen.
---
--- Weapon officer techniques are also relevant to the <color=#C0C0FF>Tactical</>, <color=#C0C0FF>Single Pilot</>, <color=#C0C0FF>Beam Weapons</>, and <color=#C0C0FF>Missile Weapons</> crew screens.
---
--- The Weapons officer's tasks include:
---
--- <color=#C0C0FF><h4>Tracking ship status</>
---
--- The Weapons officer's screen tracks the ship's energy and shields. Firing beams and raising shields consumes energy.
---
--- <color=#C0C0FF><h4>Locking onto targets</>
---
--- To fire beam weapons and target guided missile weapons, the Weapons officer can lock onto a target by clicking or tapping its radar trace on the screen's short-range radar. A targeting reticule indicates which target is locked onto.
---
--- Typically only <color=#DDDDDD>unknown</>, <color=#C0C0FF>neutral</>, or <color=#FF0000>hostile</> entities can be targeted.
---
--- <color=#C0C0FF><h4>Managing and firing weapon tubes</>
---
--- Missiles and mines are a ship's most destructive weapons, but have a limited stock and can be fully exhausted. These weapons are loaded into weapon tubes, fixed hardpoints on a ship that face a specific direction.
---
--- Some ships have tubes only on certain sides of a ship, such as facing behind or broadsides, or fire unguided weapons; in both cases, the Weapons officer must coordinate closely with the Helms officer's maneuvers to strike a target.
---
--- To load a weapon into a tube, the Weapons officer clicks or taps the weapon type in the ship's stocks to select it, then clicks or taps the Load button next to an empty weapon tube to load it into the tube. Loading a tube can take several seconds, and some tubes might accept only certain types of compatible weapons.
---
--- To unload a weapon from a tube, the Weapons officer clicks or taps the Unload button next to a loaded weapon tube. This also takes several seconds and returns the loaded weapon to the ship's stocks.
---
--- To fire a weapon, the Weapons officer clicks or taps a loaded weapon tube. Missiles with homing capabilities lock onto the selected missile weapons target, while mines, unguided missiles, and guided missiles without a locked-on target fire straight from whatever direction their tube faces. White lines originating from the weapon tubes' locations indicate the likely path that guided missiles will take toward their target.
---
--- Guided missiles can also be fired with a specific heading as a target. Disabling the Lock feature activates a targeting ring that sets the target heading.
---
--- Missiles have a limited lifetime and expire or explode at the end of it. Mines persist indefinitely, but explode when they detect a sufficient target within their detection radius.
---
--- <color=#FFC800>Homing missile</>
---
--- A high-speed missile with a small conventional kinetic warhead. If a target is locked onto, a homing missile turns to attempt to pursue its target. Nimble ships or a well-timed combat maneuver can evade them.
---
--- <color=#FF6420>Nuke</>
---
--- A powerful homing missile that deals tremendous kinetic damage to all ships within 1U of its detonation. A nuke is less maneuverable in pursuit than a homing missile, and it explodes at the end of its lifetime regardless of whether it makes contact with a target.
---
--- <color=#6420FF>Electromagentic pulse (EMP)</>
---
--- A powerful homing missile that deals powerful electromagnetic damage to any active shields within 1U of its detonation, but doesn't damage ship systems or hulls.
---
--- <color=#DDDDDD>High-velocity lead impactor (HVLI)</>
---
--- A group of five kinetic lead slugs fired sequentially and at high velocity. These railgun-like bolts don't home in on a selected target and reach their peak effectiveness at about 1U from their firing ship.
---
--- <color=#FFFFFF>Mine</>
---
--- A powerful but stationary explosive that detonates when within 0.6U of a substantial target. A mine's trigger doesn't identify friends from foes, and its explosion damages all objects within a 1U radius.
---
--- <h4><color=#FF0000>Beam weapons</>
---
--- Beam weapons are focused energy weapons that strike instantly, unerringly, and with enough precision to target specific systems on a ship. Red firing arcs originating from a ship indicate the position, arc, and range of its beam weapons.
---
--- To fire beam weapons at a target, the Weapons officer locks onto a target by clicking or tapping it on the radar. If the Autofire feature is enabled, beam weapons automatically fire at that target when it is inside the beam's firing arc, requiring coordination with the Helms officer to move the ship and beam arc into range.
---
--- Beam weapons can be modulated to different frequencies, some of which are more effective against certain shield frequencies than others. The Science officer can provide the Weapons officer with data about which beam frequencies will be most effective against a target, and the Weapons officer can then instantly remodulate their beams to that frequency to deal more damage.
---
--- By default, beam weapons fire to damage a target's hull. Dealing enough hull damage to a target destroys it. The Weapons officer can also select a specific subsystem to target, which instead disables them.
---
--- Beam weapons generate additional heat and consume additional energy each time they're fired. A Weapons officer must coordinate with Engineering to manage their ship's resources effectively while using beams in combat.
---
--- <color=#C0C0FF><h4>Managing shields</>
---
--- The Weapons officer is also responsible for activating the ship's shields and modulating their frequency. Deactivated shields don't provide any defensive capabilities. Activated shields can deflect kinetic and energy damage all around the ship, but they rapidly drain the ship's power.
---
--- Deflecting damage depletes some or all of a shield. Shields be recharged as long as the ship and the shields system have power, even while the shield itself is deactivated, but recharging a shield takes a considerable amount of time. Some ships have multiple shield segments, each of which cover an equal arc on the ship and can be depleted separately from each another.
---
--- Some shield frequencies are especially resistant to certain beam frequencies, and the Science officer can also detect which beam frequency a target ship employs. However, unlike beam weapons, remodulating the shields' frequency takes them offline for several seconds and leaves the ship temporarily defenseless. Coordinate shield modulation with other officers to ensure that you can do so safely.
-- Type: Tutorial

require("tutorial/00_all.lua")

function tutorial_init()
    tutorial_list = {
        weaponsTutorial,
        endOfTutorial
    }
    startTutorial()
end
