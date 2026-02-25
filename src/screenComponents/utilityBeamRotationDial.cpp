#include "utilityBeamRotationDial.h"
#include "playerInfo.h"
#include "screenComponents/radarView.h"
#include "components/utilityBeam.h"

GuiUtilityBeamRotationDial::GuiUtilityBeamRotationDial(GuiContainer* owner, string id, GuiRadarView* radar)
: GuiRotationDial(owner, id, 0.0f, 360.0f, 0.0f, [radar](float value)
{
    auto my_transform = my_spaceship.getComponent<sp::Transform>();
    if (my_spaceship.hasComponent<UtilityBeam>() && my_transform)
    {
        float new_value = value - my_transform->getRotation() + radar->getViewRotation() - 90.0f;
        while (new_value < 0.0f) new_value += 360.0f;
        while (new_value > 360.0f) new_value -= 360.0f;
        my_player_info->commandSetUtilityBeamBearing(new_value);
    }
}), radar(radar)
{
}

void GuiUtilityBeamRotationDial::onDraw(sp::RenderTarget& renderer)
{
    if (my_spaceship)
    {
        if (auto utility_beam = my_spaceship.getComponent<UtilityBeam>())
        {
            if (auto my_transform = my_spaceship.getComponent<sp::Transform>())
                setValue(utility_beam->bearing + my_transform->getRotation() - radar->getViewRotation() + 90.0f);
        }
    }
    GuiRotationDial::onDraw(renderer);
}
