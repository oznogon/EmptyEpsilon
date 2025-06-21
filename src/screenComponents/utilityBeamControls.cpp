#include <i18n.h>
#include "utilityBeamControls.h"
#include "playerInfo.h"
#include "powerDamageIndicator.h"
#include "components/tractorbeam.h"

#include "gui/gui2_togglebutton.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"

GuiUtilityBeamControls::GuiUtilityBeamControls(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    // Tractor toggle button.
    tractor_toggle = new GuiToggleButton(this, "TRACTOR_TOGGLE", tr("scienceButton", "Activate"), [this](bool value)
    {
        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>()) my_player_info->commandSetTractor(value);
    });
    tractor_toggle->setSize(GuiElement::GuiSizeMax, 50)->setVisible(my_spaceship.hasComponent<TractorBeamSys>());
    (new GuiPowerDamageIndicator(tractor_toggle, "TRACTOR_TOGGLE_PDI", ShipSystem::Type::TractorBeam, sp::Alignment::CenterLeft))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    tractor_mode = new GuiSelector(this, "TRACTOR_MODE", [this](int index, string value)
    {
        if (my_spaceship.hasComponent<TractorBeamSys>())
        {
            if (value == "hold")
                my_player_info->commandSetTractorMode(TractorMode::Hold);
            else if (value == "pull")
                my_player_info->commandSetTractorMode(TractorMode::Pull);
            else if (value == "push")
                my_player_info->commandSetTractorMode(TractorMode::Push);
            else if (value == "reposition")
                my_player_info->commandSetTractorMode(TractorMode::Reposition);
            else
                LOG(WARNING) << "Invalid tractor mode selector: " << value;
        }
    });
    tractor_mode->setOptions({tr("tractorMode", "Hold"), tr("tractorMode", "Pull"), tr("tractorMode", "Push"), tr("tractorMode", "Reposition")}, {"hold", "pull", "push", "reposition"})->setSelectionIndex(0);
    tractor_mode->setSize(GuiElement::GuiSizeMax, 50)->setVisible(my_spaceship.hasComponent<TractorBeamSys>());

    // Tractor bearing slider.
    tractor_bearing = new GuiSlider(this, "TRACTOR_BEARING", 0.0f, 360.0f, 0.0f, [this](float value)
    {
        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>()) my_player_info->commandSetTractorBearing(value);
    });
    tractor_bearing->addOverlay(1, 30.0f, tr("utilityButton", "Bearing: "))->setSize(GuiElement::GuiSizeMax, 50);

    // Tractor arc slider.
    tractor_arc = new GuiSlider(this, "TRACTOR_ARC", 0.0f, 180.0f, 0.0f, [this](float value)
    {
        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>()) my_player_info->commandSetTractorArc(value);
    });
    tractor_arc->addOverlay(1, 30.0f, tr("utilityButton", "Arc: "))->setSize(GuiElement::GuiSizeMax, 50)->setSize(GuiElement::GuiSizeMax, 50);

    // Tractor range slider.
    tractor_range = new GuiSlider(this, "TRACTOR_RANGE", 0.0f, 3000.0f, 1000.0f, [this](float value)
    {
        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>()) my_player_info->commandSetTractorRange(value);
    });
    tractor_range->addOverlay(1, 30.0f, tr("utilityButton", "Range: "))->setSize(GuiElement::GuiSizeMax, 50);

    // Update initial tractor values with known values.
    if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>())
    {
        tractor_toggle->setValue(tractor_system->active);
        tractor_bearing->setValue(tractor_system->bearing);
        tractor_arc->setRange(tractor_system->MIN_ARC, tractor_system->max_arc);
        tractor_arc->setValue(tractor_system->arc);
        tractor_range->setRange(tractor_system->max_range * 0.25f, tractor_system->max_range);
        tractor_range->setValue(tractor_system->range);
    }

    /*
    tractor_dial = new GuiRotationDial(science_radar, "TRACTOR_DIAL", 0.0f, 360.0f, 0.0f, [this](float value)
    {
        auto tractor_system = my_spaceship.getComponent<TractorBeamSys>();
        auto my_transform = my_spaceship.getComponent<sp::Transform>();

        if (tractor_system && my_transform)
        {
            float new_value = value - my_transform->getRotation() + science_radar->getViewRotation() - 90.0f;
            while (new_value < 0.0f) new_value += 360.0f;
            while (new_value > 360.0f) new_value -= 360.0f;

            my_player_info->commandSetTractorBearing(new_value);
        }
    });
    tractor_dial->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();
    */
}

