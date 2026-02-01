#pragma once

#include "gui2_indicatorlight.h"
#include <glm/vec4.hpp>
#include <cstdio>

/**
 * Annunciator Standard 389 Indicator Light Presets
 *
 * Based on Annunciator Standard 389 annunciator switch specifications.
 * Provides factory functions to create GuiIndicatorLight instances
 * configured for standard aviation indicator behaviors.
 *
 * Legend Types:
 *   S (1B) - Hidden legend, colored text on black when energized
 *   B (1C) - Hidden legend, colored background with black text when energized
 *   W (2D) - Black text on white, colored background when energized
 *   N (2G2) - White text on black, colored text when energized
 *   C (2B) - Black text on colored background (dim/bright)
 *   F (2F) - White text on dark, colored background when energized
 *
 * Colors: Red, Amber, Green, Blue, White
 */
namespace AnnunciatorPresets
{
    // Annunciator Standard 389 colors (approximated from chromaticity values)
    // Based on CIE x,y coordinates from optical characteristics
    enum class Color
    {
        Red,
        Amber,
        Green,
        Blue,
        White
    };

    // Legend types per Annunciator Standard 389
    enum class LegendType
    {
        S,  // 1B - Hidden legend, colored text on black background when energized
        B,  // 1C - Hidden legend, colored background with black text when energized
        W,  // 2D - Black text on white background, colored background when energized
        N,  // 2G2 - White text on black background, colored text when energized
        C,  // 2B - Black text on colored background (dim when off, bright when on)
        F   // 2F - White text on dark background, colored background when energized
    };

    // Get RGB color value for an Annunciator color
    inline glm::u8vec4 getColor(Color color)
    {
        switch (color)
        {
        case Color::Red:    return {255, 50, 50, 255};    // Aviation red
        case Color::Amber:  return {255, 140, 0, 255};    // Aviation amber/orange
        case Color::Green:  return {0, 200, 0, 255};      // Aviation green
        case Color::Blue:   return {50, 100, 255, 255};   // Aviation blue
        case Color::White:  return {255, 255, 255, 255};  // White
        default:            return {255, 255, 255, 255};
        }
    }

    // Get dimmed version of color (for non-energized colored backgrounds)
    inline glm::u8vec4 getDimColor(Color color)
    {
        switch (color)
        {
        case Color::Red:    return {80, 16, 16, 255};
        case Color::Amber:  return {80, 44, 0, 255};
        case Color::Green:  return {0, 64, 0, 255};
        case Color::Blue:   return {16, 32, 80, 255};
        case Color::White:  return {64, 64, 64, 255};
        default:            return {64, 64, 64, 255};
        }
    }

    // Standard background colors
    inline glm::u8vec4 blackBackground() { return {20, 20, 20, 255}; }
    inline glm::u8vec4 whiteBackground() { return {240, 240, 240, 255}; }
    inline glm::u8vec4 darkBackground() { return {40, 40, 40, 255}; }

    // Standard text colors
    inline glm::u8vec4 blackText() { return {0, 0, 0, 255}; }
    inline glm::u8vec4 whiteText() { return {255, 255, 255, 255}; }

    // Convert color to hex markup string
    inline string colorToMarkup(glm::u8vec4 color)
    {
        char buf[32];
        snprintf(buf, sizeof(buf), "<color=#%02X%02X%02X>", color.r, color.g, color.b);
        return string(buf);
    }

    // Wrap text in color markup
    inline string coloredLabel(const string& text, glm::u8vec4 color)
    {
        return colorToMarkup(color) + text + "</>";
    }

    /**
     * Configure indicator for Type S (1B) legend
     * Hidden legend - letters not visible until illuminated.
     * Energized: Colored text on black background
     * Non-energized: Black background, no visible text (or very dim)
     */
    inline void applyTypeS(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        indicator->setActiveColor(blackBackground());
        indicator->setDisabledColor(blackBackground());

        if (energized)
        {
            indicator->setValue(true);
            indicator->setLabel(coloredLabel(label, getColor(color)), IndicatorContentPosition::Inside());
        }
        else
        {
            indicator->setValue(false);
            // Hidden - use very dark text that blends with background
            indicator->setLabel(coloredLabel(label, {30, 30, 30, 255}), IndicatorContentPosition::Inside());
        }
    }

