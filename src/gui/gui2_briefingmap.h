#pragma once

#include "gui/gui2_element.h"
#include "gui/theme.h"
#include "engine.h"
#include "components/briefing.h"
#include <glm/vec2.hpp>
#include <glm/gtc/type_precision.hpp>
#include <vector>

class GuiBriefingMap : public GuiElement
{
private:
    const BriefingMapPage* map_data = nullptr;
    float current_map_time = 0.0f;
    float last_update_time = -1.0f;
    float map_duration = 0.0f;
    glm::vec2 camera_position{0.0f, 0.0f};
    float zoom = 5000.0f;
    std::vector<BriefingMapEntity> active_entities;

    const GuiThemeStyle* map_grid_style = nullptr;

    glm::vec2 worldToScreen(glm::vec2 world_position);
    void tweenToTime(float time);

public:
    GuiBriefingMap(GuiContainer* owner, string id);
    ~GuiBriefingMap();

    void setMapData(const BriefingMapPage* data);
    void clearMapData();

    virtual void onUpdate() override;
    virtual void onDraw(sp::RenderTarget& renderer) override;
};
