#include "scanningDialog.h"
#include "i18n.h"
#include "playerInfo.h"
#include "random.h"
#include "engine.h"

#include "gui/gui2_panel.h"
#include "gui/gui2_label.h"
#include "gui/gui2_slider.h"
#include "gui/gui2_button.h"

#include "components/scanning.h"

GuiScanningDialog::GuiScanningDialog(GuiContainer* owner, string id)
: GuiElement(owner, id)
{
    setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    box = new GuiPanel(this, id + "_BOX");
    box
        ->setSize(500.0f, 545.0f)
        ->setPosition(0.0f, 0.0f, sp::Alignment::Center)
        ->hide()
        ->setAttribute("layout", "vertical");
    box
        ->setAttribute("padding", "20, 20, 0, 20");

    signal_label = new GuiLabel(box, id + "_LABEL", tr("scanning", "Electric signature"), 30.0f);
    signal_label
        ->addBackground()
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow);

    signal_quality = new GuiSignalQualityIndicator(box, id + "_SIGNAL");
    signal_quality
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax)
        ->setAttribute("margin", "0, 10");

    locked_label = new GuiLabel(signal_quality, id + "_LOCK_LABEL", tr("scanning", "LOCKED"), GuiElement::GuiSizeRow);
    locked_label->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    for (int n = 0; n < MAX_SLIDERS; n++)
    {
        sliders[n] = new GuiSlider(box, id + "_SLIDER_" + string(n), 0.0f, 1.0f, 0.0f, nullptr);
        sliders[n]
            ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
            ->setAttribute("margin", "0, 10");
    }

    auto* cancel_row = new GuiElement(box, "CANCEL");
    cancel_row
        ->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeRow)
        ->setAttribute("layout", "horizontal");

    (new GuiElement(cancel_row, ""))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);
    cancel_button = new GuiButton(cancel_row, id + "_CANCEL", tr("button", "Cancel"),
        []()
        {
            if (my_spaceship) my_player_info->commandScanCancel();
        }
    );
    cancel_button->setSize(300.0f, GuiElement::GuiSizeMax);
    (new GuiElement(cancel_row, ""))->setSize(GuiElement::GuiSizeMax, GuiElement::GuiSizeMax);

    setupParameters();
}

void GuiScanningDialog::onDraw(sp::RenderTarget& target)
{
    updateSignal();

    // Show scanning dialog only if a scan is possible and in progress
    // (delay > 0).
    auto ss = my_spaceship.getComponent<ScienceScanner>();
    auto [complexity, depth] = getScanComplexityDepth();
    bool scan_active = ss && complexity > 0 && depth > 0 && ss->delay > 0.0f;

    if (scan_active)
    {
        if (!box->isVisible())
        {
            box->show();
            scan_depth = 0;
            setupParameters();
        }

        if (locked && engine->getElapsedTime() - lock_start_time > lock_delay)
        {
            scan_depth += 1;
            if (scan_depth >= depth)
            {
                my_player_info->commandScanDone();
                lock_start_time = engine->getElapsedTime() - 1.0f;
            }
            else setupParameters();
        }

        locked_label->setVisible(locked && engine->getElapsedTime() - lock_start_time > lock_delay * 0.5f);
    }
    else box->hide();
}

void GuiScanningDialog::onUpdate()
{
    if (!my_spaceship || !isVisible()) return;

    // Update the state of each slider
    for (int n = 0; n < MAX_SLIDERS; n++)
    {
        // Handle scan input key/button bindings.
        float adjust = ((keys.science_scan_param_increase[n].isDiscreteStepDown() || keys.science_scan_param_increase[n].isRepeatReady()) - (keys.science_scan_param_decrease[n].isDiscreteStepDown() || keys.science_scan_param_decrease[n].isRepeatReady())) * 0.01f;
        adjust += (keys.science_scan_param_increase[n].getContinuousValue() + keys.science_scan_param_increase[n].getAxis0Value() + keys.science_scan_param_increase[n].getAxis1Value() - keys.science_scan_param_decrease[n].getContinuousValue() - keys.science_scan_param_decrease[n].getAxis0Value() - keys.science_scan_param_decrease[n].getAxis1Value()) * 0.005f;

        // If the input results in an adjustment, apply it to the sliders accordingly.
        if (adjust != 0.0f)
        {
            sliders[n]->setValue(sliders[n]->getValue() + adjust);
            updateSignal();
        }

        // Handle scan input axis bindings.
        const float axis1_value = keys.science_scan_param_set[n].getAxis1Value();
        if (axis1_value != 0.0f || set_active[n])
        {
            float set_value = (axis1_value + 1.0f) / 2.0f;

            if (set_value != sliders[n]->getValue())
            {
                sliders[n]->setValue(set_value);
                updateSignal();
            }

            // Make sure the next update is send, even if it is back to zero.
            set_active[n] = axis1_value != 0.0f;
        }
    }

    // Handle abort scan input binding.
    if (keys.science_scan_abort.isDiscreteStepDown())
        my_player_info->commandScanCancel();
}

