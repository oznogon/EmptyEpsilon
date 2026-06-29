-- Name: Science
-- Description: <h3><color=#C0C0FF>Tutorial: Science</>
--- 
--- This tutorial covers how the <color=#C0C0FF>Science</> officer can examine the ship's surroundings and research entities using the ship's sensors.
---
--- To begin this tutorial, click the <color=#C0C0FF>Start tutorial</> button at the bottom right of this screen.
---
--- Science techniques are also relevant to the <color=#C0C0FF>Operations</> crew screen.
---
--- A Science officer's tasks include:
---
--- <h4><color=#C0C0FF>Viewing the ship's long-range radar</>
---
--- The Science screen includes a long-range radar that can locate ships and objects at a great distance, typically at up to 30U away from the ship. This makes the Science officer the eyes of the ship, since the radar can locate threats and hazards outside of the viewing range of Helms and Weapons officers.
---
--- The Science officer's most important responsibility is to report any unusual contacts or activity within their field of view to the ship's Captain and other officers. The Science officer can zoom in and out on the radar using the Zoom slider or mousewheel, which keeps their ship at the center of the view.
---
--- <color=#C0C0FF>Radar obstructions</>
---
--- Nebulae obstruct the ship's long-range radar. The Science officer can't see what's inside or behind them, and while inside of a nebula, the long-range radar can't detect what's outside of it. These traits make nebulae ideal places to hide for repairs or stage an ambush.
---
--- To avoid surprises around nebulae, report information about where you can and can't see objects to both the Captain, Helms, and Relay officers. The Helms officer might take care when entering a nebulae to avoid hitting a hazard, and the Relay officer can dispatch probes into the nebulae to provide visibility and scanning capabilities without venturing into them.
---
--- <color=#C0C0FF>Signal bands</>
---
--- The edge of the radar includes three colored bands of signal interference that can vaguely suggest the presence or activities of objects and space hazards. It's up to the Science officer to determine how to interpret these signals.
---
--- <h4><color=#C0C0FF>Scanning entities</>
---
--- The Science officer can use the ship's scanner to acquire more information about certain entities in space, such as other ships, space stations, and notable objects.
---
--- Unscanned vessels are indicated by a generic arrow icon instead of a radar trace, and entities of unknown faction or hostility are colored gray. Completing a scan can identify the ship's faction and relationship to your ship, and identifies the ship's type, which the Science officer can use to identify its capabilities in the Science screen's database.
---
--- To complete a scan, the Science officer must calibrate scanning frequencies to the selected target. Simple scans or targets might require as few as one dimension and a single pass, while others might require two, three, or more dimensions to be scanned across multiple passes.
---
--- <color=#C0C0FF>Deep scans</>
---
--- After completing an initial scan, the Science officer can attempt a second, more difficult scan to identify more information about the target. A deep scan of a ship can include its shield and hull status, and its shield and beam frequencies and the statuses of its individual systems, which are valuable tactical details for your Weapons officer if the target is hostile.
---
--- A deep scan also identifies the firing arcs of the target's beam weapons, which helps Helms and Weapons officers coordinate their tactics to avoid being targeted by hostile beams.
---
--- <h4><color=#C0C0FF>Linking to analysis</>
---
--- The Science officer can link the selected target to the target analysis screen. This sends all information about the target to the analysis screen, which allows the Captain, Weapons officer, or other officers on the ship to review that target's data while the Science officer moves on to other scans or research.
---
--- <h4><color=#C0C0FF>Probe view</>
---
--- The Relay officer can launch probes that provide remote sensors into distant and obstructed regions of space. The Relay officer can also link one of their probes to the Science screen, and the Science officer can then view the probe's short-range sensor data to scan entities within its range.
---
--- To enter probe view, click the Probe view button at the bottom left of the screen. This button is enabled only when a probe is linked to Science by the Relay officer. To return to your ship's radar, click the Radar button.
---
--- <h4><color=#C0C0FF>Database</>
---
--- The Science officer can access a database of known entities and phenomena, as well as data about weapons and space hazards. This can be useful when assessing a target's capabilities without a deep scan, or for help navigating a black hole, wormhole, or other anomaly.
-- Type: Tutorial

require("tutorial/99_all.lua")

function tutorial_init()
    tutorial_list = {
        scienceTutorial,
        endOfTutorial
    }
    startTutorial()
end
