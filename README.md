## Unofficial fork of EmptyEpsilon

### About EmptyEpsilon

Started by daid as a cross-platform, open-source "clone" of [Artemis Spaceship Bridge Simulator](https://www.artemisspaceshipbridge.com/), **EmptyEpsilon** (EE) deviated from Artemis with new features and gameplay, including a Game Master mode and multiple AI factions.

EmptyEpsilon is designed as a casual game for small LAN and WAN groups on extremely low-end hardware. It fully supports Windows and Linux across architectures, and can also be built on Android and macOS. The game and [SeriousProton](https://github.com/daid/SeriousProton) engine (SP) are written in C++ with [SDL3](https://www.libsdl.org/). Scenarios and some game logic are implemented in a limited Lua engine.

### About this fork

After the 2024.12.08 release, Daid moved development of EE to an entity-component-system (ECS) architecture. This fork builds on this upstream version, which as of 15 June 2026 hasn't yet had a full release.

Thanks to EmptyEpsilon's open nature, hardware integrations, scriptable APIs, and themeability, it's been adapted for use in large multi-day LARPs, immersive theatre productions, ongoing persistent campaigns, and interactive set decorations.

However, each such group has needed to implement features to facilitate this usage on their own without upstream support. Compared to upstream, this fork implements new features primarily to better facilitate these uses.

- Implements more significant changes to its user interface, including new and redesigned crew screens, and better support for higher-resolution displays.
- Focuses on implementing new features that leverage EE's ECS architecture.
- Adds and expands gameplay options that better support uses beyond casual small-group LAN/WAN play.
- Adds or updates hardware integration compatibility with theatrical sound/lighting devices and protocols.
- Reduces backward compatiblity with EE 2024.12.08 from a hardline to best-effort; scenarios written for EE 2024.12.08 are not guaranteed to work on this fork.
- Has a weaker emphasis on localization during the process of updating the primary English interface.
- Migrates from SDL2 to SDL3.
- Improves build support for macOS, Android, and Linux and Windows on architectures beyond `x86_64`.

## Download and install

TC

### Configuration files

EmptyEpsilon settings are stored in an `options.ini` file located in either the `.emptyepsilon` directory of your user home or the same directory as the EmptyEpsilon launcher. For details, see [this repository's wiki](https://github.com/oznogon/EmptyEpsilon/wiki/Preferences-file).

### Build from source

See this repository's wiki for guidance on [building EmptyEpsilon from source](https://github.com/oznogon/EmptyEpsilon/wiki/Build). Several Build subpages on the wiki provide steps for building on specific operating systems, distributions, or hardware.

## Community and contribution

This fork is a solo project.

For information on upstream EmptyEpsilon's Discord and forums communities, and regularly planned hosted game sessions, see the upstream [EmptyEpsilon website](https://daid.github.io/EmptyEpsilon/#tabs=6). This fork is _not_ compatible with hosted games running upstream EmptyEpsilon.

### Translate and localize

Due to the breadth and frequency of user-interface changes in this fork, I'm not accepting requests to translate or localize it at this time. Upstream localization content remains in this fork, but there's no guarantee that it will be maintained.
