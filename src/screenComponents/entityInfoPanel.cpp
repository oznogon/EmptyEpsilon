#include "soundManager.h"
#include "entityInfoPanel.h"
#include "components/name.h"
#include "components/rendering.h"
#include "engine.h"
#include "textureManager.h"
#include "glObjects.h"
#include "shaderRegistry.h"
#include "systems/rendering.h"

#include <graphics/opengl.h>
#include <glm/glm.hpp>
#include <glm/ext/matrix_transform.hpp>
#include <glm/ext/matrix_clip_space.hpp>
#include <glm/gtc/type_ptr.hpp>

GuiEntityInfoPanel::GuiEntityInfoPanel(GuiContainer* owner, string id, sp::ecs::Entity entity, func_t func)
: GuiPanel(owner, id), entity(entity), func(func)
{
    setAttribute("layout", "vertical");
    setAttribute("padding", "20, 20, 0, 20");

    // Create a container for the 3D model view
    model_view_container = new GuiElement(this, id + "_MODEL_VIEW");
    model_view_container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("alignment", "topcenter");

    // Create labels for callsign and type
    callsign_label = new GuiLabel(this, id + "_CALLSIGN", "", 25.0f);
    callsign_label
        ->setSize(GuiElement::GuiSizeMax, 25.0f);

    type_label = new GuiLabel(this, id + "_TYPE", "", 20.0f);
    type_label
        ->setSize(GuiElement::GuiSizeMax, 20.0f);
}

void GuiEntityInfoPanel::onUpdate()
{
    if (!entity)
    {
        callsign_label->setText("");
        type_label->setText("");
        return;
    }

    // Update callsign
    auto callsign = entity.getComponent<CallSign>();
    if (callsign)
        callsign_label->setText(callsign->callsign);
    else
        callsign_label->setText("");

    // Update type name
    auto type_name = entity.getComponent<TypeName>();
    if (type_name)
        type_label->setText(type_name->localized.empty() ? type_name->type_name : type_name->localized);
    else
        type_label->setText("");
}

void GuiEntityInfoPanel::onDraw(sp::RenderTarget& renderer)
{
    GuiPanel::onDraw(renderer);

    if (!entity) return;

    auto mrc = entity.getComponent<MeshRenderComponent>();
    if (!mrc) return;

    // Get the model view container's rect
    auto container_rect = model_view_container->getRect();
    if (container_rect.size.x <= 0 || container_rect.size.y <= 0) return;

    renderer.finish();

    float camera_fov = 60.0f;
    auto p0 = renderer.virtualToPixelPosition(container_rect.position);
    auto p1 = renderer.virtualToPixelPosition(container_rect.position + container_rect.size);
    glViewport(p0.x, renderer.getPhysicalSize().y - p1.y, p1.x - p0.x, p1.y - p0.y);

    if (GLAD_GL_ES_VERSION_2_0) glClearDepthf(1.0f);
    else glClearDepth(1.0f);

    glClear(GL_DEPTH_BUFFER_BIT);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    auto mesh_radius = mrc->getMesh()->greatest_distance_from_center * mrc->scale;
    float mesh_diameter = mesh_radius * 2.0f;
    float near_clip_boundary = 1.0f;

    auto projection_matrix = glm::perspective(glm::radians(camera_fov), container_rect.size.x / container_rect.size.y, near_clip_boundary, 25000.0f);
    float view_distance = 0.5f * (mesh_diameter / glm::tan(glm::radians(camera_fov / 2.0f)));

    // OpenGL standard: X across (left-to-right), Y up, Z "towards".
    auto view_matrix = glm::rotate(glm::identity<glm::mat4>(), glm::radians(90.0f), glm::vec3(1.0f, 0.0f, 0.0f));
    view_matrix = glm::scale(view_matrix, glm::vec3(1.0f, 1.0f, -1.0f));
    view_matrix = glm::translate(view_matrix, glm::vec3(0.0f, -1.0f * view_distance - near_clip_boundary, 0.0f));
    view_matrix = glm::rotate(view_matrix, glm::radians(-30.0f), glm::vec3(1.0f, 0.0f, 0.0f));
    view_matrix = glm::rotate(view_matrix, glm::radians(engine->getElapsedTime() * 360.0f / 10.0f), glm::vec3(0.0f, 0.0f, 1.0f));

    glDisable(GL_BLEND);
    glBindTexture(GL_TEXTURE_2D, 0);
    glEnable(GL_DEPTH_TEST);

    ShaderRegistry::updateProjectionView(projection_matrix, view_matrix);

    auto model_matrix = calculateModelMatrix(glm::vec2{}, 0.0f, mrc->mesh_offset, mrc->scale);

    auto shader = lookUpShader(*mrc);
    glUniformMatrix4fv(shader.get().uniform(ShaderRegistry::Uniforms::Model), 1, GL_FALSE, glm::value_ptr(model_matrix));

    auto modeldata_matrix = glm::rotate(model_matrix, glm::radians(180.0f), {0.0f, 0.0f, 1.0f});
    modeldata_matrix = glm::scale(modeldata_matrix, glm::vec3{mrc->scale});

    // Setup lights and textures.
    ShaderRegistry::setupLights(shader.get(), modeldata_matrix);
    activateAndBindMeshTextures(*mrc);

    // Draw the mesh.
    drawMesh(*mrc, shader);

    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glViewport(0, 0, renderer.getPhysicalSize().x, renderer.getPhysicalSize().y);
}

GuiEntityInfoPanel* GuiEntityInfoPanel::setEntity(sp::ecs::Entity new_entity)
{
    entity = new_entity;
    return this;
}

bool GuiEntityInfoPanel::onMouseDown(sp::io::Pointer::Button button, glm::vec2 position, sp::io::Pointer::ID id)
{
    return true;
}

void GuiEntityInfoPanel::onMouseUp(glm::vec2 position, sp::io::Pointer::ID id)
{
    if (rect.contains(position))
    {
        soundManager->playSound("sfx/button.wav");
        if (func)
        {
            func_t f = func;
            f(entity);
        }
    }
}

GuiEntityInfoPanelGrid::GuiEntityInfoPanelGrid(GuiContainer* owner, string id, std::vector<sp::ecs::Entity> entities, func_t func)
: GuiElement(owner, id), entities(entities), func(func)
{
    setAttribute("layout", "vertical");
}

void GuiEntityInfoPanelGrid::onDraw(sp::RenderTarget& target)
{
}

void GuiEntityInfoPanelGrid::onUpdate()
{
    children.clear();
    if (entities.empty()) return;

    int max_cols = static_cast<int>(rect.size.x / 200.0f);
    int max_rows = static_cast<int>(rect.size.y / 200.0f);
    int col = 0;
    int row = 0;
    std::vector<GuiElement*> rows;
    rows.emplace_back(new GuiElement(this, ""));
    rows[row]
        ->setSize(GuiElement::GuiSizeMax, 200.0f)
        ->setAttribute("layout", "horizontal");

    for (auto entity : entities)
    {
        col++;

        if (col > max_cols)
        {
            col = 1;
            row++;
            rows.emplace_back(new GuiElement(this, ""));
            rows[row]
                ->setSize(GuiElement::GuiSizeMax, 200.0f)
                ->setAttribute("layout", "horizontal");
        }
        (new GuiEntityInfoPanel(rows[row], "", entity, func))->setSize(200.0f, 200.0f);
    }
}

GuiEntityInfoPanelGrid* GuiEntityInfoPanelGrid::setEntities(std::vector<sp::ecs::Entity> new_entities)
{
    entities = new_entities;
    return this;
}
