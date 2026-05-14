#include "missileWeaponsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"

#include "components/reactor.h"
#include "components/target.h"
#include "components/radar.h"
#include "components/beamweapon.h"
#include "components/collision.h"
#include "components/missiletubes.h"
#include "components/utilityBeam.h"

#include "screenComponents/aimLock.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/missileTubeControls.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/utilityBeamControls.h"
#include "screenComponents/utilityBeamRotationDial.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_selector.h"

MissileWeaponsScreen::MissileWeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "MISSILE_WEAPONS_SCREEN", GuiTheme::getColor("background"))
{
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    radar = new GuiRadarView(this, "MISSILE_WEAPONS_RADAR", &targets);
    radar
        ->setAutoRotating(PreferencesManager::get("weapons_radar_lock", "0") == "1")
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                if (!my_spaceship) return;

                targets.setToClosestTo(position, 250.0f, TargetsContainer::Targetable);
                if (targets.get())
                    my_player_info->commandSetTarget(targets.get());
                else
                    my_player_info->commandSetTarget({});
            }, nullptr, nullptr, nullptr
        )
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 800.0f);

    missile_aim = new AimLock(this, "MISSILE_AIM", radar, -90.0f, 360.0f - 90.0f, 0.0f,
        [this](float value)
        {
            tube_controls->setMissileTargetAngle(value);
        }
    );
    missile_aim
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 850.0f);

    tube_controls = new GuiMissileTubeControls(this, "MISSILE_TUBES");
    tube_controls->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft);
    radar->enableTargetProjections(tube_controls);

    lock_aim = new AimLockButton(this, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim
        ->setPosition(250.0f, 20.0f, sp::Alignment::TopCenter)
        ->setSize(130.0f, 50.0f);

    auto stats = new GuiElement(this, "WEAPONS_STATS");
    stats
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, 120.0f)
        ->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45f, tr("Energy"), "");
    energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    front_shield_display = new GuiKeyValueDisplay(stats, "FRONT_SHIELD_DISPLAY", 0.45f, tr("shields", "Front"), "");
    front_shield_display
        ->setIcon("gui/icons/shields-fore")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    rear_shield_display = new GuiKeyValueDisplay(stats, "REAR_SHIELD_DISPLAY", 0.45f, tr("shields", "Rear"), "");
    rear_shield_display
        ->setIcon("gui/icons/shields-aft")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        (new GuiShieldFrequencySelect(this, "SHIELD_FREQ"))
            ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
            ->setSize(280.0f, 100.0f);
    }
    else
    {
        (new GuiShieldsEnableButton(this, "SHIELDS_ENABLE"))
            ->setPosition(-20.0f, -20.0f, sp::Alignment::BottomRight)
            ->setSize(280.0f, 50.0f);
    }

    auto ub = my_spaceship.getComponent<UtilityBeam>();

    sidebar_selector = new GuiSelector(this, "MISSILE_WEAPONS_SIDEBAR_SELECTOR", [this](int index, string value)
    {
        if (value == "func")
        {
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            utility_beam_sidebar->hide();
            utility_beam_dial->hide();
        }
        else if (value == "util")
        {
            custom_function_sidebar->hide();
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    });
    sidebar_selector->setPosition(-20, 120, sp::Alignment::TopRight)->setSize(250, 50)->hide();

    custom_function_sidebar = new GuiCustomShipFunctions(this, CrewPosition::missileWeaponsOfficer, "MISSILE_WEAPONS_CUSTOM_FUNCS");
    custom_function_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 450.0f)
        ->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(this, CrewPosition::weaponsOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar
        ->setPosition(-20.0f, 170.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 500.0f)
        ->hide()
        ->setAttribute("layout", "vertical");

    utility_beam_dial = new GuiUtilityBeamRotationDial(radar, "UTILITY_BEAM_DIAL", radar);
    utility_beam_dial->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)->hide();

    if (custom_function_sidebar->hasEntries())
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Functions"), "func");
        sidebar_selector->show();
    }
    if (ub && ub->crew_positions.has(CrewPosition::weaponsOfficer))
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Utility Beam"), "util");
        sidebar_selector->show();
    }

    if (sidebar_selector->entryCount() > 0)
    {
        sidebar_selector->setSelectionIndex(0);
        if (sidebar_selector->getSelectionValue() == "func")
            custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
        else if (sidebar_selector->getSelectionValue() == "util")
        {
            utility_beam_sidebar->show();
            utility_beam_dial->show();
        }
    }
}

void MissileWeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(static_cast<int>(reactor->energy)));

        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});

        const bool has_tubes = my_spaceship.hasComponent<MissileTubes>();
        lock_aim->setVisible(has_tubes);
        missile_aim->setVisible(has_tubes && tube_controls->getManualAim());
    }

    GuiOverlay::onDraw(renderer);
}

void MissileWeaponsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Target selection cycle keybinds.
    // Select hostile targets.
    if (keys.weapons_enemy_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setNext(
                transform->getPosition(),
                lrr ? lrr->short_range : 5000.0f,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::KnownHostile
            );
            my_player_info->commandSetTarget(targets.get());
        }
    }
    if (keys.weapons_enemy_prev_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setPrev(
                transform->getPosition(),
                lrr ? lrr->short_range : 5000.0f,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::KnownHostile
            );
            my_player_info->commandSetTarget(targets.get());
        }
    }

    // Select any non-friendly target.
    if (keys.weapons_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setNext(
                transform->getPosition(),
                lrr ? lrr->short_range : 5000.0f,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::NotKnownFriendly
            );
            my_player_info->commandSetTarget(targets.get());
        }
    }
    if (keys.weapons_prev_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setPrev(
                transform->getPosition(),
                lrr ? lrr->short_range : 5000.0f,
                TargetsContainer::ESelectionType::Targetable,
                TargetsContainer::KnownFriendOrFoe::NotKnownFriendly
            );
            my_player_info->commandSetTarget(targets.get());
        }
    }

    auto utility_beam = my_spaceship.getComponent<UtilityBeam>();

    // Synchronize the Functions sidebar tab with current custom ship functions.
    bool should_have_func_tab = custom_function_sidebar->hasEntries();
    bool has_func_tab = sidebar_selector->indexByValue("func") != -1;
    if (should_have_func_tab && !has_func_tab)
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Functions"), "func");
        sidebar_selector->show();
    }
    else if (!should_have_func_tab && has_func_tab)
    {
        bool func_was_selected = sidebar_selector->getSelectionValue() == "func";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("func"));
        custom_function_sidebar->hide();
        if (func_was_selected)
        {
            int util_idx = sidebar_selector->indexByValue("util");
            if (util_idx != -1)
            {
                sidebar_selector->setSelectionIndex(util_idx);
                utility_beam_sidebar->show();
                utility_beam_dial->show();
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }

    // Synchronize the Utility Beam sidebar tab with the current crew_positions mask.
    bool should_have_util_tab = utility_beam && utility_beam->crew_positions.has(CrewPosition::weaponsOfficer);
    bool has_util_tab = sidebar_selector->indexByValue("util") != -1;
    if (should_have_util_tab && !has_util_tab)
    {
        sidebar_selector->addEntry(tr("weaponsTab", "Utility Beam"), "util");
        sidebar_selector->show();
    }
    else if (!should_have_util_tab && has_util_tab)
    {
        bool util_was_selected = sidebar_selector->getSelectionValue() == "util";
        sidebar_selector->removeEntry(sidebar_selector->indexByValue("util"));
        utility_beam_sidebar->hide();
        utility_beam_dial->hide();
        if (util_was_selected)
        {
            int func_idx = sidebar_selector->indexByValue("func");
            if (func_idx != -1)
            {
                sidebar_selector->setSelectionIndex(func_idx);
                custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());
            }
            else
            {
                sidebar_selector->setSelectionIndex(-1);
                sidebar_selector->hide();
            }
        }
        if (sidebar_selector->entryCount() == 0)
            sidebar_selector->hide();
    }

    // Manual missile aiming keybinds.
    auto aim_adjust = (keys.weapons_aim_left.getContinuousValue() + keys.weapons_aim_left.getAxis0Value() + keys.weapons_aim_left.getAxis1Value())
        - (keys.weapons_aim_right.getContinuousValue() + keys.weapons_aim_right.getAxis0Value() + keys.weapons_aim_right.getAxis1Value());
    if (aim_adjust != 0.0f)
    {
        missile_aim->setValue(missile_aim->getValue() - 5.0f * aim_adjust);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
    if (keys.weapons_aim_left.isDiscreteStepDown() || keys.weapons_aim_left.isRepeatReady())
    {
        missile_aim->setValue(missile_aim->getValue() - 5.0f);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
    if (keys.weapons_aim_right.isDiscreteStepDown() || keys.weapons_aim_right.isRepeatReady())
    {
        missile_aim->setValue(missile_aim->getValue() + 5.0f);
        tube_controls->setMissileTargetAngle(missile_aim->getValue());
    }
}
