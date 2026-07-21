#!/usr/bin/env python3
"""Convert US English to UK English in msgstr fields of en_GB.po files.

For each entry, if msgstr is empty, fill it from msgid (converted to UK English).
If msgstr is non-empty, convert its content to UK English.
Only modifies msgstr fields; preserves msgctxt, msgid, comments, and structure.
"""

import glob
import re
import sys

UK_MAP = {
    'color': 'colour',
    'colors': 'colours',
    'colored': 'coloured',
    'coloring': 'colouring',
    'colorful': 'colourful',
    'colorless': 'colourless',
    'favor': 'favour',
    'favors': 'favours',
    'favored': 'favoured',
    'favoring': 'favouring',
    'favorite': 'favourite',
    'favorites': 'favourites',
    'favorable': 'favourable',
    'favorably': 'favourably',
    'vapor': 'vapour',
    'vapors': 'vapours',
    'center': 'centre',
    'centers': 'centres',
    'centered': 'centred',
    'centering': 'centring',
    'centerpiece': 'centrepiece',
    'maneuver': 'manoeuvre',
    'maneuvers': 'manoeuvres',
    'maneuvered': 'manoeuvred',
    'maneuvering': 'manoeuvring',
    'dialog': 'dialogue',
    'dialogs': 'dialogues',
    'customize': 'customise',
    'customizes': 'customises',
    'customized': 'customised',
    'customizing': 'customising',
    'customization': 'customisation',
    'customizations': 'customisations',
    'maximize': 'maximise',
    'maximizes': 'maximises',
    'maximized': 'maximised',
    'maximizing': 'maximising',
    'maximization': 'maximisation',
    'minimize': 'minimise',
    'minimizes': 'minimises',
    'minimized': 'minimised',
    'minimizing': 'minimising',
    'minimization': 'minimisation',
    'prioritize': 'prioritise',
    'prioritizes': 'prioritises',
    'prioritized': 'prioritised',
    'prioritizing': 'prioritising',
    'prioritization': 'prioritisation',
    'randomize': 'randomise',
    'randomizes': 'randomises',
    'randomized': 'randomised',
    'randomizing': 'randomising',
    'randomization': 'randomisation',
    'summarize': 'summarise',
    'summarizes': 'summarises',
    'summarized': 'summarised',
    'summarizing': 'summarising',
    'summarization': 'summarisation',
    'defense': 'defence',
    'defenses': 'defences',
    'offense': 'offence',
    'offenses': 'offences',
    'honor': 'honour',
    'honors': 'honours',
    'honored': 'honoured',
    'honoring': 'honouring',
    'honorable': 'honourable',
    'honorably': 'honourably',
    'armor': 'armour',
    'armors': 'armours',
    'armored': 'armoured',
    'behavior': 'behaviour',
    'behaviors': 'behaviours',
    'behavioral': 'behavioural',
    'neighbor': 'neighbour',
    'neighbors': 'neighbours',
    'neighborhood': 'neighbourhood',
    'neighbourhood': 'neighbourhood',
    'rumor': 'rumour',
    'rumors': 'rumours',
    'labor': 'labour',
    'labors': 'labours',
    'labored': 'laboured',
    'laboring': 'labouring',
    'flavor': 'flavour',
    'flavors': 'flavours',
    'flavorful': 'flavourful',
    'tire': 'tyre',
    'tires': 'tyres',
    'tired': 'tyred',
    'gray': 'grey',
    'grays': 'greys',
    'grayed': 'greyed',
    'graying': 'greying',
    'plow': 'plough',
    'plows': 'ploughs',
    'plowed': 'ploughed',
    'plowing': 'ploughing',
    'theater': 'theatre',
    'theaters': 'theatres',
    'fiber': 'fibre',
    'fibers': 'fibres',
    'liter': 'litre',
    'liters': 'litres',
    'caliber': 'calibre',
    'traveler': 'traveller',
    'travelers': 'travellers',
    'traveled': 'travelled',
    'traveling': 'travelling',
    'canceled': 'cancelled',
    'canceling': 'cancelling',
    'modeled': 'modelled',
    'modeling': 'modelling',
    'fueled': 'fuelled',
    'fueling': 'fuelling',
    'labeled': 'labelled',
    'labeling': 'labelling',
    'enrollment': 'enrolment',
    'enrollments': 'enrolments',
    'fulfill': 'fulfil',
    'fulfillment': 'fulfilment',
    'skillful': 'skilful',
    'catalog': 'catalogue',
    'catalogs': 'catalogues',
    'cataloged': 'catalogued',
    'cataloging': 'cataloguing',
    'analog': 'analogue',
    'analogs': 'analogues',
    'recognize': 'recognise',
    'recognizes': 'recognises',
    'recognized': 'recognised',
    'recognizing': 'recognising',
    'recognition': 'recognition',
    'utilize': 'utilise',
    'utilizes': 'utilises',
    'utilized': 'utilised',
    'utilizing': 'utilising',
    'utilization': 'utilisation',
    'apologize': 'apologise',
    'apologizes': 'apologises',
    'apologized': 'apologised',
    'apologizing': 'apologising',
    'organize': 'organise',
    'organizes': 'organises',
    'organized': 'organised',
    'organizing': 'organising',
    'organization': 'organisation',
    'organizations': 'organisations',
    'authorize': 'authorise',
    'authorizes': 'authorises',
    'authorized': 'authorised',
    'authorizing': 'authorising',
    'authorization': 'authorisation',
    'visualize': 'visualise',
    'visualizes': 'visualises',
    'visualized': 'visualised',
    'visualizing': 'visualising',
    'visualization': 'visualisation',
    'normalize': 'normalise',
    'normalizes': 'normalises',
    'normalized': 'normalised',
    'normalizing': 'normalising',
    'normalization': 'normalisation',
    'specialize': 'specialise',
    'specializes': 'specialises',
    'specialized': 'specialised',
    'specializing': 'specialising',
    'specialization': 'specialisation',
    'initialize': 'initialise',
    'initializes': 'initialises',
    'initialized': 'initialised',
    'initializing': 'initialising',
    'initialization': 'initialisation',
    'generalize': 'generalise',
    'generalizes': 'generalises',
    'generalized': 'generalised',
    'generalizing': 'generalising',
    'generalization': 'generalisation',
    'optimize': 'optimise',
    'optimizes': 'optimises',
    'optimized': 'optimised',
    'optimizing': 'optimising',
    'optimization': 'optimisation',
}

