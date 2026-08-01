#include "utilityBeamControls.h"
#include <i18n.h>
#include "playerInfo.h"
#include "powerDamageIndicator.h"
#include "crewPosition.h"

#include "components/utilityBeam.h"
#include "components/mounts.h"

#include "gui/gui2_progressbar.h"
#include "gui/gui2_togglebutton.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_keyvaluedisplay.h"

#include <algorithm>

GuiUtilityBeamControls::GuiUtilityBeamControls(GuiContainer* owner, CrewPosition position, string id)
: GuiElement(owner, id), position(position)
{
    // Create all elements unconditionally but hidden.
    utility_progress_bar = new GuiProgressbar(this, "UTILITY_PROGRESS_BAR", 0.0f, 1.0f, 0.0f);
    utility_progress_bar
        ->setColor(glm::u8vec4(192, 192, 192, 64)) // TODO: Theme this
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    // Utility toggle button.
    utility_toggle = new GuiToggleButton(this, "UTILITY_BEAM_TOGGLE", tr("utilityControls", "Activate"),
        [](bool value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetUtilityBeam(value);
                        break;
                    }
                }
            }
        }
    );
    utility_toggle
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    (new GuiPowerDamageIndicator(utility_toggle, "UTILITY_BEAM_TOGGLE_PDI", ShipSystem::Type::UtilityBeam, sp::Alignment::CenterLeft))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    custom_utility_mode = new GuiSelector(this, "CUSTOM_UTILITY_BEAM_MODE",
        [](int index, string value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetCustomUtilityBeamMode(value);
                        break;
                    }
                }
            }
        }
    );
    custom_utility_mode
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    // Utility turret direction slider, shown only when the mount is turreted.
    utility_turret_direction = new GuiSlider(this, "UTILITY_BEAM_TURRET_DIRECTION", 0.0f, 360.0f, 0.0f,
        [](float value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetUtilityBeamDirection(value);
                        break;
                    }
                }
            }
        }
    );
    utility_turret_direction
        ->addOverlay(1, GuiElement::GuiSizeLabel, tr("utilityControls", "Bearing: "))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    utility_bearing_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_BEARING_FIXED", 0.5f, tr("utilityControls", "Bearing"), "0");
    utility_bearing_fixed
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    // Turret lock toggle, visible only when the mount is turreted.
    // When enabled, the turret direction is automatically managed; when
    // disabled, the turret direction is manually managed.
    turret_lock = new GuiToggleButton(this, "UTILITY_TURRET_LOCK", tr("utilityButton", "Turret lock"),
        [](bool value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetUtilityBeamTurretLock(!value);
                        break;
                    }
                }
            }
        }
    );
    turret_lock
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    // Utility arc slider.
    utility_arc = new GuiSlider(this, "UTILITY_BEAM_ARC", 0.0f, 180.0f, 0.0f,
        [](float value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetUtilityBeamArc(value);
                        break;
                    }
                }
            }
        }
    );
    utility_arc
        ->addOverlay(0, GuiElement::GuiSizeLabel, tr("utilityControls", "Arc: "))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    utility_arc_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_ARC_FIXED", 0.5f, tr("utilityControls", "Arc"), "0");
    utility_arc_fixed
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    // Utility range slider.
    utility_range = new GuiSlider(this, "UTILITY_BEAM_RANGE", 0.0f, 3000.0f, 1000.0f,
        [](float value)
        {
            if (!my_spaceship) return;

            if (auto mounts = my_spaceship.getComponent<Mounts>())
            {
                for (auto& m : mounts->mounts)
                {
                    if (m.type == MountType::UtilityBeam)
                    {
                        my_player_info->commandSetUtilityBeamRange(value);
                        break;
                    }
                }
            }
        }
    );
    utility_range
        ->addOverlay(0, GuiElement::GuiSizeLabel, tr("utilityControls", "Range: "))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();

    utility_range_fixed = new GuiKeyValueDisplay(this, "UTILITY_BEAM_RANGE_FIXED", 0.5f, tr("utilityControls", "Range"), "0");
    utility_range_fixed
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->hide();
}

