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

    (new GuiCustomShipFunctions(this, CrewPosition::missileWeaponsOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
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
