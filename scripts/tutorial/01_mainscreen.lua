-- Name: Basics
-- Type: Tutorial
-- Description: <h3><color=#C0C0FF>Tutorial: Basics</>
---
--- This introductory tutorial covers the basics of leading a crew, maintaining map awareness, and reading radar displays.
---
--- To begin this tutorial, click the <color=#C0C0FF>Start tutorial</> button at the bottom right of this screen.
---
--- The <color=#C0C0FF>Captain</> keeps their crew focused on their goals and makes strategic decisions in combat. Without direct control over the ship, the Captain must communicate their orders to the other bridge officers and ensure that officers communicate their needs effectively to each other.
---
--- The Captain's tasks include:
---
--- - Planning the crew's next actions
--- - Coordinating combat tactics
--- - Setting priorities
--- - Preventing mutiny
---
--- In addition to the Captain's tasks, this tutorial also covers the basics of other stations, except for Engineering.
---
--- Display the ship's main screen on a large monitor or projector so that all players can track their ship's status.

require("utils.lua")
require("tutorial/99_all.lua")

function tutorial_init()
    tutorial_list = {
        mainscreenTutorial,
        radarTutorial,
        endOfTutorial
    }

    startTutorial()
end