    /**
     * Configure indicator for Type B (1C) legend
     * Hidden legend - letters not visible until illuminated.
     * Energized: Colored background with black text
     * Non-energized: Black background, no visible text
     */
    inline void applyTypeB(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        if (energized)
        {
            indicator->setValue(true);
            indicator->setActiveColor(getColor(color));
            indicator->setLabel(coloredLabel(label, blackText()), IndicatorContentPosition::Inside());
        }
        else
        {
            indicator->setValue(false);
            indicator->setDisabledColor(blackBackground());
            // Hidden - use very dark text
            indicator->setLabel(coloredLabel(label, {30, 30, 30, 255}), IndicatorContentPosition::Inside());
        }
    }

    /**
     * Configure indicator for Type W (2D) legend
     * Opaque black letters on white background.
     * Energized: Colored background with black text
     * Non-energized: White background with black text
     */
    inline void applyTypeW(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        indicator->setLabel(coloredLabel(label, blackText()), IndicatorContentPosition::Inside());

        if (energized)
        {
            indicator->setValue(true);
            indicator->setActiveColor(getColor(color));
        }
        else
        {
            indicator->setValue(false);
            indicator->setDisabledColor(whiteBackground());
        }
    }

    /**
     * Configure indicator for Type N (2G2) legend
     * White letters on black background.
     * Energized: Colored text on black background
     * Non-energized: White text on black background
     */
    inline void applyTypeN(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        indicator->setActiveColor(blackBackground());
        indicator->setDisabledColor(blackBackground());

        if (energized)
        {
            indicator->setValue(true);
            indicator->setLabel(coloredLabel(label, getColor(color)), IndicatorContentPosition::Inside());
        }
        else
        {
            indicator->setValue(false);
            indicator->setLabel(coloredLabel(label, whiteText()), IndicatorContentPosition::Inside());
        }
    }

    /**
     * Configure indicator for Type C (2B) legend
     * Opaque black letters on colored background.
     * Energized: Bright colored background with black text
     * Non-energized: Dim colored background with black text
     */
    inline void applyTypeC(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        indicator->setLabel(coloredLabel(label, blackText()), IndicatorContentPosition::Inside());

        if (energized)
        {
            indicator->setValue(true);
            indicator->setActiveColor(getColor(color));
        }
        else
        {
            indicator->setValue(false);
            indicator->setDisabledColor(getDimColor(color));
        }
    }

    /**
     * Configure indicator for Type F (2F) legend
     * Opaque white letters on dark background.
     * Energized: Colored background with white text
     * Non-energized: Dark background with white text
     */
    inline void applyTypeF(GuiIndicatorLight* indicator, const string& label, Color color, bool energized)
    {
        indicator->setLabel(coloredLabel(label, whiteText()), IndicatorContentPosition::Inside());

        if (energized)
        {
            indicator->setValue(true);
            indicator->setActiveColor(getColor(color));
        }
        else
        {
            indicator->setValue(false);
            indicator->setDisabledColor(darkBackground());
        }
    }

    /**
     * Generic apply function that dispatches to the correct legend type
     */
    inline void apply(GuiIndicatorLight* indicator, const string& label, LegendType type, Color color, bool energized)
    {
        switch (type)
        {
        case LegendType::S: applyTypeS(indicator, label, color, energized); break;
        case LegendType::B: applyTypeB(indicator, label, color, energized); break;
        case LegendType::W: applyTypeW(indicator, label, color, energized); break;
        case LegendType::N: applyTypeN(indicator, label, color, energized); break;
        case LegendType::C: applyTypeC(indicator, label, color, energized); break;
        case LegendType::F: applyTypeF(indicator, label, color, energized); break;
        }
    }

    /**
     * Convenience struct to store an Annunciator indicator configuration
     */
    struct Config
    {
        LegendType type = LegendType::B;
        Color color = Color::Green;
        string label;

        Config() = default;
        Config(LegendType t, Color c, const string& l) : type(t), color(c), label(l) {}

        void apply(GuiIndicatorLight* indicator, bool energized) const
        {
            AnnunciatorPresets::apply(indicator, label, type, color, energized);
        }
    };

}  // namespace AnnunciatorPresets


