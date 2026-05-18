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

#include "screenComponents/aimLock.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/missileTubeControls.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"

MissileWeaponsScreen::MissileWeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "MISSILE_WEAPONS_SCREEN", GuiTheme::getColor("background"))
{
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255});
    background_crosses->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    // Message if entity lacks the MissileTubes component or mounts.
    no_weapons_label = new GuiLabel(this, "NO_WEAPONS_LABEL", tr("missile_weapons", "No missile weapons"), 50.0f);
    no_weapons_label
        ->setAlignment(sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    missile_controls = new GuiElement(this, "");
    missile_controls
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    radar = new GuiRadarView(missile_controls, "MISSILE_WEAPONS_RADAR", &targets);
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

    missile_aim = new AimLock(missile_controls, "MISSILE_AIM", radar, -90.0f, 360.0f - 90.0f, 0.0f,
        [this](float value)
        {
            tube_controls->setMissileTargetAngle(value);
        }
    );
    missile_aim
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMatchHeight, 850.0f);

    tube_controls = new GuiMissileTubeControls(missile_controls, "MISSILE_TUBES");
    tube_controls->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft);
    radar->enableTargetProjections(tube_controls);

    lock_aim = new AimLockButton(missile_controls, "LOCK_AIM", tube_controls, missile_aim);
    lock_aim
        ->setPosition(250.0f, 20.0f, sp::Alignment::TopCenter)
        ->setSize(130.0f, 50.0f);

    auto stats = new GuiElement(missile_controls, "WEAPONS_STATS");
    stats
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, 120.0f)
        ->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45f, tr("Energy"), "");
    energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(GuiElement::GuiSizeMax, 40.0f);

    (new GuiCustomShipFunctions(this, CrewPosition::missileWeaponsOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void MissileWeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto missile_tubes = my_spaceship.getComponent<MissileTubes>();
        const bool has_tubes = missile_tubes && missile_tubes->mounts.size() > 0;
        background_gradient->setVisible(has_tubes);
        missile_controls->setVisible(has_tubes);
        no_weapons_label->setVisible(!has_tubes);
        if (!has_tubes)
        {
            GuiOverlay::onDraw(renderer);
            return;
        }

        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(static_cast<int>(reactor->energy)));

        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});

        lock_aim->setVisible(true);
        missile_aim->setVisible(tube_controls->getManualAim());
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
            targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable, FactionRelation::Enemy);
            my_player_info->commandSetTarget(targets.get());
        }
    }

    // Select any non-friendly target.
    if (keys.weapons_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
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
}
