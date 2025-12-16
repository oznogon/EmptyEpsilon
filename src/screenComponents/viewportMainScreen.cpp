#include "viewportMainScreen.h"
#include "gameGlobalInfo.h"
#include "playerInfo.h"
#include "preferenceManager.h"
#include "components/collision.h"
#include "components/target.h"
#include "main.h"

GuiViewportMainScreen::GuiViewportMainScreen(GuiContainer* owner, string id)
: GuiViewport3D(owner, id)
{
    uint8_t flags = PreferencesManager::get("main_screen_flags","7").toInt();

    if (flags & flag_callsigns)
      showCallsigns();
    if (flags & flag_headings)
      showHeadings();
    if (flags & flag_spacedust)
      showSpacedust();

    first_person = PreferencesManager::get("first_person") == "1";
}

void GuiViewportMainScreen::onDraw(sp::RenderTarget& renderer)
{
    float delta = engine->getElapsedTime() - previous_draw;
    previous_draw = engine->getElapsedTime();

    if (my_spaceship)
    {
        auto transform = my_spaceship.getComponent<sp::Transform>();
        if (!transform) return;
        auto pc = my_spaceship.getComponent<PlayerControl>();
        auto target_ship = my_spaceship.getComponent<Target>();

        switch(pc ? pc->main_screen_setting : MainScreenSetting::Front)
        {
        case MainScreenSetting::Front: target_camera_yaw = transform->getRotation(); break;
        case MainScreenSetting::Back:  target_camera_yaw = transform->getRotation() + 180.0f; break;
        case MainScreenSetting::Left:  target_camera_yaw = transform->getRotation() - 90.0f; break;
        case MainScreenSetting::Right: target_camera_yaw = transform->getRotation() + 90.0f; break;
        case MainScreenSetting::Target:
            if ((target_ship && target_ship->entity) || linger_timer > 0.0f)
            {
                if (auto tt = target_ship->entity.getComponent<sp::Transform>())
                {
                    linger_timer = linger_period;
                    auto target_camera_diff = transform->getPosition() - tt->getPosition();
                    target_camera_yaw = vec2ToAngle(target_camera_diff) + 180.0f;
                }
                else linger_timer -= delta;
            }
            else target_camera_yaw = transform->getRotation();
            break;
        default:
            break;
        }
        camera_pitch = 30.0f;

        float camera_ship_distance = 420.0f;
        float camera_ship_height = 420.0f;
        if (first_person)
        {
            float radius = 300.0f;
            auto physics = my_spaceship.getComponent<sp::Physics>();
            if (physics)
                radius = physics->getSize().x;
            camera_ship_distance = -radius;
            camera_ship_height = radius / 10.f;
            camera_pitch = 0;
        }
        auto cameraPosition2D = transform->getPosition() + vec2FromAngle(target_camera_yaw) * -camera_ship_distance;
        glm::vec3 targetCameraPosition(cameraPosition2D.x, cameraPosition2D.y, camera_ship_height);
        if (first_person)
        {
            camera_position = targetCameraPosition;
            camera_yaw = target_camera_yaw;
        }
        else
        {
            camera_position = camera_position * 0.9f + targetCameraPosition * 0.1f;
            camera_yaw += angleDifference(camera_yaw, target_camera_yaw) * 0.1f;
        }
    }
    GuiViewport3D::onDraw(renderer);
}
