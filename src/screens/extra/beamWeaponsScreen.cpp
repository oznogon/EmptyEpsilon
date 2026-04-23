#include "beamWeaponsScreen.h"
#include <i18n.h>
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "preferenceManager.h"

#include "components/reactor.h"
#include "components/shields.h"
#include "components/target.h"
#include "components/radar.h"
#include "components/beamweapon.h"
#include "components/collision.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/beamFrequencySelector.h"
#include "screenComponents/beamTargetSelector.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/powerDamageIndicator.h"
#include "screenComponents/radarView.h"
#include "screenComponents/shieldFreqencySelect.h"
#include "screenComponents/shieldsEnableButton.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"

BeamWeaponsScreen::BeamWeaponsScreen(GuiContainer* owner)
: GuiOverlay(owner, "BEAM_WEAPONS_SCREEN", GuiTheme::getColor("background"))
{
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    background_crosses = new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255});
    background_crosses->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    radar = new GuiRadarView(this, "BEAM_WEAPONS_RADAR", &targets);
    radar
        ->setAutoRotating(PreferencesManager::get("weapons_radar_lock","0") == "1")
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

    beam_info_box = new GuiElement(this, "BEAM_INFO_BOX");
    beam_info_box
        ->setPosition(20.0f, -20.0f, sp::Alignment::BottomLeft)
        ->setSize(280.0f, 150.0f)
        ->hide()
        ->setAttribute("layout", "vertical");

    (new GuiLabel(beam_info_box, "BEAM_INFO_LABEL", tr("Beam info"), 30.0f))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, 50.0f);
    (new GuiBeamFrequencySelector(beam_info_box, "BEAM_FREQUENCY_SELECTOR"))
        ->setSize(GuiElement::GuiSizeMax, 50.0f);
    (new GuiBeamTargetSelector(beam_info_box, "BEAM_TARGET_SELECTOR"))
        ->setSize(GuiElement::GuiSizeMax, 50.0f);
    (new GuiPowerDamageIndicator(beam_info_box, "", ShipSystem::Type::BeamWeapons, sp::Alignment::CenterLeft))
        ->setSize(GuiElement::GuiSizeMax, 50.0f)
        ->setPosition(0.0f, 50.0f, sp::Alignment::TopLeft);

    auto stats = new GuiElement(this, "WEAPONS_STATS");
    stats
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(240.0f, 120.0f)
        ->setAttribute("layout", "vertical");

    energy_display = new GuiKeyValueDisplay(stats, "ENERGY_DISPLAY", 0.45, tr("Energy"), "");
    energy_display
        ->setIcon("gui/icons/energy")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);
    front_shield_display = new GuiKeyValueDisplay(stats, "FRONT_SHIELD_DISPLAY", 0.45, tr("shields","Front"), "");
    front_shield_display
        ->setIcon("gui/icons/shields-fore")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);
    rear_shield_display = new GuiKeyValueDisplay(stats, "REAR_SHIELD_DISPLAY", 0.45, tr("shields", "Rear"), "");
    rear_shield_display
        ->setIcon("gui/icons/shields-aft")
        ->setTextSize(20.0f)
        ->setSize(240.0f, 40.0f);

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

    (new GuiCustomShipFunctions(this, CrewPosition::beamWeaponsOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, GuiElement::GuiSizeMax);
}

void BeamWeaponsScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto reactor = my_spaceship.getComponent<Reactor>();
        energy_display->setVisible(reactor);
        if (reactor)
            energy_display->setValue(string(static_cast<int>(reactor->energy)));

        auto shields = my_spaceship.getComponent<Shields>();
        if (shields && shields->entries.size() > 0)
        {
            front_shield_display->setValue(string(shields->entries[0].percentage()) + "%");
            front_shield_display->show();
        }
        else front_shield_display->hide();

        if (shields && shields->entries.size() > 1)
        {
            rear_shield_display->setValue(string(shields->entries[1].percentage()) + "%");
            rear_shield_display->show();
        }
        else rear_shield_display->hide();

        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});

        beam_info_box->setVisible(my_spaceship.hasComponent<BeamWeaponSys>());
    }

    GuiOverlay::onDraw(renderer);
}

void BeamWeaponsScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    if (keys.weapons_enemy_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable, FactionRelation::Enemy);
            my_player_info->commandSetTarget(targets.get());
        }
    }

    if (keys.weapons_next_target.getDown())
    {
        if (auto transform = my_spaceship.getComponent<sp::Transform>())
        {
            auto lrr = my_spaceship.getComponent<LongRangeRadar>();
            targets.setNext(transform->getPosition(), lrr ? lrr->short_range : 5000.0f, TargetsContainer::Targetable);
            my_player_info->commandSetTarget(targets.get());
        }
    }
}
