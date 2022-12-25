#include "main.h"
#include "zone.h"
#include "playerInfo.h"
#include "particleEffect.h"
#include "explosionEffect.h"
#include "pathPlanner.h"

#include "math/triangulate.h"
#include "math/centerOfMass.h"

#include "scriptInterface.h"

/// A Zone is a polygonal area of space defined by a series of coordinates.
/// Zones are drawn on comms and long-range radar screens, can have a text label, and can return SpaceObjects within their bounds.
REGISTER_SCRIPT_SUBCLASS(Zone, SpaceObject)
{
    /// Sets the corners of this Zone n-gon to x_1, y_1, x_2, y_2, ... x_n, y_n.
    /// Note that positive x coordinates are right/"east" of the origin, and positive y coordinates are down/"south" of the origin in space.
    /// Example: zone = Zone():setPoints(2000, 0, 0, 3000, -2000, 0)
    REGISTER_SCRIPT_CLASS_FUNCTION(Zone, setPoints);
    /// Sets this Zone's color when drawn on radar.
    /// Example: zone:setColor(255, 140, 0)
    REGISTER_SCRIPT_CLASS_FUNCTION(Zone, setColor);
    /// Sets this Zone's text label.
    REGISTER_SCRIPT_CLASS_FUNCTION(Zone, setLabel);
    /// Returns this Zone's text label.
    REGISTER_SCRIPT_CLASS_FUNCTION(Zone, getLabel);
    /// Returns whether the given SpaceObject is inside this Zone.
    REGISTER_SCRIPT_CLASS_FUNCTION(Zone, isInside);
}

REGISTER_MULTIPLAYER_CLASS(Zone, "Zone");
Zone::Zone()
: SpaceObject(1, "Zone")
{
    has_weight = false;
    color = glm::u8vec4(255, 255, 255, 0);

    registerMemberReplication(&outline);
    registerMemberReplication(&triangles);
    registerMemberReplication(&color);
    registerMemberReplication(&label);
}

void Zone::drawOnRadar(sp::RenderTarget& renderer, glm::vec2 position, float scale, float rotation, bool long_range)
{
    if (!long_range || color.a == 0 || !outline.size())
        return;
    std::vector<glm::vec2> outline_points;
    for(auto p : outline)
        outline_points.push_back(position + rotateVec2(p * scale, -rotation));
    renderer.drawTriangles(outline_points, triangles, glm::u8vec4(color.r, color.g, color.b, 64));
    
    outline_points.push_back(position + rotateVec2(outline[0] * scale, -rotation));
    renderer.drawLine(outline_points, glm::u8vec4(color.r, color.g, color.b, 128));

    if (label.length() > 0)
    {
        float font_size = getRadius() * scale / label.length();
        renderer.drawText(sp::Rect(position.x, position.y, 0, 0), label, sp::Alignment::Center, font_size, main_font, glm::u8vec4(color.r, color.g, color.b, 128));
    }
}

void Zone::drawOnGMRadar(sp::RenderTarget& renderer, glm::vec2 position, float scale, float rotation, bool long_range)
{
    if (long_range && color.a == 0)
    {
        color.a = 255;
        drawOnRadar(renderer, position, scale, rotation, long_range);
        color.a = 0;
    }
}

void Zone::setColor(int r, int g, int b)
{
    color = glm::u8vec4(r, g, b, 255);
}

void Zone::setPoints(const std::vector<glm::vec2>& points)
{
    triangles.clear();
    outline = points;

    glm::vec2 position = centerOfMass(outline);
    float radius = 1;
    for(auto& p : outline)
    {
        p -= position;
        radius = std::max(radius, glm::length(p));
    }
    
    Triangulate::process(outline, triangles);

    setPosition(position);
    setRadius(radius);
    setCollisionRadius(1);
}

void Zone::setLabel(string label)
{
    this->label = label;
}

string Zone::getLabel()
{
    return this->label;
}

bool Zone::isInside(P<SpaceObject> obj)
{
    if (!obj)
        return false;
    return insidePolygon(outline, obj->getPosition() - getPosition());
}
