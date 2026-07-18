#include "shipLogScreen.h"
#include "playerInfo.h"

#include "gui/theme.h"
#include "gui/gui2_advancedscrolltext.h"

#include "screenComponents/alertOverlay.h"
#include "screenComponents/customShipFunctions.h"

#include "components/shiplog.h"

ShipLogScreen::ShipLogScreen(GuiContainer* owner)
: GuiOverlay(owner, "SHIP_LOG_SCREEN", GuiTheme::getColor("background"))
{
    // Draw background elements.
    (new GuiOverlay(this, "", glm::u8vec4{255, 255, 255, 255}))
        ->setTextureTiledThemed("background.crosses");

    new AlertLevelOverlay(this);

    GuiElement* shiplog_layout = new GuiElement(this, "SHIPLOG_LAYOUT");
    shiplog_layout
        ->setPosition(50.0f, 120.0f)
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("layout", "horizontalright");

    custom_function_sidebar = new GuiCustomShipFunctions(shiplog_layout, CrewPosition::shipLog, "");
    custom_function_sidebar->setSize(270.0f, 750.0f);

    log_text = new GuiAdvancedScrollText(shiplog_layout, "SHIP_LOG");
    log_text
        ->enableAutoScrollDown()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
}

void ShipLogScreen::onDraw(sp::RenderTarget& renderer)
{
    GuiOverlay::onDraw(renderer);

    if (!my_spaceship) return;

    auto logs = my_spaceship.getComponent<ShipLog>();
    if (!logs) return;

    custom_function_sidebar->setVisible(custom_function_sidebar->hasEntries());

    if (log_text->getEntryCount() > 0 && logs->size() == 0)
        log_text->clearEntries();

    while (log_text->getEntryCount() > logs->size())
        log_text->removeEntry(0);

    if (log_text->getEntryCount() > 0 && logs->size() > 0 && log_text->getEntryText(0) != logs->get(0).text)
    {
        bool updated = false;
        for (unsigned int n = 1; n < log_text->getEntryCount(); n++)
        {
            if (log_text->getEntryText(n) == logs->get(0).text)
            {
                for (unsigned int m = 0; m < n; m++)
                    log_text->removeEntry(0);
                updated = true;
                break;
            }
        }

        if (!updated) log_text->clearEntries();
    }

    while (log_text->getEntryCount() < logs->size())
    {
        const int n = log_text->getEntryCount();
        const auto& entry = logs->get(n);
        log_text->addEntry(entry.prefix, entry.text, entry.color, 0);
    }
}
