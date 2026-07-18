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

    // Layout elements.
    GuiElement* container = new GuiElement(this, "");
    container
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("padding", "50");
    container
        ->setAttribute("layout", "vertical");

    GuiElement* columns = new GuiElement(container, "");
    columns
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontal");
    columns
        ->setAttribute("margin", "0, 0, 0, 20");

    GuiElement* left = new GuiElement(columns, "LEFT_COLUMN");
    left
        ->setSize(250.0f, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");
    left
        ->setAttribute("margin", "0, 20, 0, 0x");

    GuiElement* right = new GuiElement(columns, "RIGHT_COLUMN");
    right
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "vertical");

    // Scenario categories.
    (new GuiLabel(left, "SCENARIO_LABEL", tr("Tutorials"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // List each scenario derived from scenario_*.lua files in Resources.
    GuiListbox* tutorial_list = new GuiListbox(left, "TUTORIAL_LIST",
        [this](int index, string value)
        {
            selectTutorial(value);
        }
    );
    tutorial_list->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    // Fetch and sort all Lua files starting with "tutorial_".
    std::vector<string> tutorial_filenames = findResources("tutorial/*.lua");
    std::sort(tutorial_filenames.begin(), tutorial_filenames.end());

    // For each scenario file, extract its name, then add it to the list.
    for (string filename : tutorial_filenames)
    {
        ScenarioInfo info(filename);
        tutorial_list->addEntry(info.name, filename);
    }

    // Scenario categories.
    (new GuiLabel(right, "DESCRIPTION_LABEL", tr("Description"), GuiElement::GuiSizeLabel))
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("margin", "0, 0, 0, 10");

    // Show the scenario description text.
    tutorial_description = new GuiScrollFormattedText(right, "TUTORIAL_DESCRIPTION", "");
    tutorial_description
        ->setTextSize(30.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

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
