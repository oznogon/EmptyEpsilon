-- Name: Relay
-- Description: <h3><color=#C0C0FF>Tutorial: Relay</>
--- 
--- This tutorial covers how the <color=#C0C0FF>Relay</> officer manages the flow of information between their ship and other ships and space stations across the region. This includes hailing and communicating with other entities, launching probes, setting navigational waypoints, and hacking hostile entities.
---
--- To begin this tutorial, click the <color=#C0C0FF>Start tutorial</> button at the bottom right of this screen.
---
--- Relay officer techniques are also relevant to the <color=#C0C0FF>Operations</>, <color=#C0C0FF>Strategic Map</>, <color=#C0C0FF>Comms</>, and <color=#C0C0FF>Ship's Log</> crew screen.
---
--- A Relay officer's tasks include:
---
--- <h4><color=#C0C0FF>Viewing a sector map</>
---
--- The Relay screen includes a map of the sector, including large space hazards such as nebulae, black holes, and wormholes. The ship's short-range radar is visible on this map, as are the short-range radars of the ship's probes and other friendly ships and space stations, allowing the Relay officer to spot distant threats or points of interest that are obscured on or beyond the range of even the Science officer's long-range radar.
---
--- To zoom in and out on the map, use the Zoom slider or mousewheel. To pan the map, click or tap the map and drag. To center and lock the map onto your ship, click the Center on ship button.
---
--- <h4><color=#C0C0FF>Launching and linking scan probes</>
---
--- The Relay officer can't scan entities on their own, but they can launch high-speed unmanned probes toward any point on their map and link them to Science for scanning.
---
--- To launch a probe, click or tap the launch probe button, then click or tap the point on the map where you want the probe to go. Each probe flies in a straight line toward its target location and then remains stationary there, where it transmits its short-range radar to its launching ship for 10 minutes before expiring. A launched probe can't reposition itself.
---
--- To link a probe to the Science screen, click or tap the launched probe, then click the Link to science button. The Relay officer can link only one probe at a time, and can link a probe while it's still in transit to its destination. This allows the Science officer to scan ships and other entities within the probe's radar range even if the probe is located out of reach of the ship's long-range radar.
---
--- Probes can transmit from within nebulae and transit wormholes, and are thus powerful tools when faced with areas inaccessible to the Science officer's radar.
---
--- Ships have a limited stock of probes, which are fragile and defenseless. Hostile ships, collisions with asteroids, and other hazards can quickly destroy them. A ship can't retrieve and reuse a launched probe, nor can it capture other probes it encounter. Your ship's stock of probes can be replenished only by docking at a station or picking up a supply drop containing additional probes.
---
--- <h4><color=#C0C0FF>Placing navigational waypoints</>
---
--- The Relay officer can set waypoints on their sector map. These waypoints appear as indicators pointing toward their location on the Helms officer's short-range radar. Use waypoints to help guide your Helms officer toward a destination or on a specific route through space.
---
--- You must also place waypoints in order to request aid from friendly space stations.
---
--- To delete a waypoint, click or tap the waypoint to select it, then click or tap the Delete waypoint button. Deleting a waypoint doesn't change the numbers of other already-placed waypoints in the set.
---
--- If multiple waypoint sets are enabled on this server, click or tap the waypoint set selector to choose which set to use. Each set is distinguished by using a different color. Space station communications that refer to waypoints always refer to waypoint set 1.
---
--- If waypoint routes are enabled, click or tap the Show as route button to draw a line between waypoints.
---
--- <h4><color=#C0C0FF>Hailing and communicating with other entities</>
---
--- The Relay officer can open communications with space stations and other ships. Friendly ships hailed by the Relay officer will often take orders from you, and friendly stations can dispatch backup and provide supply drops toward placed waypoints.
---
--- When their ship is docked at a friendly or neutral station, the Relay officer can also often request rearmament of the ship's missiles and mines. Some of these requests can cost some of your crew's reputation, which is also tracked by the Relay station.
---
--- <h4><color=#C0C0FF>Hacking other entities</>
---
--- The Relay officer can hack the systems of unknown, neutral, and hostile entities. This can reduce the effectiveness of a targeted system, which can give your ship a tactical edge in combat or allow you to escape.
---
--- To begin a hacking attempt, click or tap a target to select it. If the target can be hacked, the Start hacking button is enabled. Click or tap it to begin hacking.
---
--- To successfully hack the target, the Relay officer must complete a Lights or Mines minigame. For details about the minigames, play through the tutorial scenario.
---
--- <h4><color=#C0C0FF>Setting the ship's alert status</>
---
--- The Relay officer has the responsibility of setting the ship's alert level. This adds an overlay to all crew stations to communicate the severity of the crew's current status.
---
--- To set the alert level, click the Alert level button, then select the appropriate level. To disable an alert, change the alert level to Normal.
---
--- <h4><color=#C0C0FF>Reviewing the ship's log</>
---
--- The Relay officer can view the ship's log, which keeps a time-stamped, running record of all communications with other entities. Other events might also be written to the ship's log. Review the log as needed to track mission objectives and recall details gleaned from past communications.
---
--- The most recent line of the ship's log is always visible at the bottom of the Relay screen. To expand the ship's log, click or tap this line. To retract it, click the ship's log again.
---
--- <h4><color=#C0C0FF>Tracking the mission clock</>
---
--- The Relay officer can view the time that has elpased since the start of the mission. Use this to keep track of timed events.
---
-- Type: Tutorial
require("tutorial/99_all.lua")

function tutorial_init()
    tutorial_list = {
        relayTutorial,
        endOfTutorial
    }
    startTutorial()
end
