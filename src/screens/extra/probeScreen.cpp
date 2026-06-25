#include "probeScreen.h"
#include "playerInfo.h"
#include "main.h"
#include "i18n.h"

#include "components/radar.h"
#include "components/collision.h"
#include "components/maneuveringthrusters.h"

#include "screenComponents/viewport3d.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/globalMessage.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_label.h"
#include "gui/hotkeyConfig.h"

ProbeScreen::ProbeScreen(GuiContainer* owner)
: GuiOverlay(owner, "PROBE_SCREEN", GuiTheme::getColor("background"))
{
    // Render the radar shadow and background decorations.
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new GuiOverlay(this, "BACKGROUND_CROSSES", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Render the alert level color overlay.
    new AlertLevelOverlay(this);

    // Message if entity lacks a linked probe.
    no_probe_label = new GuiLabel(this, "NO_PROBE_LABEL", tr("probe_screen", "No probe linked"), GuiElement::GuiSizeRow);
    no_probe_label
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->hide();

    viewport = new GuiViewport3D(this, "PROBE_VIEWPORT");
    viewport
        ->showCallsigns()
        ->showSpacedust()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    (new GuiGlobalMessage(this))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void ProbeScreen::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    auto rl = my_spaceship.getComponent<RadarLink>();
    if (rl && rl->linked_entity)
    {
        auto angle = (keys.probe_turn_right.getValue() - keys.probe_turn_left.getValue()) * 5.0f;
        if (angle != 0.0f)
        {
            if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
                my_player_info->commandProbeTargetRotation(probe_transform->getRotation() + angle);
        }

        if (mouse_turn_direction != 0.0f)
        {
            if (auto probe_transform = rl->linked_entity.getComponent<sp::Transform>())
                my_player_info->commandProbeTargetRotation(probe_transform->getRotation() + mouse_turn_direction * 5.0f);
        }
    }
}

void ProbeScreen::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        auto rl = my_spaceship.getComponent<RadarLink>();
        if (rl && rl->linked_entity)
        {
            background_gradient->show();
            no_probe_label->hide();
            viewport->show();

            auto probe_transform = rl->linked_entity.getComponent<sp::Transform>();
            if (probe_transform)
            {
                camera_position.x = probe_transform->getPosition().x;
                camera_position.y = probe_transform->getPosition().y;
                camera_position.z = 0.0f;
                camera_yaw = probe_transform->getRotation();
                camera_pitch = 0.0f;
            }
        }
        else
        {
            viewport->hide();
            no_probe_label->show();
            background_gradient->hide();
        }
    }

    GuiOverlay::onDraw(renderer);
}

bool ProbeScreen::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!my_spaceship || !isVisible()) return false;

    auto rl = my_spaceship.getComponent<RadarLink>();
    if (!rl || !rl->linked_entity) return false;

    mouse_turn_direction = position.x < viewport->getCenterPoint().x ? -1.0f : 1.0f;
    return true;
}

void ProbeScreen::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    mouse_turn_direction = 0.0f;
}
