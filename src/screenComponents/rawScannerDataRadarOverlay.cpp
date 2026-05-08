#include "rawScannerDataRadarOverlay.h"
#include "radarView.h"
#include "playerInfo.h"
#include "random.h"
#include "components/collision.h"
#include "components/radar.h"
#include "ecs/query.h"
#include "gui/theme.h"

RawScannerDataRadarOverlay::RawScannerDataRadarOverlay(GuiRadarView* owner, string id)
: GuiElement(owner, id), radar(owner)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    electrical_band_style = theme->getStyle("signal_bands.electrical");
    thermal_band_style = theme->getStyle("signal_bands.thermal");
    gravitational_band_style = theme->getStyle("signal_bands.gravitational");
}

void RawScannerDataRadarOverlay::onDraw(sp::RenderTarget& renderer)
{
    if (!my_spaceship)
        return;
    auto distance = radar->getDistance();

    auto view_position = radar->getViewPosition();
    float view_rotation = radar->getViewRotation();

    // Cap the number of signature points, which determines the raw data's
    // resolution.
    const int point_count = 512;
    float radius = std::min(rect.size.x, rect.size.y) / 2.0f;

    RawRadarSignatureInfo signatures[point_count];

    // For each entity with radar signature info ...
    for(auto [entity, signature, dynamic_signature, transform] : sp::ecs::Query<RawRadarSignatureInfo, sp::ecs::optional<DynamicRadarSignatureInfo>, sp::Transform>())
    {
        // Don't measure our own ship.
        if (entity == my_spaceship)
            continue;

        // Initialize angle, distance, and scale variables.
        float a_0, a_1;
        float dist = glm::length(transform.getPosition() - view_position);
        float scale = 1.0;

        // If the object is more than twice as far away as the maximum radar
        // range, disregard it.
        if (dist > distance * 2.0f)
            continue;

        // The further away the object is, the less its effect on radar data.
        if (dist > distance)
            scale = 1.0f - ((dist - distance) / distance);

        auto physics = entity.getComponent<sp::Physics>();
        // If we're adjacent to the object ...
        if (physics && dist <= physics->getSize().x)
        {
            // ... affect all angles of the radar.
            a_0 = 0.0f;
            a_1 = 360.0f;
        }else{
            // Otherwise, measure the affected range of angles by the object's
            // distance and radius.
            float a_diff = glm::degrees(asinf((physics ? physics->getSize().x : 300.0f) / dist));
            float a_center = vec2ToAngle(transform.getPosition() - view_position);
            a_0 = a_center - a_diff;
            a_1 = a_center + a_diff;
        }

        // Get the object's radar signature. If it has a dynamic signature, adjust
        // it based on its current state and activity.
        RawRadarSignatureInfo info = signature;
        if (dynamic_signature)
        {
            info.gravitational += dynamic_signature->gravitational;
            info.electrical += dynamic_signature->electrical;
            info.thermal += dynamic_signature->thermal;
        }

        // For each interval determined by the level of raw data resolution,
        // initialize the signatures array.
        for (float a = a_0; a <= a_1; a += 360.f / static_cast<float>(point_count))
        {
            int idx = (static_cast<int>(a / 360.0f * point_count) + point_count * 2) % point_count;
            signatures[idx] += info * scale;
        }
    }

    // Initialize the data's amplitude along each of the three color bands.
    float amp_r[point_count];
    float amp_g[point_count];
    float amp_b[point_count];

    // For each data point ...
    for(int n = 0; n < point_count; n++)
    {
        // ... initialize its values in the array ...
        signatures[n].gravitational = std::max(0.0f, std::min(1.0f, signatures[n].gravitational));
        signatures[n].electrical = std::max(0.0f, std::min(1.0f, signatures[n].electrical));
        signatures[n].thermal = std::max(0.0f, std::min(1.0f, signatures[n].thermal));

        // ... make some noise ...
        float r = random(-1, 1);
        float g = random(-1, 1);
        float b = random(-1, 1);

        // ... and then modify the bands' values based on the object's signature.
        // Thermal signatures amplify the green band.
        g += signatures[n].thermal * 30;

        // Electrical signatures amplify the red band.
        r += random(-20, 20) * signatures[n].electrical;

        // Gravitational signatures amplify the blue band.
        b = b * (1.0f - signatures[n].gravitational) + 40 * signatures[n].gravitational;

        // Apply the values to the radar bands.
        amp_r[n] = r;
        amp_g[n] = g;
        amp_b[n] = b;
    }

    // Create a vertex array containing each data point.
    std::vector<glm::vec2> a_r;
    std::vector<glm::vec2> a_g;
    std::vector<glm::vec2> a_b;

    // For each data point ...
    for (int n = 0; n < point_count; n++)
    {
        // ... set a baseline of 0 ...
        float r = 0.0f;
        float g = 0.0f;
        float b = 0.0f;

        // ... then sum the amplitude values ...
        for (int m = n - 2 + point_count; m <= n + 2 + point_count; m++)
        {
            r += amp_r[m % point_count];
            g += amp_g[m % point_count];
            b += amp_b[m % point_count];
        }

        // ... divide them by 5 ...
        r /= 5.0f;
        g /= 5.0f;
        b /= 5.0f;

        // ... and add vectors for each point.
        const float x_half = rect.position.x + rect.size.x * 0.5f;
        const float y_half = rect.position.y + rect.size.y * 0.5f;
        const float angle = static_cast<float>(n) / static_cast<float>(point_count) * 360.0f - view_rotation;

        a_r.push_back(glm::vec2(x_half, y_half) + vec2FromAngle(angle) * (radius * (0.95f - r / 500.0f)));
        a_g.push_back(glm::vec2(x_half, y_half) + vec2FromAngle(angle) * (radius * (0.92f - g / 500.0f)));
        a_b.push_back(glm::vec2(x_half, y_half) + vec2FromAngle(angle) * (radius * (0.89f - b / 500.0f)));
    }

    // Set a zero value at the "end" of the data point array.
    a_r.push_back(a_r.front());
    a_g.push_back(a_g.front());
    a_b.push_back(a_b.front());

    // Draw each band as a line.
    renderer.drawLineBlendAdd(a_r, 1.0f, electrical_band_style->get(getState()).color);
    renderer.drawLineBlendAdd(a_g, 1.0f, thermal_band_style->get(getState()).color);
    renderer.drawLineBlendAdd(a_b, 1.0f, gravitational_band_style->get(getState()).color);
}
