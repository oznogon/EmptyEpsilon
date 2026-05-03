#include "probeScreen.h"
#include "playerInfo.h"
#include "main.h"
#include "i18n.h"

#include "components/radar.h"
#include "components/collision.h"

#include "screenComponents/viewport3d.h"
#include "screenComponents/alertOverlay.h"
#include "screenComponents/globalMessage.h"

#include "gui/theme.h"
#include "gui/gui2_image.h"
#include "gui/gui2_label.h"

ProbeScreen::ProbeScreen(GuiContainer* owner)
: GuiOverlay(owner, "PROBE_SCREEN", GuiTheme::getColor("background"))
{
    background_gradient = new GuiImage(this, "BACKGROUND_GRADIENT", "");
    background_gradient
        ->setTextureThemed("background.gradient")
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(1200.0f, 900.0f);

    (new AlertLevelOverlay(this));

    viewport = new GuiViewport3D(this, "PROBE_VIEWPORT");
    viewport
        ->showCallsigns()
        ->showSpacedust()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    no_probe_label = new GuiLabel(this, "NO_PROBE_LABEL", tr("probe_screen", "No probe linked"), 30.0f);
    no_probe_label
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->setSize(400.0f, 50.0f)
        ->hide();

    (new GuiGlobalMessage(this))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
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
