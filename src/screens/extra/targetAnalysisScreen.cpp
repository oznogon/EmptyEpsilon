#include "targetAnalysisScreen.h"
#include "playerInfo.h"
#include "gameGlobalInfo.h"
#include "i18n.h"
#include "featureDefs.h"
#include "vectorUtils.h"

#include "components/radar.h"
#include "components/target.h"
#include "components/hull.h"
#include "components/shields.h"
#include "components/faction.h"
#include "components/scanning.h"
#include "components/name.h"
#include "components/beamweapon.h"
#include "components/collision.h"

#include "screenComponents/radarView.h"
#include "screenComponents/rotatingModelView.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/frequencyCurve.h"
#include "screenComponents/customShipFunctions.h"
#include "screenComponents/globalMessage.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"

TargetAnalysisScreen::TargetAnalysisScreen(GuiContainer* owner)
: GuiOverlay(owner, "TARGET_ANALYSIS_SCREEN", GuiTheme::getColor("background"))
{
    (new GuiImage(this, "BACKGROUND_GRADIENT", ""))
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255,255,255,255}))
        ->setTextureTiledThemed("background.crosses");

    (new AlertLevelOverlay(this));

    auto lrr = my_spaceship.getComponent<LongRangeRadar>();
    radar = new GuiRadarView(this, "TARGET_ANALYSIS_RADAR", lrr ? lrr->short_range : 5000.0f, &targets);
    radar
        ->setRangeIndicatorStepSize(1000.0f)
        ->shortRange()
        ->enableCallsigns()
        ->enableHeadingIndicators()
        ->setStyle(GuiRadarView::Circular)
        ->setCallbacks(
            [this](sp::io::Pointer::Button button, glm::vec2 position)
            {
                if (!my_spaceship) return;
                targets.setToClosestTo(position, 250.0f, TargetsContainer::Selectable);
                if (targets.get())
                    my_player_info->commandSetTarget(targets.get());
                else
                    my_player_info->commandSetTarget({});
            }, nullptr, nullptr, nullptr
        )
        ->setPosition(-310.0f, 0.0f, sp::Alignment::CenterRight)
        ->setSize(GuiElement::GuiSizeMatchHeight, 600.0f);

    model_view = new GuiRotatingModelView(this, "TARGET_MODEL_VIEW", target_entity);
    model_view
        ->setPosition(-320.0f, -20.0f, sp::Alignment::BottomRight)
        ->setSize(280.0f, 280.0f);

    auto info_sidebar = new GuiElement(this, "INFO_SIDEBAR");
    info_sidebar
        ->setPosition(20.0f, 100.0f, sp::Alignment::TopLeft)
        ->setSize(280.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    info_callsign = new GuiKeyValueDisplay(info_sidebar, "INFO_CALLSIGN", 0.4f, tr("analysis", "Callsign"), "-");
    info_callsign->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_distance = new GuiKeyValueDisplay(info_sidebar, "INFO_DISTANCE", 0.4f, tr("analysis", "Distance"), "-");
    info_distance->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_bearing = new GuiKeyValueDisplay(info_sidebar, "INFO_BEARING", 0.4f, tr("analysis", "Bearing"), "-");
    info_bearing->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_relspeed = new GuiKeyValueDisplay(info_sidebar, "INFO_RELSPEED", 0.4f, tr("analysis", "Rel. Speed"), "-");
    info_relspeed->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_faction = new GuiKeyValueDisplay(info_sidebar, "INFO_FACTION", 0.4f, tr("analysis", "Faction"), "-");
    info_faction->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_type = new GuiKeyValueDisplay(info_sidebar, "INFO_TYPE", 0.4f, tr("analysis", "Type"), "-");
    info_type->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_hull = new GuiKeyValueDisplay(info_sidebar, "INFO_HULL", 0.4f, tr("analysis", "Hull"), "-");
    info_hull->setSize(GuiElement::GuiSizeMax, 30.0f);
    info_shields = new GuiKeyValueDisplay(info_sidebar, "INFO_SHIELDS", 0.4f, tr("analysis", "Shields"), "-");
    info_shields->setSize(GuiElement::GuiSizeMax, 30.0f);

    if (gameGlobalInfo->use_beam_shield_frequencies)
    {
        info_shield_frequency = new GuiFrequencyCurve(info_sidebar, "INFO_SHIELD_FREQ", false, true);
        info_shield_frequency->setSize(GuiElement::GuiSizeMax, 80.0f);
        info_beam_frequency = new GuiFrequencyCurve(info_sidebar, "INFO_BEAM_FREQ", true, false);
        info_beam_frequency->setSize(GuiElement::GuiSizeMax, 80.0f);
    }
    else
    {
        info_shield_frequency = nullptr;
        info_beam_frequency = nullptr;
    }

    for (int n = 0; n < ShipSystem::COUNT; n++)
    {
        info_system[n] = new GuiKeyValueDisplay(info_sidebar, "INFO_SYSTEM_" + string(n), 0.75f, getLocaleSystemName(ShipSystem::Type(n)), "-");
        info_system[n]->setSize(GuiElement::GuiSizeMax, 25.0f)->hide();
    }

    (new GuiCustomShipFunctions(this, CrewPosition::scienceOfficer, ""))
        ->setPosition(-20.0f, 120.0f, sp::Alignment::TopRight)
        ->setSize(250.0f, 200.0f);

    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void TargetAnalysisScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto lrr = my_spaceship.getComponent<LongRangeRadar>();
        radar->setDistance(lrr ? lrr->short_range : 5000.0f);

        if (auto tg = my_spaceship.getComponent<Target>())
            targets.set(tg->entity);
        else
            targets.set(sp::ecs::Entity{});
    }

    info_callsign->setValue("-");
    info_distance->setValue("-");
    info_bearing->setValue("-");
    info_relspeed->setValue("-");
    info_faction->setValue("-");
    info_type->setValue("-");
    info_hull->setValue("-");
    info_shields->setValue("-");
    for (int n = 0; n < ShipSystem::COUNT; n++)
        info_system[n]->hide();

    auto target = targets.get();
    if (target)
    {
        target_entity = target;
        model_view->show();

        auto my_transform = my_spaceship.getComponent<sp::Transform>();
        auto target_transform = target.getComponent<sp::Transform>();

        if (my_transform && target_transform)
        {
            auto diff = target_transform->getPosition() - my_transform->getPosition();
            float distance = glm::length(diff);
            float heading = vec2ToAngle(diff) - 270.0f;
            while (heading < 0.0f) heading += 360.0f;

            info_distance->setValue(string(distance / 1000.0f, 1) + DISTANCE_UNIT_1K);
            info_bearing->setValue(string(int(heading)));

            auto my_physics = my_spaceship.getComponent<sp::Physics>();
            auto target_physics = target.getComponent<sp::Physics>();
            if (my_physics && target_physics && distance > 0.0f)
            {
                float rel_velocity = glm::dot(target_physics->getVelocity(), diff / distance) - glm::dot(my_physics->getVelocity(), diff / distance);
                if (std::abs(rel_velocity) < 0.01f)
                    rel_velocity = 0.0f;
                info_relspeed->setValue(string(rel_velocity / 1000.0f * 60.0f, 1) + DISTANCE_UNIT_1K + "/min");
            }
        }

        if (auto cs = target.getComponent<CallSign>())
            info_callsign->setValue(cs->callsign);

        auto scanstate_component = target.getComponent<ScanState>();
        auto scanstate = scanstate_component ? scanstate_component->getStateFor(my_spaceship) : ScanState::State::FullScan;

        if (scanstate >= ScanState::State::SimpleScan)
        {
            auto faction = Faction::getInfo(target);
            info_faction->setValue(faction.locale_name);

            if (auto tn = target.getComponent<TypeName>())
                info_type->setValue(tn->localized);

            if (auto hull = target.getComponent<Hull>())
                info_hull->setValue(string(int(ceil(hull->current))) + "/" + string(int(ceil(hull->max))));

            if (auto shields = target.getComponent<Shields>())
            {
                string str = "";
                for (size_t i = 0; i < shields->entries.size(); i++)
                {
                    if (i > 0) str += "/";
                    str += string(int(shields->entries[i].level));
                }
                info_shields->setValue(str);
            }
        }

        if (scanstate >= ScanState::State::FullScan)
        {
            if (gameGlobalInfo->use_beam_shield_frequencies && info_shield_frequency)
            {
                auto shieldsystem = target.getComponent<Shields>();
                info_shield_frequency->setFrequency(shieldsystem ? shieldsystem->frequency : -1);
                info_shield_frequency->setEnemyHasEquipment(shieldsystem);
                auto beamsystem = target.getComponent<BeamWeaponSys>();
                info_beam_frequency->setFrequency(beamsystem ? beamsystem->frequency : -1);
                info_beam_frequency->setEnemyHasEquipment(beamsystem);
            }

            for (int n = 0; n < ShipSystem::COUNT; n++)
            {
                auto sys = ShipSystem::get(target, ShipSystem::Type(n));
                if (sys)
                {
                    float health = sys->health;
                    info_system[n]
                        ->setValue(string(int(health * 100.0f)) + "%")
                        ->setBackColor(glm::u8vec4(255, uint8_t(127.5f * (health + 1)), uint8_t(127.5f * (health + 1)), 255))
                        ->show();
                }
            }
        }
    }
    else
    {
        target_entity = {};
        model_view->hide();
    }

    GuiOverlay::onDraw(renderer);
}