/**
 * Annunciator Standard 389 Lens Configurations
 *
 * Multi-segment indicator panels following Annunciator lens configuration standards.
 * Each configuration divides the indicator area into segments (A, B, C, D)
 * that can be independently controlled.
 */
class AnnunciatorLensPanel : public GuiElement
{
public:
    // Lens configuration types per Annunciator Standard 389
    enum class Configuration
    {
        Full,              // Single segment (A)
        VerticalSplit,     // Left/Right (A|B)
        HorizontalSplit,   // Top/Bottom (A over B)
        ThreeWayBottom,    // A|B on top, C spanning bottom
        ThreeWayTop,       // A spanning top, B|C on bottom
        ThreeWayRight,     // A on top-left, B spanning right, C on bottom-left
        ThreeWayLeft,      // A spanning left, B on top-right, C on bottom-right
        FourWay            // A|B on top, C|D on bottom
    };

    // Segment identifiers
    enum class Segment { A = 0, B = 1, C = 2, D = 3 };

private:
    Configuration config;
    std::vector<GuiIndicatorLight*> segments;
    float segment_margin = 2.0f;

    void createSegments()
    {
        // Clear existing segments
        for (auto* seg : segments)
        {
            if (seg) seg->destroy();
        }
        segments.clear();

        int num_segments = getSegmentCount();
        for (int i = 0; i < num_segments; i++)
        {
            auto* seg = new GuiIndicatorLight(this, id + "_SEG_" + string(i), false);
            segments.push_back(seg);
        }
    }

    void layoutSegments()
    {
        if (segments.empty()) return;

        float w = rect.size.x;
        float h = rect.size.y;
        float m = segment_margin;
        float half_w = (w - m) / 2.0f;
        float half_h = (h - m) / 2.0f;
        float third_w = (w - 2 * m) / 3.0f;
        float third_h = (h - 2 * m) / 3.0f;
        float two_third_w = third_w * 2 + m;
        float two_third_h = third_h * 2 + m;

        switch (config)
        {
        case Configuration::Full:
            // A fills entire area
            if (segments.size() >= 1)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(w, h);
            }
            break;

        case Configuration::VerticalSplit:
            // A on left, B on right
            if (segments.size() >= 2)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(half_w, h);
                segments[1]->setPosition(half_w + m, 0, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, h);
            }
            break;

        case Configuration::HorizontalSplit:
            // A on top, B on bottom
            if (segments.size() >= 2)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(w, half_h);
                segments[1]->setPosition(0, half_h + m, sp::Alignment::TopLeft);
                segments[1]->setSize(w, half_h);
            }
            break;

        case Configuration::ThreeWayBottom:
            // A|B on top row, C spanning bottom
            if (segments.size() >= 3)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(half_w, half_h);
                segments[1]->setPosition(half_w + m, 0, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, half_h);
                segments[2]->setPosition(0, half_h + m, sp::Alignment::TopLeft);
                segments[2]->setSize(w, half_h);
            }
            break;

        case Configuration::ThreeWayTop:
            // A spanning top, B|C on bottom row
            if (segments.size() >= 3)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(w, half_h);
                segments[1]->setPosition(0, half_h + m, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, half_h);
                segments[2]->setPosition(half_w + m, half_h + m, sp::Alignment::TopLeft);
                segments[2]->setSize(half_w, half_h);
            }
            break;

        case Configuration::ThreeWayRight:
            // A on top-left, B spanning right column, C on bottom-left
            if (segments.size() >= 3)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(half_w, half_h);
                segments[1]->setPosition(half_w + m, 0, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, h);
                segments[2]->setPosition(0, half_h + m, sp::Alignment::TopLeft);
                segments[2]->setSize(half_w, half_h);
            }
            break;

        case Configuration::ThreeWayLeft:
            // A spanning left column, B on top-right, C on bottom-right
            if (segments.size() >= 3)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(half_w, h);
                segments[1]->setPosition(half_w + m, 0, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, half_h);
                segments[2]->setPosition(half_w + m, half_h + m, sp::Alignment::TopLeft);
                segments[2]->setSize(half_w, half_h);
            }
            break;

        case Configuration::FourWay:
            // A|B on top, C|D on bottom
            if (segments.size() >= 4)
            {
                segments[0]->setPosition(0, 0, sp::Alignment::TopLeft);
                segments[0]->setSize(half_w, half_h);
                segments[1]->setPosition(half_w + m, 0, sp::Alignment::TopLeft);
                segments[1]->setSize(half_w, half_h);
                segments[2]->setPosition(0, half_h + m, sp::Alignment::TopLeft);
                segments[2]->setSize(half_w, half_h);
                segments[3]->setPosition(half_w + m, half_h + m, sp::Alignment::TopLeft);
                segments[3]->setSize(half_w, half_h);
            }
            break;
        }
    }

