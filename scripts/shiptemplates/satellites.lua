local template = ShipTemplate()
    :setName("ANT 615")
    :setLocaleName(_("ship", "ANT 615"))
    :setModel("combatsat")
    :setClass(_("class", "Satellite"), _("subclass", "Sentry Series"))
    :setDescription(
        _(
            "Military satellite from the old days, back when the earth's population was much more divided than today. Its original purpose was probably to take out other satellites."
        )
    )
    :setRadarTrace("combatsat.png")
    :setBeam(0, 15, 5, 990.0, 4.0, 2)
    :setBeam(1, 15, -5, 1000.0, 4.0, 2)
    :setHull(30)
    :setShields(30)
    :setSpeed(120, 30, 25)