void GuiUtilityBeamControls::onDraw(sp::RenderTarget& target)
{
    if (my_spaceship)
    {
        auto my_transform = my_spaceship.getComponent<sp::Transform>();

        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>())
        {
            if (tractor_arc->getRangeMax() != tractor_system->max_arc)
                tractor_arc->setRange(tractor_system->MIN_ARC, tractor_system->max_arc);
            if (tractor_range->getRangeMax() != tractor_system->max_range)
                tractor_arc->setRange(tractor_system->MIN_RANGE, tractor_system->max_range);

            tractor_bearing->setValue(tractor_system->bearing);
            tractor_arc->setValue(tractor_system->arc);
            tractor_range->setValue(tractor_system->range);

            if (tractor_system->mode == TractorMode::Hold)
                tractor_mode->setSelectionIndex(0);
            else if (tractor_system->mode == TractorMode::Pull)
                tractor_mode->setSelectionIndex(1);
            else if (tractor_system->mode == TractorMode::Push)
                tractor_mode->setSelectionIndex(2);
            else tractor_mode->setSelectionIndex(3);
        }
    }
}

void GuiUtilityBeamControls::onUpdate()
{
    // Handle hotkey input
    if (my_spaceship && isVisible())
    {
        if (auto tractor_system = my_spaceship.getComponent<TractorBeamSys>())
        {
            auto bearing_input = (keys.utilitybeam_bearing_right.getValue() - keys.utilitybeam_bearing_left.getValue());
            auto arc_input = (keys.utilitybeam_arc_increase.getValue() - keys.utilitybeam_arc_decrease.getValue());
            auto range_input = (keys.utilitybeam_range_increase.getValue() - keys.utilitybeam_range_decrease.getValue());
            auto mode = tractor_system->mode;

            if (keys.utilitybeam_toggle_active.getDown())
            { 
                if (tractor_system->active) my_player_info->commandSetTractor(!tractor_system->active);
                else my_player_info->commandSetTractor(true);
            }

            if (bearing_input != 0.0f) my_player_info->commandSetTractorBearing((tractor_system->bearing + 360.0f) + bearing_input);
            if (arc_input != 0.0f) my_player_info->commandSetTractorArc((tractor_system->arc + 360.0f) + arc_input);
            if (range_input != 0.0f) my_player_info->commandSetTractorRange((tractor_system->range + 360.0f) + range_input);

            if (keys.utilitybeam_mode_next.getDown())
            {
                if (mode == TractorMode::Hold)
                    my_player_info->commandSetTractorMode(TractorMode::Pull);
                else if (mode == TractorMode::Pull)
                    my_player_info->commandSetTractorMode(TractorMode::Push);
                else if (mode == TractorMode::Push)
                    my_player_info->commandSetTractorMode(TractorMode::Reposition);
                else if (mode == TractorMode::Reposition)
                    my_player_info->commandSetTractorMode(TractorMode::Hold);
                else LOG(WARNING) << "Invalid tractor mode: " << static_cast<int>(mode);
            }

            if (keys.utilitybeam_mode_prev.getDown())
            {
                if (mode == TractorMode::Hold)
                    my_player_info->commandSetTractorMode(TractorMode::Reposition);
                else if (mode == TractorMode::Pull)
                    my_player_info->commandSetTractorMode(TractorMode::Hold);
                else if (mode == TractorMode::Push)
                    my_player_info->commandSetTractorMode(TractorMode::Pull);
                else if (mode == TractorMode::Reposition)
                    my_player_info->commandSetTractorMode(TractorMode::Push);
                else LOG(WARNING) << "Invalid tractor mode: " << static_cast<int>(mode);
            }

            if (keys.utilitybeam_mode_hold.getDown()) my_player_info->commandSetTractorMode(TractorMode::Hold);
            if (keys.utilitybeam_mode_pull.getDown()) my_player_info->commandSetTractorMode(TractorMode::Pull);
            if (keys.utilitybeam_mode_push.getDown()) my_player_info->commandSetTractorMode(TractorMode::Push);
            if (keys.utilitybeam_mode_reposition.getDown()) my_player_info->commandSetTractorMode(TractorMode::Reposition);
        }
    }
}