public:
    AnnunciatorLensPanel(GuiContainer* owner, const string& id, Configuration config = Configuration::Full)
        : GuiElement(owner, id), config(config)
    {
        createSegments();
    }

    // Get the number of segments for current configuration
    int getSegmentCount() const
    {
        switch (config)
        {
        case Configuration::Full:            return 1;
        case Configuration::VerticalSplit:   return 2;
        case Configuration::HorizontalSplit: return 2;
        case Configuration::ThreeWayBottom:  return 3;
        case Configuration::ThreeWayTop:     return 3;
        case Configuration::ThreeWayRight:   return 3;
        case Configuration::ThreeWayLeft:    return 3;
        case Configuration::FourWay:         return 4;
        default:                             return 1;
        }
    }

    // Get segment by index (0-3)
    GuiIndicatorLight* getSegment(int index)
    {
        if (index >= 0 && index < static_cast<int>(segments.size()))
            return segments[index];
        return nullptr;
    }

    // Get segment by identifier (A, B, C, D)
    GuiIndicatorLight* getSegment(Segment seg)
    {
        return getSegment(static_cast<int>(seg));
    }

    // Convenience accessors
    GuiIndicatorLight* A() { return getSegment(Segment::A); }
    GuiIndicatorLight* B() { return getSegment(Segment::B); }
    GuiIndicatorLight* C() { return getSegment(Segment::C); }
    GuiIndicatorLight* D() { return getSegment(Segment::D); }

    // Change configuration
    AnnunciatorLensPanel* setConfiguration(Configuration new_config)
    {
        if (config != new_config)
        {
            config = new_config;
            createSegments();
            layoutSegments();
        }
        return this;
    }

    Configuration getConfiguration() const { return config; }

    // Set margin between segments
    AnnunciatorLensPanel* setSegmentMargin(float margin)
    {
        segment_margin = margin;
        layoutSegments();
        return this;
    }

    // Apply Annunciator preset to a specific segment
    AnnunciatorLensPanel* applyPreset(Segment seg, const string& label,
                                       AnnunciatorPresets::LegendType type,
                                       AnnunciatorPresets::Color color, bool energized)
    {
        if (auto* indicator = getSegment(seg))
        {
            AnnunciatorPresets::apply(indicator, label, type, color, energized);
        }
        return this;
    }

    // Apply Annunciator preset to all segments with same settings
    AnnunciatorLensPanel* applyPresetToAll(AnnunciatorPresets::LegendType type,
                                            AnnunciatorPresets::Color color, bool energized)
    {
        for (auto* seg : segments)
        {
            // Keep existing label, just apply style
            AnnunciatorPresets::apply(seg, "", type, color, energized);
        }
        return this;
    }

    // Set energized state for a segment
    AnnunciatorLensPanel* setEnergized(Segment seg, bool energized)
    {
        if (auto* indicator = getSegment(seg))
        {
            indicator->setValue(energized);
        }
        return this;
    }

    // Set label for a segment
    AnnunciatorLensPanel* setSegmentLabel(Segment seg, const string& label)
    {
        if (auto* indicator = getSegment(seg))
        {
            indicator->setLabel(label, IndicatorContentPosition::Inside());
        }
        return this;
    }

    virtual void onUpdate() override
    {
        // Layout is handled when size changes
    }

    virtual void onDraw(sp::RenderTarget& renderer) override
    {
        // Segments draw themselves; we just ensure layout is correct
        layoutSegments();
    }
};


/**
 * Factory functions for common Annunciator lens panel configurations
 */
