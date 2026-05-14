#include "signalQualityIndicator.h"
#include "engine.h"
#include "random.h"
#include "gui/theme.h"

GuiSignalQualityIndicator::GuiSignalQualityIndicator(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    signalquality_style = theme->getStyle("signalquality");
    electrical_band_style = theme->getStyle("signal_bands.electrical");
    thermal_band_style = theme->getStyle("signal_bands.thermal");
    gravitational_band_style = theme->getStyle("signal_bands.gravitational");
    target_period = random(2.0f, 5.0f);
}

void GuiSignalQualityIndicator::onUpdate()
{
    float current_time = engine->getElapsedTime();
    history.push_back({current_time, max_amp});
    while (!history.empty() && current_time - history.front().time > 30.0f)
        history.pop_front();
}

void GuiSignalQualityIndicator::onDraw(sp::RenderTarget& renderer)
{
    // Bail if all bands are hidden.
    if (!show_red && !show_green && !show_blue) return;

    const auto& signalquality = signalquality_style->get(getState());
    renderer.drawStretchedHV(rect, signalquality.size, signalquality.texture);

    if (display_mode == DisplayMode::TimeSeries)
    {
        if (history.size() < 2) return;

        float current_time = engine->getElapsedTime();
        float y_max = 1.0f;
        for (const auto& entry : history)
            y_max = std::max(y_max, entry.value);

        float padding = 5.0f;
        float chart_left = rect.position.x + padding;
        float chart_right = rect.position.x + rect.size.x - padding;
        float chart_bottom = rect.position.y + rect.size.y - padding;
        float chart_top = rect.position.y + padding;

        std::vector<glm::vec2> points;
        for (const auto& entry : history)
        {
            float t = 1.0f - (current_time - entry.time) / 30.0f;
            float x = chart_left + t * (chart_right - chart_left);
            float y = chart_bottom - entry.value / y_max * (chart_bottom - chart_top);
            points.emplace_back(x, y);
        }

        if (show_red)
            renderer.drawLine(points, 2.0f, electrical_band_style->get(getState()).color);
        if (show_green)
            renderer.drawLine(points, 2.0f, thermal_band_style->get(getState()).color);
        if (show_blue)
            renderer.drawLine(points, 2.0f, gravitational_band_style->get(getState()).color);

        return;
    }

    // Bail if there's not enough space to draw the signal.
    int point_count = rect.size.x / 4 - 1;
    if (point_count < 2) return;

    std::vector<glm::vec2> r;
    std::vector<glm::vec2> g;
    std::vector<glm::vec2> b;
    float amp = (rect.size.y * 0.5f - 10.0f) * max_amp;
    float phase[3];
    float freq[3];
    float noise[3] = {error_noise, error_noise, error_noise};
    for (int n = 0; n < 3; n++)
    {
        phase[n] = clock.get() * (2.0f + error_phase * (100.0f + n * 45.0f));
        phase[n] = clock.get() + error_phase * (100.0f + n * 45.0f);
        freq[n] = 2.0f * static_cast<float>(M_PI) / static_cast<float>(point_count) * target_period * (1.0f + (error_period * (n * 2.2f)));
    }

    for (int n = 0; n < point_count; n++)
    {
        float f;
        const float nf = static_cast<float>(n);
        const float half_rect_y = rect.position.y + rect.size.y * 0.5f;
        const float four_rect_x = rect.position.x + 4.0f + nf * 4.0f;

        if (show_red)
        {
            f = sin(nf * freq[0] + phase[0]);
            f = (1.0f - noise[0]) * f + noise[0] * random(-1.0f, 1.0f);
            r.emplace_back(four_rect_x, half_rect_y + f * amp);
        }

        if (show_green)
        {
            f = sin(nf * freq[1] + phase[1]);
            f = (1.0f - noise[1]) * f + noise[1] * random(-1.0f, 1.0f);
            g.emplace_back(four_rect_x, half_rect_y + f * amp);
        }

        if (show_blue)
        {
            f = sin(nf * freq[2] + phase[2]);
            f = (1.0f - noise[2]) * f + noise[2] * random(-1.0, 1.0);
            b.emplace_back(four_rect_x, half_rect_y + f * amp);
        }
    }

    if (show_red) renderer.drawLineBlendAdd(r, 2.0f, electrical_band_style->get(getState()).color);
    if (show_green) renderer.drawLineBlendAdd(g, 2.0f, thermal_band_style->get(getState()).color);
    if (show_blue) renderer.drawLineBlendAdd(b, 2.0f, gravitational_band_style->get(getState()).color);
}

GuiElement* GuiSignalQualityIndicator::getClickElement(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (!visible || !enabled || !rect.contains(position))
        return nullptr;

    GuiElement* result = GuiContainer::getClickElement(button, position, id);
    if (result)
        return result;

    return this;
}

bool GuiSignalQualityIndicator::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    if (display_mode == DisplayMode::Waveform)
        display_mode = DisplayMode::TimeSeries;
    else
        display_mode = DisplayMode::Waveform;
    return true;
}
