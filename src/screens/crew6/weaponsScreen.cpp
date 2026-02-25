#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "weaponsScreen.h"
#include "preferenceManager.h"

#include "components/reactor.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/radar.h"
#include "components/beamweapon.h"
#include "components/collision.h"

#include "screenComponents/missileTubeControls.h"
#include "screenComponents/aimLock.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/shieldFreqencySelect.h"
#include "screenComponents/shieldsEnableButton.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/utilityBeamControls.h"

#include "components/customshipfunction.h"
#include "components/utilityBeam.h"

#include "gui/gui2_selector.h"

#include "screenComponents/utilityBeamRotationDial.h"
#include "gui/gui2_label.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"


WeaponsScreen::WeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "WEAPONS_SCREEN", colorConfig.background)
{
    // Render the radar shadow and background decorations.
    (new GuiImage(this, "BACKGROUND_GRADIENT", "gui/background/gradient.png"))->setPosition(glm::vec2(0, 0), sp::Alignment::Center)->setSize(1200, 900);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiled("gui/background/crosses.png");

    // Render the alert level color overlay.
    (new AlertLevelOverlay(this));

    radar = new GuiRadarView(this, "WEAPONS_RADAR", &targets);
    radar->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 800);
    radar->setRangeIndicatorStepSize(1000.0)->shortRange()->enableCallsigns()->enableHeadingIndicators()->setStyle(GuiRadarView::Circular);
    radar->setCallbacks(
        [this](sp::io::Pointer::Button button, glm::vec2 position) {
            targets.setToClosestTo(position, 250, TargetsContainer::Targetable);
            if (my_spaceship && targets.get())
                my_player_info->commandSetTarget(targets.get());
            else if (my_spaceship)
                my_player_info->commandSetTarget({});
        }, nullptr, nullptr
    );
    radar->setAutoRotating(PreferencesManager::get("weapons_radar_lock","0")=="1");

    missile_aim = new AimLock(this, "MISSILE_AIM", radar, -90, 360 - 90, 0, [this](float value){
        tube_controls->setMissileTargetAngle(value);
    });
    missile_aim->setPosition(0, 0, sp::Alignment::Center)->setSize(GuiElement::GuiSizeMatchHeight, 850);

    tube_controls = new GuiMissileTubeControls(this, "MISSILE_TUBES");
    tube_controls->setPosition(20, -20, sp::Alignment::BottomLeft);
    radar->enableTargetProjections(tube_controls);

    lock_aim = new AimLockButton(this, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim->setPosition(250, 20, sp::Alignment::TopCenter)->setSize(130, 50);

    if (gameGlobalInfo->use_beam_shield_frequencies || gameGlobalInfo->use_system_damage)
    {
        beam_info_box = new GuiElement(this, "BEAM_INFO_BOX");
        beam_info_box->setPosition(-20, -120, sp::Alignment::BottomRight)->setSize(280, 150);
        (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beam info"), 30))->addBackground()->setSize(GuiElement::GuiSizeMax, 50);
        (new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft))->setSize(GuiElement::GuiSizeMax, 50);
        (new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR"))->setPosition(0, 0, sp::Alignment::BottomRight)->setSize(GuiElement::GuiSizeMax, 50);
        (new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR"))->setPosition(0, -50, sp::Alignment::BottomRight)->setSize(GuiElement::GuiSizeMax, 50);

        if (!gameGlobalInfo->use_beam_shield_frequencies)
        {   //If we do have system damage, but no shield frequencies, we can partially overlap this with the shield button.
            //So move the beam configuration a bit down.
            beam_info_box->setPosition(-20, -50, sp::Alignment::BottomRight);
        }
    }

    auto stats = new GuiElement(this, "WEAPONS_STATS");
    stats->setPosition(20, 100, sp::Alignment::TopLeft)->setSize(240, 120)->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45, tr("Energy"), "");
    energy_display->setIcon("gui/icons/energy")->setTextSize(20)->setSize(240, 40);
    front_shield_display = new GuiKeyValueDisplay(stats, "FRONT_SHIELD_DISPLAY", 0.45, tr("shields","Front"), "");
    front_shield_display->setIcon("gui/icons/shields-fore")->setTextSize(20)->setSize(240, 40);
    rear_shield_display = new GuiKeyValueDisplay(stats, "REAR_SHIELD_DISPLAY", 0.45, tr("shields", "Rear"), "");
    rear_shield_display->setIcon("gui/icons/shields-aft")->setTextSize(20)->setSize(240, 40);

    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        //The shield frequency selection includes a shield enable button.
        (new GuiShieldFrequencySelect(this, "SHIELD_FREQ"))->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 100);
    }else{
        (new GuiShieldsEnableButton(this, "SHIELDS_ENABLE"))->setPosition(-20, -20, sp::Alignment::BottomRight)->setSize(280, 50);
    }

    auto ub = my_spaceship.getComponent<UtilityBeam>();

    sidebar_selector = new GuiSelector(this, "WEAPONS_SIDEBAR_SELECTOR", [this](int index, string value)
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

    custom_function_sidebar = new GuiCustomShipFunctions(this, CrewPosition::weaponsOfficer, "WEAPONS_CUSTOM_FUNCS");
    custom_function_sidebar->setPosition(-20, 170, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax)->hide();

    utility_beam_sidebar = new GuiUtilityBeamControls(this, CrewPosition::weaponsOfficer, "UTILITY_BEAM_CONTROLS");
    utility_beam_sidebar->setPosition(-20, 170, sp::Alignment::TopRight)->setSize(250, GuiElement::GuiSizeMax)->setAttribute("layout", "vertical");
    utility_beam_sidebar->hide();

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

    // Set initial sidebar state by manually applying the first tab.
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

void WeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(int(reactor->energy)));
        auto shields = my_spaceship.getComponent<Shields>();
        if (shields && shields->entries.size() > 0) {
            front_shield_display->setValue(string(shields->entries[0].percentage()) + "%");
            front_shield_display->show();
        } else {
            front_shield_display->hide();
        }
        if (shields && shields->entries.size() > 1) {
            rear_shield_display->setValue(string(shields->entries[1].percentage()) + "%");
            rear_shield_display->show();
        } else {
            rear_shield_display->hide();
        }
        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});

        if (utility_beam_dial->isVisible())
            missile_aim->hide();
        else
            missile_aim->setVisible(tube_controls->getManualAim());
        if (beam_info_box)
            beam_info_box->setVisible(my_spaceship.hasComponent<BeamWeaponSys>());
    }
    GuiOverlay::onDraw(renderer);
}

void WeaponsScreen::onUpdate()
{
    if (my_spaceship && isVisible())
    {
        if (keys.weapons_enemy_next_target.getDown())
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>()) {
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();
                targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable, FactionRelation::Enemy);
                my_player_info->commandSetTarget(targets.get());
            }
        }
        if (keys.weapons_next_target.getDown())
        {
            if (auto transform = my_spaceship.getComponent<sp::Transform>()) {
                auto lrr = my_spaceship.getComponent<LongRangeRadar>();
                targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable);
                my_player_info->commandSetTarget(targets.get());
            }
        }
        auto aim_adjust = keys.weapons_aim_left.getValue() - keys.weapons_aim_right.getValue();
        if (aim_adjust != 0.0f)
        {
            missile_aim->setValue(missile_aim->getValue() - 5.0f * aim_adjust);
            tube_controls->setMissileTargetAngle(missile_aim->getValue());
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
    }
}