namespace AnnunciatorLensPanels
{
    // Create a full (single-segment) indicator
    inline AnnunciatorLensPanel* createFull(GuiContainer* owner, const string& id,
                                             const string& label,
                                             AnnunciatorPresets::LegendType type,
                                             AnnunciatorPresets::Color color)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::Full);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, label, type, color, false);
        return panel;
    }

    // Create a vertical split (A|B) indicator
    inline AnnunciatorLensPanel* createVerticalSplit(GuiContainer* owner, const string& id,
                                                      const string& labelA, const string& labelB,
                                                      AnnunciatorPresets::LegendType type,
                                                      AnnunciatorPresets::Color colorA,
                                                      AnnunciatorPresets::Color colorB)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::VerticalSplit);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        return panel;
    }

    // Create a horizontal split (A over B) indicator
    inline AnnunciatorLensPanel* createHorizontalSplit(GuiContainer* owner, const string& id,
                                                        const string& labelA, const string& labelB,
                                                        AnnunciatorPresets::LegendType type,
                                                        AnnunciatorPresets::Color colorA,
                                                        AnnunciatorPresets::Color colorB)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::HorizontalSplit);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        return panel;
    }

    // Create a 3-way bottom split (A|B on top, C on bottom) indicator
    inline AnnunciatorLensPanel* createThreeWayBottom(GuiContainer* owner, const string& id,
                                                       const string& labelA, const string& labelB,
                                                       const string& labelC,
                                                       AnnunciatorPresets::LegendType type,
                                                       AnnunciatorPresets::Color colorA,
                                                       AnnunciatorPresets::Color colorB,
                                                       AnnunciatorPresets::Color colorC)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::ThreeWayBottom);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::C, labelC, type, colorC, false);
        return panel;
    }

    // Create a 3-way top split (A on top, B|C on bottom) indicator
    inline AnnunciatorLensPanel* createThreeWayTop(GuiContainer* owner, const string& id,
                                                   const string& labelA, const string& labelB,
                                                   const string& labelC,
                                                   AnnunciatorPresets::LegendType type,
                                                   AnnunciatorPresets::Color colorA,
                                                   AnnunciatorPresets::Color colorB,
                                                   AnnunciatorPresets::Color colorC)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::ThreeWayTop);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::C, labelC, type, colorC, false);
        return panel;
    }

    // Create a 3-way right split (A top-left, B right, C bottom-left) indicator
    inline AnnunciatorLensPanel* createThreeWayRight(GuiContainer* owner, const string& id,
                                                      const string& labelA, const string& labelB,
                                                      const string& labelC,
                                                      AnnunciatorPresets::LegendType type,
                                                      AnnunciatorPresets::Color colorA,
                                                      AnnunciatorPresets::Color colorB,
                                                      AnnunciatorPresets::Color colorC)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::ThreeWayRight);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::C, labelC, type, colorC, false);
        return panel;
    }

    // Create a 3-way left split (A left, B top-right, C bottom-right) indicator
    inline AnnunciatorLensPanel* createThreeWayLeft(GuiContainer* owner, const string& id,
                                                     const string& labelA, const string& labelB,
                                                     const string& labelC,
                                                     AnnunciatorPresets::LegendType type,
                                                     AnnunciatorPresets::Color colorA,
                                                     AnnunciatorPresets::Color colorB,
                                                     AnnunciatorPresets::Color colorC)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::ThreeWayLeft);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::C, labelC, type, colorC, false);
        return panel;
    }

    // Create a 4-way split (A|B on top, C|D on bottom) indicator
    inline AnnunciatorLensPanel* createFourWay(GuiContainer* owner, const string& id,
                                                const string& labelA, const string& labelB,
                                                const string& labelC, const string& labelD,
                                                AnnunciatorPresets::LegendType type,
                                                AnnunciatorPresets::Color colorA,
                                                AnnunciatorPresets::Color colorB,
                                                AnnunciatorPresets::Color colorC,
                                                AnnunciatorPresets::Color colorD)
    {
        auto* panel = new AnnunciatorLensPanel(owner, id, AnnunciatorLensPanel::Configuration::FourWay);
        panel->applyPreset(AnnunciatorLensPanel::Segment::A, labelA, type, colorA, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::B, labelB, type, colorB, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::C, labelC, type, colorC, false);
        panel->applyPreset(AnnunciatorLensPanel::Segment::D, labelD, type, colorD, false);
        return panel;
    }

}  // namespace AnnunciatorLensPanels
