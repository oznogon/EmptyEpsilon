-- Name: Briefing Map Test
-- Description: Test scenario for the scriptable briefing map with keyframe-tweened pseudoentities.
-- Type: Development

function init()
    player = PlayerSpaceship():setFaction("Human Navy"):setTemplate("Atlantis")
    player:setPosition(0, 0)

    -- Page 1: Static image page (no map)
    setBriefingPage(player, 1,
        _("This is a standard static image page."),
        "images/black_hole_wireframe.jpg",
        nil, 5
    )

    -- Page 2: Map page with keyframes over 10 seconds
    setBriefingMapPage(player, 2, 10.0)

    -- Keyframe 1 at t=0: Camera at origin, zoomed out
    addBriefingMapKeyframe(player, 2, 1, 0.0, 0.0, 0.0, 60000.0)

    -- Define full entities for keyframe 1
    addBriefingMapEntity(player, 2, 1, 1, 10000.0, 0.0, 0.0, 1000.0, "radar/adv_gunship.png", 255, 0, 0, 255, true, "Red Ship")
    addBriefingMapEntity(player, 2, 1, 2, -10000.0, 0.0, 0.0, 1000.0, "radar/adv_striker.png", 0, 0, 255, 255, true, "Blue Ship")

    -- Keyframe 2 at t=5: Camera pans right and zooms in
    addBriefingMapKeyframe(player, 2, 2, 5.0, 15000.0, 5000.0, 30000.0)

    -- Copy entity 1 forward from keyframe 1 by touching its position, then modify
    setBriefingMapEntityPosition(player, 2, 2, 1, 15000.0, 5000.0)
    setBriefingMapEntityRotation(player, 2, 2, 1, 45.0)
    -- Entity 2 gets a full identity change
    setBriefingMapEntityPosition(player, 2, 2, 2, 0.0, 0.0)
    setBriefingMapEntityRotation(player, 2, 2, 2, -45.0)
    setBriefingMapEntitySize(player, 2, 2, 2, 1500.0)
    setBriefingMapEntityImage(player, 2, 2, 2, "radar/battleship.png")
    setBriefingMapEntityColor(player, 2, 2, 2, 0, 255, 0, 255)
    setBriefingMapEntityLabel(player, 2, 2, 2, "Green Ship")
    -- New entity appears at t=5, defined fully with addBriefingMapEntity
    addBriefingMapEntity(player, 2, 2, 3, 20000.0, 10000.0, 0.0, 800.0, "radar/exuari_1.png", 255, 255, 0, 255, true, "Yellow Ship")

    -- Keyframe 3 at t=10: Camera zooms in closer, final position
    addBriefingMapKeyframe(player, 2, 3, 10.0, 10000.0, 2500.0, 15000.0)

    -- Update individual properties on entity 1
    setBriefingMapEntityPosition(player, 2, 3, 1, 10000.0, 2500.0)
    setBriefingMapEntityRotation(player, 2, 3, 1, 90.0)
    setBriefingMapEntitySize(player, 2, 3, 1, 3000.0)
    setBriefingMapEntityColor(player, 2, 3, 1, 255, 128, 128, 128)
    -- Entity 2: just move it
    setBriefingMapEntityPosition(player, 2, 3, 2, 8000.0, 0.0)
    setBriefingMapEntityRotation(player, 2, 3, 2, 0.0)
    -- Entity 3: hide it
    setBriefingMapEntityVisible(player, 2, 3, 3, false)
end
