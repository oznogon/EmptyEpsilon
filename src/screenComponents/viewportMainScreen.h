#pragma once

#include "viewport3d.h"
#include "ecs/entity.h"

class GuiViewportMainScreen : public GuiViewport3D
{
public:
    GuiViewportMainScreen(GuiContainer* owner, string id);

    virtual void onDraw(sp::RenderTarget& target) override;

    bool first_person = false;

    // When set, overrides my_spaceship as the camera anchor (first-person from this entity).
    sp::ecs::Entity override_entity;

    constexpr static uint8_t flag_callsigns = 0x04;
    constexpr static uint8_t flag_headings  = 0x02;
    constexpr static uint8_t flag_spacedust = 0x01;

private:
    glm::vec2 tot_coordinates{0.0f, 0.0f};
    const float linger_period = 3.0f;
    float linger_timer = 0.0f;
    float previous_draw = 0.0f;
};