void GuiScanningDialog::setupParameters()
{
    auto [complexity, depth] = getScanComplexityDepth();

    // Reset lock state when setting up new scan parameters
    locked = false;
    lock_start_time = 0.0f;

    for (int n = 0; n < MAX_SLIDERS; n++)
        sliders[n]->setVisible(n < complexity);

    box->setSize(500.0f, 265.0f + 70.0f * static_cast<float>(complexity));

    // Define the initial sensor target and slider values, ensuring that the
    // sliders start a random but significant distance form the target.
    for (int n = 0; n < MAX_SLIDERS; n++)
    {
        target[n] = random(0.0f, 1.0f);
        float slider_value = random(0.0f, 1.0f);
        while (fabsf(target[n] - slider_value) < 0.2f)
            slider_value = random(0.0f, 1.0f);
        sliders[n]->setValue(slider_value);
    }

    updateSignal();

    // Set a random scan text string.
    // TODO: Define in Lua instead.
    string label = "[" + string(scan_depth + 1) + "/" + string(depth) + "] ";
    switch(irandom(0, 10))
    {
    default:
    case  0: label += tr("scanning", "Electric signature"); break;
    case  1: label += tr("scanning", "Biomass frequency"); break;
    case  2: label += tr("scanning", "Gravity well signature"); break;
    case  3: label += tr("scanning", "Radiation halftime"); break;
    case  4: label += tr("scanning", "Radio profile"); break;
    case  5: label += tr("scanning", "Ionic phase shift"); break;
    case  6: label += tr("scanning", "Infra-red color shift"); break;
    case  7: label += tr("scanning", "Doppler stability"); break;
    case  8: label += tr("scanning", "Raspberry jam prevention"); break;
    case  9: label += tr("scanning", "Infinity impropability"); break;
    case 10: label += tr("scanning", "Zerospace audio frequency"); break;
    }
    signal_label->setText(label);
}

void GuiScanningDialog::updateSignal()
{
    // Reinitialize waveform properties.
    float noise = 0.0f;
    float period = 0.0f;
    float phase = 0.0f;
    int visible_slider_count = 0;

    // Update waveform properties based on each slider's value.
    for (int n = 0; n < MAX_SLIDERS; n++)
    {
        if (sliders[n]->isVisible())
        {
            const float f = fabsf(target[n] - sliders[n]->getValue());
            noise += f;
            period += f;
            phase += f;
            visible_slider_count++;
        }
    }

    // Lock scan when all 3 waveform properties are default < 5% from target.
    // Check for a lock only if there are visible sliders (a scan is active).
    if (visible_slider_count > 0
        && noise < lock_range
        && period < lock_range
        && phase < lock_range)
    {
        const float elapsed_time = engine->getElapsedTime();

        // Initiate the lock if we haven't yet.
        if (!locked)
        {
            lock_start_time = elapsed_time;
            locked = true;
        }

        // Gradually collapse the waveform into alignment over the lock delay.
        const float time_since_lock_start = elapsed_time - lock_start_time;

        if (time_since_lock_start > lock_delay * 0.5f)
            noise = period = phase = 0.0f;
        else
        {
            const float f = 1.0f - time_since_lock_start / (lock_delay * 0.5f);
            noise *= f;
            period *= f;
            phase *= f;
        }
    }
    else locked = false;

    signal_quality->setNoiseError(noise);
    signal_quality->setPeriodError(period);
    signal_quality->setPhaseError(phase);
}

void GuiScanningDialog::setLockDelay(float delay)
{
    lock_delay = std::max(0.0f, delay);
}

float GuiScanningDialog::getLockDelay()
{
    return lock_delay;
}

void GuiScanningDialog::setLockRange(float range)
{
    lock_range = std::max(0.0f, range);
}

float GuiScanningDialog::getLockRange()
{
    return lock_range;
}

std::pair<int, int> GuiScanningDialog::getScanComplexityDepth()
{
    // Return zeroes if we lack a scanner or the target lacks a scan state.
    auto ss = my_spaceship.getComponent<ScienceScanner>();
    if (!ss) return {0, 0};
    if (!ss->scan_target) return {0, 0};

    auto scanstate = ss->scan_target.getComponent<ScanState>();
    if (!scanstate) return {0, 0};

    auto complexity = scanstate->complexity;
    auto depth = scanstate->depth;

    if (complexity < 0)
    {
        switch (gameGlobalInfo->scanning_complexity)
        {
        case SC_None:
            complexity = 0;
            break;
        case SC_Simple:
            complexity = 1;
            break;
        case SC_Normal:
            if (scanstate->getStateFor(my_spaceship) == ScanState::State::SimpleScan)
                complexity = 2;
            else
                complexity = 1;
            break;
        case SC_Advanced:
            if (scanstate->getStateFor(my_spaceship) == ScanState::State::SimpleScan)
                complexity = 3;
            else
                complexity = 2;
            break;
        }
    }

    if (depth < 0)
    {
        switch (gameGlobalInfo->scanning_complexity)
        {
        case SC_None:
        case SC_Simple:
            depth = 1;
            break;
        case SC_Normal:
        case SC_Advanced:
            depth = 2;
            break;
        }
    }

    return {complexity, depth};
}