void GuiUtilityBeamControls::onDraw(sp::RenderTarget& target)
{
    if (!my_spaceship) return;

    if (auto mounts = my_spaceship.getComponent<Mounts>())
    {
        Mount* utility_mount = nullptr;
        for (auto& m : mounts->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                utility_mount = &m;
                break;
            }
        }

        if (utility_mount)
        {
            utility_arc
                ->setValue(utility_mount->arc)
                ->setVisible(!utility_mount->fixed_arc);
            utility_arc_fixed
                ->setValue(utility_mount->arc)
                ->setVisible(utility_mount->fixed_arc);

            if (utility_arc->isVisible() && utility_arc->getRangeMax() != utility_mount->max_arc)
                utility_arc->setRange(UTILITY_BEAM_MIN_ARC, utility_mount->max_arc);

            utility_range
                ->setValue(utility_mount->range)
                ->setVisible(!utility_mount->fixed_range);
            utility_range_fixed
                ->setValue(utility_mount->range)
                ->setVisible(utility_mount->fixed_range);

            if (utility_range->isVisible() && utility_range->getRangeMax() != utility_mount->max_range)
                utility_range->setRange(UTILITY_BEAM_MIN_RANGE, utility_mount->max_range);

            // When the turret is manually managed, the crew aims it with the
            // turret direction slider, whose label provides the bearing value.
            // The aim is limited to the turret arc minus the beam arc, so the
            // beam's arc always stays within the turret's swing.
            // Otherwise show the beam's current bearing as read-only.
            const bool turret_manual = utility_mount->turret_arc > 0.0f && utility_mount->turret_locked;
            if (turret_manual)
            {
                const float aim_swing = std::max(0.0f, (utility_mount->turret_arc - utility_mount->arc) * 0.5f);
                const float low = utility_mount->turret_direction - aim_swing;
                const float high = utility_mount->turret_direction + aim_swing;
                if (utility_turret_direction->getRangeMin() != low || utility_turret_direction->getRangeMax() != high)
                    utility_turret_direction->setRange(low, high);

                utility_turret_direction
                    ->setValue(utility_mount->direction)
                    ->show();
                utility_bearing_fixed->hide();
            }
            else
            {
                utility_bearing_fixed
                    ->setValue(string(utility_mount->direction, 1))
                    ->show();
                utility_turret_direction->hide();
            }

            for (int i = 0; i < custom_utility_mode->entryCount(); i++)
            {
                if (custom_utility_mode->getEntryName(i) == utility_mount->custom_beam_mode)
                {
                    if (utility_mount->custom_beam_modes[i].progress >= 0.0f)
                        utility_progress_bar->setValue(utility_mount->custom_beam_modes[i].progress);
                }
            }
        }
    }
}

void GuiUtilityBeamControls::onUpdate()
{
    if (!my_spaceship) return;

    auto mounts = my_spaceship.getComponent<Mounts>();
    Mount* utility_mount = nullptr;

    if (mounts)
    {
        for (auto& m : mounts->mounts)
        {
            if (m.type == MountType::UtilityBeam)
            {
                utility_mount = &m;
                break;
            }
        }
    }

    if (utility_mount)
    {
        // Configure custom mode selector from component data.
        if (utility_mount->custom_beam_modes.size() < 1)
            custom_utility_mode->hide();
        else
        {
            std::vector<string> display_names;
            for (const auto& beam_mode : utility_mount->custom_beam_modes)
                display_names.push_back(beam_mode.name);

            custom_utility_mode
                ->setOptions(display_names, display_names)
                ->show();
        }

        // Sync custom mode selection to authoritative server state.
        int mode_idx = custom_utility_mode->indexByValue(utility_mount->custom_beam_mode);
        if (mode_idx >= 0 && mode_idx != custom_utility_mode->getSelectionIndex())
            custom_utility_mode->setSelectionIndex(mode_idx);

        // Show all controls now that the component is available.
        utility_toggle
            ->setValue(utility_mount->active)
            ->show();
        utility_arc->show();
        utility_range->show();
        utility_progress_bar->show();

        if (utility_mount->turret_arc > 0.0f)
        {
            turret_lock
                ->setValue(!utility_mount->turret_locked)
                ->show();
        }
        else
        {
            utility_turret_direction->hide();
            turret_lock->hide();
        }

        // Hotkey input only when visible.
        if (isEffectivelyVisible())
        {
            auto turret_input = (keys.utilitybeam_bearing_right.getValue() - keys.utilitybeam_bearing_left.getValue());
            auto arc_input = (keys.utilitybeam_arc_increase.getValue() - keys.utilitybeam_arc_decrease.getValue());
            auto range_input = (keys.utilitybeam_range_increase.getValue() - keys.utilitybeam_range_decrease.getValue());

            if (keys.utilitybeam_toggle_active.getDown())
                my_player_info->commandSetUtilityBeam(!utility_mount->active);

            if (utility_mount->turret_arc > 0.0f && utility_mount->turret_locked && turret_input != 0.0f)
                my_player_info->commandSetUtilityBeamDirection(utility_mount->direction + turret_input);
            if (arc_input != 0.0f) my_player_info->commandSetUtilityBeamArc(utility_mount->arc + arc_input);
            if (range_input != 0.0f) my_player_info->commandSetUtilityBeamRange(utility_mount->range + range_input);

            // TODO: Implement previous/next mode hotkeys.
            if (keys.utilitybeam_mode_prev.getDown())
                LOG(Warning, "[ubc] You forgot to implement prev/next on custom_beam_mode.");
            if (keys.utilitybeam_mode_next.getDown())
                LOG(Warning, "[ubc] You forgot to implement prev/next on custom_beam_mode.");
        }
    }
    else
    {
        // Component not available - hide all controls.
        utility_toggle->hide();
        custom_utility_mode->hide();
        utility_turret_direction->hide();
        utility_bearing_fixed->hide();
        utility_arc->hide();
        utility_arc_fixed->hide();
        utility_range->hide();
        utility_range_fixed->hide();
        utility_progress_bar->hide();
        turret_lock->hide();
    }
}
