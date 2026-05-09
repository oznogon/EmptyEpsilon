#include "radarScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/globalMessage.h"
#include "screenComponents/jumpIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/radarZoomSlider.h"
#include "screenComponents/rawScannerDataRadarOverlay.h"
#include "screenComponents/selfDestructIndicator.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_listbox.h"

#include "components/collision.h"
#include "components/radar.h"

RadarScreen::RadarScreen(GuiContainer* owner, string type)
: GuiOverlay(owner, "RADAR_SCREEN", GuiTheme::getColor("background")), radar_type(type)
{
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    radar = new GuiRadarView(this, "RADAR_VIEW", 5000.0f, &targets);
    radar
        ->setStyle(GuiRadarView::Circular)
        ->setRangeIndicatorStepSize(1000.0f)
        ->enableCallsigns()
        ->enableWaypoints()
        ->enableHeadingIndicators()
        ->enableMissileTubeIndicators()
        ->shortRange()
        ->setFogOfWarStyle(GuiRadarView::NoFogOfWar)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    signal_bands = new RawScannerDataRadarOverlay(radar, "");

    probe_radar = new GuiRadarView(this, "PROBE_RADAR_VIEW", 5000.0f, &targets);
    probe_radar
        ->setStyle(GuiRadarView::Circular)
        ->setRangeIndicatorStepSize(1000.0f)
        ->enableCallsigns()
        ->enableWaypoints()
        ->enableHeadingIndicators()
        ->disableMissileTubeIndicators()
        ->shortRange()
        ->setFogOfWarStyle(GuiRadarView::NoFogOfWar)
        ->setAutoCentering(false)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    probe_signal_bands = new RawScannerDataRadarOverlay(probe_radar, "");
    probe_signal_bands->hide();

    zoom_slider = new GuiRadarZoomSlider(this, "RADAR_ZOOM", 5000.0f, 30000.0f, 30000.0f, radar);
    zoom_slider
        ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(250.0f, 50.0f);

    // Radar/database view toggle.
    view_mode_selection = new GuiListbox(this, "VIEW_SELECTION",
        [this](int index, string value)
        {
            setRadarMode(value);
        }
    );
    view_mode_selection
        ->setOptions(
            {tr("scienceButton", "Long range"), tr("scienceButton", "Short range"), tr("scienceButton", "Strategic")},
            {"Long range", "Short range", "Strategic"}
        )
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(200.0f, 200.0f);

    setRadarMode(type);

    (new GuiJumpIndicator(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiSelfDestructIndicator(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiCustomShipFunctions(this, CrewPosition::radarOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void RadarScreen::setRadarMode(string mode)
{
    if (!my_spaceship) return;

    float mode_short = 5000.0f;
    float mode_long = 30000.0f;
    float mode_far = 50000.0f;
    if (auto lrr = my_spaceship.getComponent<LongRangeRadar>())
    {
        mode_short = lrr->short_range;
        mode_long = lrr->long_range;
    }

    bool mode_changed = (previous_radar_type != mode);
    bool ranges_changed = (previous_short_range != mode_short || previous_long_range != mode_long);
    previous_radar_type = mode;
    previous_short_range = mode_short;
    previous_long_range = mode_long;

    // Toggle probe entry in view_mode_selection if linked.
    auto rl = my_spaceship.getComponent<RadarLink>();
    bool has_probe = (rl && rl->linked_entity);

    if (has_probe && !probe_entry_added)
    {
        view_mode_selection->addEntry(tr("scienceButton", "Linked probe"), "Linked probe");
        probe_entry_added = true;
    }
    else if (!has_probe && probe_entry_added)
    {
        const int probe_index = view_mode_selection->indexByValue("Linked probe");
        if (probe_index >= 0)
            view_mode_selection->removeEntry(probe_index);
        probe_entry_added = false;

        if (radar_type == "Linked probe")
            radar_type = "Long range";
    }

    if (mode == "Long range")
    {
        radar_type = mode;
        view_mode_selection->setSelectionIndex(view_mode_selection->indexByValue(mode));
        radar
            ->setStyle(GuiRadarView::Circular)
            ->setRangeIndicatorStepSize(5000.0)
            ->enableHeadingIndicators()
            ->disableMissileTubeIndicators()
            ->longRange()
            ->setFogOfWarStyle(GuiRadarView::NebulaFogOfWar)
            ->show();
        zoom_slider
            ->setRange(mode_long, mode_short)
            ->show();
        if (mode_changed)
            zoom_slider->setValue(mode_long);
        else if (ranges_changed)
            zoom_slider->setValue(std::clamp(radar->getDistance(), mode_short, mode_long));
        probe_radar->hide();
        probe_signal_bands->hide();
        signal_bands->show();
    }
    else if (mode == "Short range")
    {
        radar_type = mode;
        view_mode_selection->setSelectionIndex(view_mode_selection->indexByValue(mode));
        radar
            ->setStyle(GuiRadarView::Circular)
            ->setRangeIndicatorStepSize(1000.0)
            ->enableHeadingIndicators()
            ->enableMissileTubeIndicators()
            ->shortRange()
            ->setFogOfWarStyle(GuiRadarView::NoFogOfWar)
            ->show();
        if (mode_changed || ranges_changed)
            radar->setDistance(mode_short);
        zoom_slider->hide();
        probe_radar->hide();
        probe_signal_bands->hide();
        signal_bands->hide();
    }
    else if (mode == "Strategic")
    {
        radar_type = mode;
        view_mode_selection->setSelectionIndex(view_mode_selection->indexByValue(mode));
        radar
            ->setStyle(GuiRadarView::Rectangular)
            ->setRangeIndicatorStepSize(0.0f) // disable
            ->disableHeadingIndicators()
            ->disableMissileTubeIndicators()
            ->longRange()
            ->setFogOfWarStyle(GuiRadarView::FriendlysShortRangeFogOfWar)
            ->show();
        zoom_slider
            ->setRange(mode_far, mode_short)
            ->show();
        if (mode_changed)
            zoom_slider->setValue(mode_far);
        else if (ranges_changed)
            zoom_slider->setValue(std::clamp(radar->getDistance(), mode_short, mode_far));
        probe_radar->hide();
        probe_signal_bands->hide();
        signal_bands->hide();
    }
    else if (mode == "Linked probe")
    {
        auto rl = my_spaceship.getComponent<RadarLink>();
        if (rl && rl->linked_entity)
        {
            if (auto transform = rl->linked_entity.getComponent<sp::Transform>())
            {
                radar_type = mode;
                view_mode_selection->setSelectionIndex(view_mode_selection->indexByValue(mode));
                radar->hide();
                zoom_slider->hide();
                signal_bands->hide();

                probe_radar
                    ->setViewPosition(transform->getPosition())
                    ->show();
                probe_signal_bands->show();
            }
        }
        else
        {
            radar_type = "Long range";
            setRadarMode(radar_type);
        }
    }
}

void RadarScreen::onDraw(sp::RenderTarget& renderer)
{
    setRadarMode(radar_type);

    GuiOverlay::onDraw(renderer);
}

void RadarScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto rl = my_spaceship.getComponent<RadarLink>();
    bool has_probe = (rl && rl->linked_entity);

    if (keys.radar_long_range.getDown())
        radar_type = "Long range";
    else if (keys.radar_short_range.getDown())
        radar_type = "Short range";
    else if (keys.radar_strategic.getDown())
        radar_type = "Strategic";
    else if (keys.radar_linked_probe.getDown() && has_probe)
        radar_type = "Linked probe";

    if (radar_type == "Linked probe" && has_probe)
    {
        if (auto transform = rl->linked_entity.getComponent<sp::Transform>())
            probe_radar->setViewPosition(transform->getPosition());
    }
}