#include "utilityBeamControls.h"
#include <i18n.h>
#include "playerInfo.h"
#include "powerDamageIndicator.h"
#include "crewPosition.h"

#include "components/utilityBeam.h"

#include "gui/gui2_progressbar.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_keyvaluedisplay.h"

GuiUtilityBeamControls::GuiUtilityBeamControls(GuiContainer* owner, CrewPosition position, string id)
: GuiElement(owner, id), position(position)
{
    // Create all elements unconditionally but hidden.
    // The UtilityBeam component data may not be available at construction time
    // (e.g., screen created before entity data arrives from the server).
    // onUpdate() will populate and show them when the component becomes available.

    utility_progress_bar = new GuiProgressbar(this, "UTILITY_PROGRESS_BAR", 0.0, 1.0, 0.0);
    utility_progress_bar->setColor(glm::u8vec4(192, 192, 192, 64))->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility toggle button.
    utility_toggle = new GuiToggleButton(this, "UTILITY_BEAM_TOGGLE", tr("scienceButton", "Activate"), [](bool value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeam(value);
    });
    utility_toggle->setSize(GuiElement::GuiSizeMax, 50)->hide();
    (new GuiPowerDamageIndicator(utility_toggle, "UTILITY_BEAM_TOGGLE_PDI", ShipSystem::Type::UtilityBeam, sp::Alignment::CenterLeft))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    custom_utility_mode = new GuiSelector(this, "CUSTOM_UTILITY_BEAM_MODE", [](int index, string value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>())
            my_player_info->commandSetCustomUtilityBeamMode(value);
    });
    custom_utility_mode->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility bearing slider.
    utility_bearing = new GuiSlider(this, "UTILITY_BEAM_BEARING", 0.0f, 360.0f, 0.0f, [](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamBearing(value);
    });
    utility_bearing->addOverlay(1, 30.0f, tr("utilityButton", "Bearing: "))->setSize(GuiElement::GuiSizeMax, 50)->hide();

    utility_bearing_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_BEARING_FIXED", 0.5f, tr("utilityControls", "Bearing"), "0");
    utility_bearing_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility arc slider.
    utility_arc = new GuiSlider(this, "UTILITY_BEAM_ARC", 0.0f, 180.0f, 0.0f, [](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamArc(value);
    });
    utility_arc->addOverlay(1, 30.0f, tr("utilityButton", "Arc: "))->setSize(GuiElement::GuiSizeMax, 50)->hide();

    utility_arc_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_ARC_FIXED", 0.5f, tr("utilityControls", "Arc"), "0");
    utility_arc_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility range slider.
    utility_range = new GuiSlider(this, "UTILITY_BEAM_RANGE", 0.0f, 3000.0f, 1000.0f, [](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamRange(value);
    });
    utility_range->addOverlay(1, 30.0f, tr("utilityButton", "Range: "))->setSize(GuiElement::GuiSizeMax, 50)->hide();

    utility_range_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_RANGE_FIXED", 0.5f, tr("utilityControls", "Range"), "0");
    utility_range_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();
}

void GuiUtilityBeamControls::onDraw(sp::RenderTarget& target)
{
    if (!my_spaceship) return;

    if (auto utility_beam = my_spaceship.getComponent<UtilityBeam>())
    {
        utility_arc->setValue(utility_beam->arc)->setVisible(!utility_beam->fixed_arc);
        utility_arc_fixed->setValue(utility_beam->arc)->setVisible(utility_beam->fixed_arc);
        if (utility_arc->isVisible() && utility_arc->getRangeMax() != utility_beam->max_arc)
            utility_arc->setRange(utility_beam->MIN_ARC, utility_beam->max_arc);

        utility_range->setValue(utility_beam->range)->setVisible(!utility_beam->fixed_range);
        utility_range_fixed->setValue(utility_beam->range)->setVisible(utility_beam->fixed_range);
        if (utility_range->isVisible() && utility_range->getRangeMax() != utility_beam->max_range)
            utility_range->setRange(utility_beam->MIN_RANGE, utility_beam->max_range);

        utility_bearing->setValue(utility_beam->bearing)->setVisible(!utility_beam->fixed_bearing);
        utility_bearing_fixed->setValue(utility_beam->bearing)->setVisible(utility_beam->fixed_bearing);

        for (int i = 0; i < custom_utility_mode->entryCount(); i++)
        {
            if (custom_utility_mode->getEntryName(i) == utility_beam->custom_beam_mode)
            {
                if (utility_beam->custom_beam_modes[i].progress >= 0.0f)
                    utility_progress_bar->setValue(utility_beam->custom_beam_modes[i].progress);
            }
        }
    }
}

void GuiUtilityBeamControls::onUpdate()
{
    if (!my_spaceship) return;

    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();

    if (utility_beam)
    {
        // Configure custom mode selector from component data.
        if (utility_beam->custom_beam_modes.size() < 1)
            custom_utility_mode->hide();
        else
        {
            std::vector<string> display_names;
            for (const auto& beam_mode : utility_beam->custom_beam_modes)
                display_names.push_back(beam_mode.name);
            custom_utility_mode->setOptions(display_names, display_names);
            custom_utility_mode->show();
        }

        // Sync custom mode selection to authoritative server state.
        int mode_idx = custom_utility_mode->indexByValue(utility_beam->custom_beam_mode);
        if (mode_idx >= 0 && mode_idx != custom_utility_mode->getSelectionIndex())
            custom_utility_mode->setSelectionIndex(mode_idx);

        // Show all controls now that the component is available.
        utility_toggle->show();
        utility_toggle->setValue(utility_beam->active);
        utility_bearing->show();
        utility_arc->show();
        utility_range->show();
        utility_progress_bar->show();

        // Hotkey input only when visible.
        if (isEffectivelyVisible())
        {
            auto bearing_input = (keys.utilitybeam_bearing_right.getValue() - keys.utilitybeam_bearing_left.getValue());
            auto arc_input = (keys.utilitybeam_arc_increase.getValue() - keys.utilitybeam_arc_decrease.getValue());
            auto range_input = (keys.utilitybeam_range_increase.getValue() - keys.utilitybeam_range_decrease.getValue());

            if (keys.utilitybeam_toggle_active.getDown())
                my_player_info->commandSetUtilityBeam(!utility_beam->active);

            if (bearing_input != 0.0f) my_player_info->commandSetUtilityBeamBearing(utility_beam->bearing + bearing_input);
            if (arc_input != 0.0f) my_player_info->commandSetUtilityBeamArc(utility_beam->arc + arc_input);
            if (range_input != 0.0f) my_player_info->commandSetUtilityBeamRange(utility_beam->range + range_input);

            if (keys.utilitybeam_mode_next.getDown())
                LOG(WARNING) << "You forgot to implement prev/next on custom_beam_mode";
            if (keys.utilitybeam_mode_prev.getDown())
                LOG(WARNING) << "You forgot to implement prev/next on custom_beam_mode";
        }
    }
    else
    {
        // Component not available - hide all controls.
        utility_toggle->hide();
        custom_utility_mode->hide();
        utility_bearing->hide();
        utility_bearing_fixed->hide();
        utility_arc->hide();
        utility_arc_fixed->hide();
        utility_range->hide();
        utility_range_fixed->hide();
        utility_progress_bar->hide();
    }
}
