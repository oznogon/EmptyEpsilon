#ifndef GUI2_IMAGE_CONTAIN_H
#define GUI2_IMAGE_CONTAIN_H

#include "gui2_image.h"

class GuiImageContain : public GuiImage
{
public:
    GuiImageContain(GuiContainer* owner, string id, string texture_name);

    virtual void onDraw(sp::RenderTarget& renderer) override;
};

#endif//GUI2_IMAGE_CONTAIN_H
