-- Name: Briefing Screen Test
-- Description: Test scenario that populates a briefing with images and audio.
-- Type: Development

function init()
    -- Spawn a player ship so the briefing screen is accessible
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Populate 5 briefing pages on the player ship using images from resources/images/
    -- and audio from resources/audio/scenario/55/
    setBriefingPage(player, 1, _([[[If you run stock missions, you can make do without GM, but a lot of missions have some controls to tweak that exact mission on the fly. 

Here is full description of GM screen with controls: https://github.com/daid/EmptyEpsilon/wiki/Game-Master

I recommend toying with it too get a handle on what things actually do (and what objects can you create in top of our what the scenario itself creates). 

I believe, taky there is also mistake/imprecise info - faction selector can also change faction for selected objects. But check that for yourself. 

If you want to create your own scenarios, see mission scripting page from there and also mission scripting tutorial on EE's web page. But that is entirely new can of worms.]]), "images/black_hole_wireframe.jpg", "audio/scenario/55/sa_55_Commander1.ogg", 8)
    setBriefingPage(player, 2, _("If you run stock missions, you can make do without GM, but a lot of missions have some controls to tweak that exact mission on the fly."), "images/frequency_graph.png", "audio/scenario/55/sa_55_Commander2.ogg", 10)
    setBriefingPage(player, 3, _("Hack Minigames"), "images/hack_minigames.jpg", "audio/scenario/55/sa_55_Manager1.ogg", 6)
    setBriefingPage(player, 4, _("Radar Rings"), "images/radar_rings.png", "audio/scenario/55/sa_55_Maria1.ogg", 9)
    setBriefingPage(player, 5, _("Wormhole"), "images/wormhole.jpg", "audio/scenario/55/sa_55_Maria2.ogg", 13)
end

function update(delta)
    -- Nothing to update
end
