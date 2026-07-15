-- Name: Helms
-- Description: <h3><color=#C0C0FF>Tutorial: Helms</>
---
--- This tutorial covers how the <color=#C0C0FF>Helms</> officer pilots a ship. This includes maneuvering the ship with thrusters and impulse engines, employing faster-than-light propulsion methods, docking with other ships and space stations, and retrieving objects.
---
--- To begin this tutorial, click the <color=#C0C0FF>Start tutorial</> button at the bottom right of this screen.
---
--- Piloting techniques are also relevant to the <color=#C0C0FF>Tactical</> and <color=#C0C0FF>Single Pilot</> crew screens.
---
--- The Helms officer's tasks include:
---
--- <h4><color=#C0C0FF>Tracking ship status</>
---
--- The Helms officer's screen tracks the ship's energy, heading, and speed.
---
--- <h4><color=#C0C0FF>Impulse engine</>
---
--- The impulse engine's slider controls the throttle, from -100% (full reverse) to 0% (full stop) to 100% (full ahead).
---
--- <h4><color=#C0C0FF>Radar and rotation</>
---
--- The Helms officer has a short-range radar. Pressing inside this radar sets the ship's heading. If the ship has beam weapons, the radar view includes those weapons' firing arcs to help the Helms officer keep targets in the Weapons officer's sights.
---
--- <h4><color=#C0C0FF>Jump drive</>
---
--- On ships with a jump drive, you can teleport the ship across the specified distance along its current heading. The ship's impulse engines shut down, and after a countdown the ship disappears from its position and instantly reappears at its destination.
---
--- Each jump consumes energy, with longer jumps consuming more energy. A standard jump takes 10 seconds to initiate, but depending on how much power is allocated to the drive (and how damaged it is), the time to power the jump might vary. Jumps can be aborted, but doing so will generate additional heat and consume jump charge, with consequences growing the longer you wait to cancel the jump.
---
--- <h4><color=#C0C0FF>Warp drive</>
---
--- On ships with a warp drive, you can propel the ship forward at several times the velocity of impulse engine. However, warp propulsion drains energy and generates heat at much higher rates. A warping ship can still collide with hazards like asteroids and mines, but a ship can enter warp very quickly for rapid escapes and advanced tactical maneuvers.
---
--- <h4><color=#C0C0FF>Combat maneuvers</>
---
--- For ships capable of performing combat maneuvers, the screen includes combat maneuver controls. Vertical movement rapidly increases the ship's forward speed above its maximum cruising speed, but rapidly generates heat in the impulse engine system. Horizontal movement moves the ship laterally but can quickly overheat maneuvering system. Combat maneuvers can be exhausted but recharge automatically over time.
---
--- <h4><color=#C0C0FF>Docking</>
---
--- On ships with a docking port, you can initiate an automated docking sequence with a friendly or neutral ship or space station that has a docking bay when it is no more than 1U away.
---
--- While docked, the ship can't engage its propulsion or fire weapons, but its energy recharges faster, repairs take less time, the ship's supply of probes is replenished, and the Relay officer can often request a resupply of missile weapon ammunition. The Helms officer is also responsible for undocking the ship.
---
--- <h4><color=#C0C0FF>Retrieving objects</>
---
--- The Helms officer is also responsible for piloting the ship into supply drops and other collectible items to retrieve them.
-- Type: Tutorial

require("tutorial/99_all.lua")

function tutorial_init()
    tutorial_list = {
        helmsTutorial,
        endOfTutorial
    }
    startTutorial()
end
