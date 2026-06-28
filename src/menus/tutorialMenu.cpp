#include "tutorialMenu.h"
#include <i18n.h>
#include "engine.h"
#include "main.h"
#include "preferenceManager.h"
#include "tutorialGame.h"
#include "scenarioInfo.h"

#include "gui/theme.h"
#include "gui/gui2_button.h"
#include "gui/gui2_keyvaluedisplay.h"
#include "gui/gui2_label.h"
#include "gui/gui2_listbox.h"
#include "gui/gui2_overlay.h"
#include "gui/gui2_panel.h"
#include "gui/gui2_scrolltextcontainer.h"
#include "gui/gui2_selector.h"
#include "gui/gui2_slider.h"

TutorialMenu::TutorialMenu()
{
    // Draw background decorations.
    new GuiOverlay(this, "", GuiTheme::getColor("background"));
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    // Draw a one-column autolayout container with margins.
    container = new GuiElement(this, "TUTORIAL_CONTAINER");
    container
        ->setPosition(0.0f, 0.0f, sp::Alignment::TopLeft)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    container
        ->setAttribute("padding", "50");

    // Tutorial section.
    (new GuiLabel(container, "TUTORIAL_LABEL", tr("title", "Tutorials"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // List each scenario derived from scenario_*.lua files in Resources.
    GuiListbox* tutorial_list = new GuiListbox(container, "TUTORIAL_LIST",
        [this](int index, string value)
        {
            selectTutorial(value);
        }
    );
    tutorial_list->setSize(GuiElement::GuiSizeMax, 350.0f);

    // Fetch and sort all Lua files starting with "tutorial_".
    std::vector<string> tutorial_filenames = findResources("tutorial/*.lua");
    std::sort(tutorial_filenames.begin(), tutorial_filenames.end());

    // For each scenario file, extract its name, then add it to the list.
    for (string filename : tutorial_filenames)
    {
        ScenarioInfo info(filename);
        tutorial_list->addEntry(info.name, filename);
    }

    // Show the scenario description text.
    GuiPanel* panel = new GuiPanel(container, "TUTORIAL_DESCRIPTION_BOX");
    panel
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 20");

    tutorial_description = new GuiScrollFormattedText(panel, "TUTORIAL_DESCRIPTION", "");
    tutorial_description
        ->setTextSize(30.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "20");

    // Bottom GUI.
    bottom_row = new GuiElement(container, "TUTORIAL_BOTTOM_ROW");
    bottom_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    // Back button.
    // Close this menu, stop the music, and return to the main menu.
    (new GuiButton(bottom_row, "BACK", tr("button", "Back"),
        [this]()
        {
            destroy();
            returnToMainMenu(getRenderLayer());
        }
    ))
        ->setSize(250.0f, GuiElement::GuiSizeMax);

    (new GuiElement(bottom_row, "SPACER"))
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Start tutorial button.
    start_tutorial_button = new GuiButton(bottom_row, "START_TUTORIAL", tr("Start tutorial"), 
        [this]()
        {
            destroy();
            new TutorialGame(false,selected_tutorial_filename);
        }
    );
    start_tutorial_button
        ->setEnable(false)
        ->setSize(250.0f, GuiElement::GuiSizeMax);


    // Select the first scenario in the list by default.
    if (!tutorial_filenames.empty())
    {
        tutorial_list->setSelectionIndex(0);
        selectTutorial(tutorial_filenames.front());
    }
}

void TutorialMenu::selectTutorial(string filename)
{
    selected_tutorial_filename = filename;
    start_tutorial_button->setEnable(true);
    ScenarioInfo info(filename);
    tutorial_description->setText(info.description);
}

void TutorialMenu::update(float delta)
{
    if (keys.escape.getDown())
    {
        destroy();
        returnToMainMenu(getRenderLayer());
    }
}