_lower_map = {k.lower(): v.lower() for k, v in UK_MAP.items()}


def us_to_uk(text):
    """Convert US English to UK English, preserving case pattern of each word."""
    def replace_word(match):
        word = match.group(0)
        lower = word.lower()
        if lower in _lower_map:
            uk = _lower_map[lower]
            if word.isupper() and len(word) > 1:
                return uk.upper()
            if word[0:1].isupper():
                return uk[0].upper() + uk[1:]
            return uk
        return word

    return re.sub(r'\b[A-Za-z][A-Za-z\']*\b', replace_word, text)


def extract_quoted(s):
    first = s.index('"')
    last = s.rindex('"')
    return s[first + 1:last]


def process_po_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    current_msgid = ''
    skip_until = 0
    changed_count = 0

    for i, line in enumerate(lines):
        if i < skip_until:
            continue

        stripped = line.strip()

        if re.match(r'^msgid\s+"', stripped):
            current_msgid = extract_quoted(stripped)
            j = i + 1
            while j < len(lines) and lines[j].strip().startswith('"'):
                current_msgid += extract_quoted(lines[j].strip())
                j += 1

        m = re.match(r'^(\s*msgstr(\[\d+\])?\s+)', stripped)
        if m:
            content = ''
            j = i
            first = True
            while j < len(lines):
                s = lines[j].strip()
                if first:
                    if '"' in s:
                        content = extract_quoted(s)
                    first = False
                    j += 1
                elif s.startswith('"'):
                    content += extract_quoted(s)
                    j += 1
                else:
                    break

            if content:
                new_content = us_to_uk(content)
            elif current_msgid:
                new_content = us_to_uk(current_msgid)
            else:
                new_content = ''

            first_quote = line.index('"')
            new_lines.append(line[:first_quote] + '"' + new_content + '"\n')
            skip_until = j

            if content != new_content:
                changed_count += 1

            continue

        new_lines.append(line)

    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

    return changed_count


def main():
    patterns = ["resources/locale/*.en_GB.po", "scripts/locale/**/*.en_GB.po"]
    files = []
    for pat in patterns:
        files.extend(glob.glob(pat, recursive=True))

    if not files:
        print("No en_GB.po files found.")
        return

    total_changed = 0
    for fp in sorted(files):
        changed = process_po_file(fp)
        if changed:
            print(f"{fp}: {changed} entries updated")
        total_changed += changed

    print(f"\nDone. {total_changed} entries updated across {len(files)} files.")


if __name__ == "__main__":
    main()
