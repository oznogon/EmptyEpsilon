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
    if (!my_spaceship) return;
    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();
    if (!utility_beam) return;

    utility_progress_bar = new GuiProgressbar(this, "UTILITY_PROGRESS_BAR", 0.0, 1.0, 0.0);
    utility_progress_bar->setColor(glm::u8vec4(192, 192, 192, 64))->setSize(GuiElement::GuiSizeMax, 50);

    // Utility toggle button.
    utility_toggle = new GuiToggleButton(this, "UTILITY_BEAM_TOGGLE", tr("scienceButton", "Activate"), [this](bool value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeam(value);
    });
    utility_toggle->setSize(GuiElement::GuiSizeMax, 50)->setVisible(my_spaceship.hasComponent<UtilityBeam>());
    (new GuiPowerDamageIndicator(utility_toggle, "UTILITY_BEAM_TOGGLE_PDI", ShipSystem::Type::UtilityBeam, sp::Alignment::CenterLeft))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    custom_utility_mode = new GuiSelector(this, "CUSTOM_UTILITY_BEAM_MODE", [this](int index, string value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>())
            my_player_info->commandSetCustomUtilityBeamMode(value);
    });

    if (!utility_beam)
        custom_utility_mode->hide();
    else if (utility_beam->custom_beam_modes.size() < 1)
        custom_utility_mode->hide();
    else
    {
        std::vector<string> display_names;

        for (const auto& beam_mode : utility_beam->custom_beam_modes)
            display_names.push_back(beam_mode.name);

        custom_utility_mode->setOptions(display_names, display_names);

        string init_beam_mode = utility_beam->custom_beam_modes[0].name;

        for (int i = 0; i < custom_utility_mode->entryCount(); i++)
        {
            if (custom_utility_mode->getEntryName(i) == utility_beam->custom_beam_mode)
                init_beam_mode = custom_utility_mode->getEntryName(i);
        }

        my_player_info->commandSetCustomUtilityBeamMode(init_beam_mode);
        custom_utility_mode->show();
    }

    custom_utility_mode->setSelectionIndex(custom_utility_mode->indexByValue(utility_beam->custom_beam_mode));
    custom_utility_mode->setSize(GuiElement::GuiSizeMax, 50);

    // Utility bearing slider.
    utility_bearing = new GuiSlider(this, "UTILITY_BEAM_BEARING", 0.0f, 360.0f, 0.0f, [this](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamBearing(value);
    });
    utility_bearing->addOverlay(1, 30.0f, tr("utilityButton", "Bearing: "))->setSize(GuiElement::GuiSizeMax, 50);

    utility_bearing_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_BEARING_FIXED", 0.5f, tr("utilityControls", "Bearing"), "0");
    utility_bearing_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility arc slider.
    utility_arc = new GuiSlider(this, "UTILITY_BEAM_ARC", 0.0f, 180.0f, 0.0f, [this](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamArc(value);
    });
    utility_arc->addOverlay(1, 30.0f, tr("utilityButton", "Arc: "))->setSize(GuiElement::GuiSizeMax, 50);

    utility_arc_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_ARC_FIXED", 0.5f, tr("utilityControls", "Arc"), "0");
    utility_arc_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Utility range slider.
    utility_range = new GuiSlider(this, "UTILITY_BEAM_RANGE", 0.0f, 3000.0f, 1000.0f, [this](float value)
    {
        if (my_spaceship.hasComponent<UtilityBeam>()) my_player_info->commandSetUtilityBeamRange(value);
    });
    utility_range->addOverlay(1, 30.0f, tr("utilityButton", "Range: "))->setSize(GuiElement::GuiSizeMax, 50);

    utility_range_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_RANGE_FIXED", 0.5f, tr("utilityControls", "Range"), "0");
    utility_range_fixed->setSize(GuiElement::GuiSizeMax, 50)->hide();

    // Update initial utility values with known values.
    if (utility_beam)
    {
        utility_toggle->setValue(utility_beam->active);
        utility_bearing->setValue(utility_beam->bearing);
        utility_beam->setArcAndAdjustRange(utility_beam->arc);
        utility_arc->setRange(utility_beam->MIN_ARC, utility_beam->max_arc);
        utility_arc->setValue(utility_beam->arc);
        utility_range->setRange(utility_beam->max_range * 0.25f, utility_beam->max_range);
        utility_range->setValue(utility_beam->range);
    }
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

        // Sync the custom beam mode selector to the server-authoritative custom_beam_mode.
        int mode_idx = custom_utility_mode->indexByValue(utility_beam->custom_beam_mode);
        if (mode_idx >= 0 && mode_idx != custom_utility_mode->getSelectionIndex())
            custom_utility_mode->setSelectionIndex(mode_idx);

        for (int i = 0; i < custom_utility_mode->entryCount(); i++)
        {
            if (custom_utility_mode->getEntryName(i) == utility_beam->custom_beam_mode)
            {
                if (utility_beam->custom_beam_modes[i].progress >= 0.0f)
                    utility_progress_bar->setValue(utility_beam->custom_beam_modes[i].progress);
//                else
//                    utility_progress_bar->hide();
            }
//            else
//                utility_progress_bar->hide();
        }
    }
}

void GuiUtilityBeamControls::onUpdate()
{
    if (!my_spaceship) return;

    // Hotkey input only when visible.
    if (isVisible())
    {
        if (auto utility_beam = my_spaceship.getComponent<UtilityBeam>())
        {
            auto bearing_input = (keys.utilitybeam_bearing_right.getValue() - keys.utilitybeam_bearing_left.getValue());
            auto arc_input = (keys.utilitybeam_arc_increase.getValue() - keys.utilitybeam_arc_decrease.getValue());
            auto range_input = (keys.utilitybeam_range_increase.getValue() - keys.utilitybeam_range_decrease.getValue());
            auto mode = utility_beam->custom_beam_mode;

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

            if (keys.utilitybeam_toggle_active.getDown())
                my_player_info->commandSetUtilityBeam(!utility_beam->active);

            if (bearing_input != 0.0f) my_player_info->commandSetUtilityBeamBearing(utility_beam->bearing + bearing_input);
            if (arc_input != 0.0f) my_player_info->commandSetUtilityBeamArc(utility_beam->arc + arc_input);
            if (range_input != 0.0f) my_player_info->commandSetUtilityBeamRange(utility_beam->range + range_input);

            if (keys.utilitybeam_mode_next.getDown())
            {
                LOG(WARNING) << "You forgot to implement prev/next on custom_beam_mode";
            }

            if (keys.utilitybeam_mode_prev.getDown())
            {
                LOG(WARNING) << "You forgot to implement prev/next on custom_beam_mode";
            }
        }
    }
}
