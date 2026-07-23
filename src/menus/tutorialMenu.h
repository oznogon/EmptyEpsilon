#pragma once

#include "gui/gui2_canvas.h"
#include "Updatable.h"

class GuiButton;
class GuiElement;
class GuiScrollFormattedText;

class TutorialMenu : public GuiCanvas, public Updatable
{
private:
    string selected_tutorial_filename;

    GuiElement* bottom_row;
    GuiScrollFormattedText* tutorial_description;
    GuiButton* start_tutorial_button;

    void selectTutorial(string filename);
public:
    TutorialMenu();

    virtual void update(float delta) override;
};
