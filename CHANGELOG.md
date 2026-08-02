# Changelog

## [2026-08]

### Changed

- Raise weapon mount arrays to a first-class component (`Mounts`) and incorporate features across beam weapons, missile weapons, and utility beamss
  - Missile weapon tubes can now be turreted. Turreted tubes' indicators and firing arcs update to reflect turret direction
  - Utility Beam directional control is now managed as a turret within a defined arc
  - Mounts GM Tweak page manages all weapon mounts across weapon types

### Fixed

- Utility Beam rotation dial background outline no longer renders over the handle and other UI elements

## [2026-07]

### New features

- Missile weapon data moved from hardcoded C++ enums to Lua-driven ECS components
  - `EMissileWeapons` enum replaced with dynamic `MissileWeaponData` ECS component loaded from `scripts/missileWeaponData.lua`
  - `MissileWeaponDataRegistry` singleton maps missile type names to integer indices for efficient storage arrays
  - Missile type data (speed, turnrate, damage, blast, behavior flags) now defined in Lua and replicated over the network
  - New `MissileWeaponData()` and `getMissileWeaponData()` Lua API following the FactionInfo pattern
  - `MissileTubes` storage arrays expanded to support up to 16 dynamic missile types (was 5 hardcoded)
  - Scenario scripts can create, modify, and remove missile weapon types mid-game
  - Existing Lua APIs (`getWeaponStorage`, `setWeaponStorage`, `commandLoadTube`, etc.) maintain backward compatibility
  - Missile spawn behavior data-driven: explosion type, damage, SFX, homing, and special flags all configurable per type
  - GM Tweak screen missile weapon editor supports dynamic types
  - New `findMissileWeaponData()` C++ binding exposed to Lua
  - Missile weapon data lifecycle callbacks added (`on_spawn`, `on_collision`, `on_lifetime_expire`, `on_explode`) triggered at missile projectile events
  - GM Tweak screen MissileWeaponData editor added with full property browser and "Missile weapons" side panel
- Touchscreen pinch-to-zoom gestures on RadarViews
  - Pinch with two fingers to zoom, centered on the pinch point like mousewheel zoom
  - Single-finger touch continues to support tap-to-select and drag-to-pan
  - GuiCanvas updated to correctly forward multi-touch DOWN and UP events
  - Map recentering suppressed after pinch gesture release
- Map pages for BriefingMap screen, with new briefing map script functions
  - Map mimics Relay/Strategic Map, using script-defined pseudoentities
  - Supports keyframe animation
- 4K texture atlas detection and support
  - Default behavior uses largest available of 2K (old default) and 4K
  - If 4K, double font rendering texture size
- Hull component added to missiles and asteroids, making them targetable and destroyable
- Fractional (<1x) time scales on GM screen (upstream 2887)
- Multiline text entry now allowed in certain GuiTextEntry fields, primarily LuaConsole (shift+enter for linebreak; linebreaks also copy/paste correctly)
- AI/pathfinding logic moved to background thread, reducing main thread blocking
- Expanded music library with Rafael Krux CC-BY tracks
- Read and display artist-title OGG tags in Options menu music preview
- StyLua configuration TOML to enforce consistent Lua code formatting
- `getEffectiveScrollbarWidth()` exposed from GuiScrollContainer
  - Pause, scale, and stacking controls on the debug timing graph
  - Tooltips on hover added to timing graph to view timings at a specific point in time
  - Timing graph forces GL lines for better performance
- Long-range missile visibility toggle button in server options
- Philips Hue V2 smart lighting support
  - Hue controls split into V1 and new V2 implementations
  - V2 requires SSL, and support for it is built only when `WITH_SSL=ON`, which adds dependencies on OpenSSL and crypto libraries.
  - V2 bridge IP discovery via discovery.meethub
  - Hue/sat color space conversion to V2 XY coordinates
  - API key request flow with retries and prompts to push the bridge's link button (console/STDOUT only)
- Vertex displacement noise shader with mapped color intensities added and adapted for use as new explosion effect, replacing plain sphere
- Multimonitor mode toggle in OptionsMenu, with tooltip and restart label
- Lua API additions
  - `reactor.energyPercentage()`, `hull.percentage()`, `shields.percentage()` return integer strings to avoid redundant calculation
  - `getWallTime()` returns wall clock time (elapsed time including pauses) since scenario start
  - Target getter functions for split weapon, comms, scan, and hacking targets
  - Functions to change an InternalRoom's ShipSystem in ShipTemplates and STBOs
- Scan/abort toggle keybind on Science screen
- Interface Options toggle to show/hide the Lua console error popup
- Logging level and output can now be overridden in non-debug builds
- English (en) locale split into en_GB (UK English) and en_US (US English)
  - en_US is the new default
  - Locale update tooling copies missing en_GB PO files from en_US and naively applies basic US-to-UK spelling transformations
- Alphabetical sort option added to GuiEntryList
- GM Tweak component filter toggle, to list only tweak pages for components that the selected entity already possesses

### Changed

- Migrate SDL from SDL2 to SDL3
  - Builds now require SDL3 to be installed or built from source, see https://github.com/oznogon/EmptyEpsilon/wiki/Build
  - See commit 7d86049 "Migrate from SDL2 to SDL3" for implementation details
- Reorganize and refactor ship template classes
  - Add, rename, and reorganize ship template class files and `setClass()` definitions
  - Corvettes are no longer described as "larger" than frigates
  - Exuari and Ktlitan templates split into subdirectories
  - Non-combat ships split into Auxiliaries file
  - Edit some ship descriptions to facilitate i18n reuse
- Codebase-wide formatting edits
  - All Lua scripts reformatted using StyLua
  - Tab (indents and most inline tabs) converted to spaces in C++ and Lua
  - All line endings normalized (dos2unix)
- Refactor Engineering screen
  - Apply layout attributes
  - Engineering+ screen logic consolidated into Engineering screen
  - ShipSystem list made scrollable; rows now render from top
- Refactor DebugRenderer to use GuiResizableDialog, GuiKeyValueDisplays, GuiButtons, etc. instead of bespoke drawText
- Enforce both `max_size` and `min_size` on GuiResizableDialog
- Rewrite AI system
  - AI/pathfinding split into light (every server update) and heavy (batched) logic to prevent AI updates from blocking main thread
  - Pathfinding rewritten with split A* and spatial hash grid for improved accuracy, reduced update jitter, and better performance
  - Formation collision over-avoidance mitigated
- Nebulae performance tweaks
  - Nebula occlusion queries cached and dynamic lights pre-computed
  - Nebulae default to seed-only cloud randomization, reducing replication load
  - Add OptionsMenu toggles for nebula fog, dynamic lighting
- Refactor OptionsMenu
  - Use a single-column GuiScrollContainer instead of multiple columns
  - Use consistent header styling and selector tabs
  - Split i18n keys
  - Consistently apply layout padding and formatting
- Refactor GuiTextEntry for multiline input and autoscroll support
- LuaConsole refactored
  - LuaConsole now uses GuiScrollContainer for output
  - LuaConsole output selection and copying restored
  - LuaConsole output lines now wrap to fit
  - LuaConsole now supports multiline text on GuiTextEntry
- Science screen hides empty tabs and sidebar key/value fields without values
- Theme files support `display_name` display metadata for OptionsMenu theme selector
- Language selector disabled in OptionsMenu when serving a scenario, to prevent scenario/UI language drift
- `metricsserver` preference renamed to `metrics_server` for consistency
- Scenarios reorganized
  - Training: Cruiser scenario renumbered per convention
  - Replayable Mission scenario category renamed to "Replayable"
- Scenario fixes
  - `getSectorName()` used instead of hardcoded sector names in scenarios and scripts
- PanelBackground transparent padding removed from default theme's sprite
- Beam weapons can now target non-friendly entities, not only hostiles
- Headless mode no longer loads visual resources (images, 3D meshes, textures).
- Sector subdivision changed from 8x8 subsectors to 10x10
- AI behaviors refactored
  - Ships attempt to avoid colliding with each other
  - AI docking handler handles both Docking and Docked states, preventing instant/repeated undocks
  - Direct AI order changes now take immediate effect
  - FighterAI Evade state now persists across frames
- ShipTemplate and faction selectors sorted alphabetically on ShipSelection and GM screens
- `self_destruct_countdown` preference restored; configuration loading buffer size increased
- FSAA menu options hidden when unsupported by the GPU
- Keybinds suppressed when the owning screen component is hidden
- GuiScrollContainer starting scroll position configurable (ScrollStart::Bottom) for chat-like output
- Multiuse Lua API functions consolidated
- Metrics server restricted to server processes only
- Scenarios renamed and renumbered per convention; station and ship names updated across scenarios (Cadet, Race)
- DebugRenderer timing graph hidden by default in Release builds
- Health bars hidden for entities with 1 max hull
- Previous ship template names noted in descriptions; redundant strings split for internationalization reuse

### Fixed

- GuiScrollContainer no longer exhibits first-frame layout flicker
- Utility Beam controls now appear on default Science screen when UtilityBeam component is added to a player ship mid-game
- Tooltip no longer renders in unusual or persistent locations on button hold/release
- ThreatLevelEstimate more correctly influences music selection and looping
- Duplicate and incorrect translations in French internationalization text fixed
- Line rendering selector options no longer transposed
- Component description is now correct upon direct GM Tweak page open (i.e. Database editor)
- GuiScrollContainer layout with `verticalbottom` children no longer breaks GuiScrollContainer scrolling
- GuiContainer::cleanTree() no longer leaves dangling scroll container pointers
- DebugRenderer click capture bounding issues removed by move to GuiResizableDialog
- `metrics_server` port validity now checked
- GuiSlider release delay prevents slider values from being overwritten on clients mid-drag
- Science/scan target cycling now correctly skips radar-blocked entities
- Relay targeting fixes
  - Hotkey targeting now correctly limited to hackable, comms-capable, and probe entities
  - Hacking now prevented on entities without either ShipSystems or a defined HackingDifficulty
- Scanning refactored to prevent exploiting low-complexity scan targets to advance scanstate on high-complexity scan targets
- Multiple repair crews now prevented from spawning in or moving into the same internal room cell
- Radar signature values are now normalized
- DockingBayScreen regressions fixed
  - Supply drop visibility on berth selection
  - Slider release behavior
- LuaConsole regressions fixed
  - Popup autoscroll
  - Click catching on hidden console
- GM Tweaks now open the correct description upon direct tweak page opening
- Undefined behavior in `FLT_MAX` cast to int fixed in GuiScrollContainer
- Segfault when adding too many custom buttons fixed
- Metrics server no longer runs on clients
- Scenario fixes
  - Basic
    - Status banner now shown even when time set to Unlimited
    - Asteroids should overlap less frequently upon intiial scenario spawn
  - Push the Payload
    - Artifact pickup fixed for ECS in Push the Payload scenario
    - Player detection and crash on PlayerShip destruction in Push the Payload
    - Remove unmanaged Coolant component from CpuShip spawns using PlayerShip templates in Push the Payload to prevent ship systems from overheating
  - Kessler: End-of-line semicolons removed to prevent script breakage
  - Birth of the Atlantis: Destroy nebula before exploding artifact to avoid nil error
  - Early Evaluation Exercise: Fix failure when player ship respawns after home station destroyed
  - Surf's Up: Check for name_pool existence before removing names
- Crew positions are now cleared only when a different scenario is loaded
- Default sidebar selector value set on crew screens with a sidebar
- Duplicate Heracles ship templates removed
- Sensors ShipSystem added to Lua enum
- Missile `radar_signature` member names fixed
- HTML template language codes fixed
- Striker ShipTemplate references fixed in docking bay test
- GM screen waypoint control position no longer overlaps with AI orders
- Science screen no longer warns on invalid pager state when tabs intentionally absent
- ShipSelectionScreen description now correctly linked to ShipTemplate GuiSelector value regardless of the selector's sort order
- Compilation fixes
  - Update Discord header ifdefs for Windows builds
  - SelfDestruct header include fixed
  - Compiler warnings fixed (narrowing conversions, unused captures, float-to-double, MSVC `_unlink`)

## [2026-06]

### New features

- Nebula rendering overhaul: volumetric fog, dynamic lighting, particle dithering, entity occlusion, configurable draw distance
  - Default behavior is a significant gameplay change; nebulae are no longer see-through, eyeballs are no longer more powerful than radar, instruments required to fight/navigate through nebulae
- Collision damage, factor tunable via ShipSelection setting; defaults to 0/off
- Beam weapon autofire/safety toggle, allows disabling firing of beam weapons at valid targets
- Scanner ShipSystem affects radar range, scanning speed, drone sensor range, and shared radar ranges
- DockingBayScreen supply drop creation and stocking system with berth management
- Limited remote GM prototype (entity movement, editing of remote-exposed properties)
- Font line_height supported in themes
- GuiElement constants for consistent row, label, and padding/margin sizes
- Client latency simulation controls for servers in DebugRenderer, adds flat 250ms delay randomized 0-250ms delay on outgoing packets
- Science screen missile/beam lock indicators, visible when an entity's homing missile or in-range beam weapon is actively targeting the player
- Server setting to show missiles on long-range radar (off by default, preserving original gameplay)
- Scenario selection button shows "Configure" instead of "Start" for scenarios with config steps
- Crew position requirement checks consolidated into `CrewPositionRequirements` class
- ShipSelectionScreen describes most recently clicked crew screen
- Server/UDP port change available from server creation screen
- Script descriptions expanded and formatted on TutorialMenu
- Refactor alert overlay
  - Background image now stretches as a 9-segment texture
  - Transparency pulses
  - Alert overlay now rendered on all screens, including Relay/Strategic Map
- Menu screen titles added and refactored
- Scenario categories made available to translation

### Changed

- Rewrite pathfinding system rewritten
  - A* grid search with line-of-sight smoothing replaces recursive binary-detour planner, improving route quality around clustered obstacles
  - Obstacle registration uses flat spatial list instead of big/small entity classification
  - AvoidObject internal state enum and position_hash removed
- Shield hit effect now uses ship mesh instead of generic sphere, with new texture
- Update themes
  - GuiToggleButton on-state style now applied
  - GuiEntityInfoPanel theme styles now applied
- Deprecate `altRelay` role name in favor of `strategicMap`; alias retained for compatibility
- Refactor Weapons screens' (Tactical, Weapons, BeamWeapons, MissileWeapons) layouts
- Refactor `CrewStationScreen`
  - Renamed "crew station" to "crew screen" throughout, including `CrewStationScreen` to `CrewScreen`, to avoid ambiguity with space stations
  - Crew screen selector placed in `GuiScrollContainer`, for rare cases where more are selected than will fit on the screen
- `TutorialMenu` refactored into two-column layout using layout properties
- ShipSelectionScreen and playerInfo code reformatted
- Alert overlay converted to `DrawStretchedHV`, full-screen color multiply removed
- Update i18n implementation
  - Redundant/legacy C++-defined translation keys migrated to canonical Lua equivalents
  - Translation PO files swept of deleted C++-defined strings
  - French science_db and PO file corrections
- RED/YELLOW ALERT no longer uppercased
- Update scenarios
  - Station space setup in Surf's Up scenario replaced with util script
  - Xansta util and scenario scripts cleaned up
- GM Tweak button state now updates every frame

### Fixed

- Fighter AI strafing runs now fly directly at the target on initial approach (bypassing pathfinding avoidance) until the ship has fired or closed within beam range, ensuring beam weapons get on target before collision evasion kicks in
- Theme font offset now correctly applied
- Asteroid radar trace radius once again synced to physics radius
- GuiScrollContainer tree explicit cleanup
- GuiRenderedModelSprite correctly tracks GL_SCISSOR_TEST state
- Space station entries now populated as expected in ScienceDatabase
- Zone transform positions update correctly when moved on GM Tweak
- Prevent 0-size rooms in InternalCrewSystem
- CrewPosition MAX limit reduced to 30 to fit 32-bit mask
- HardwareController invalid effect setting handling
- Avoid GuiTheme getter null return for undefined themes/styles
- AdvancedScrollText bounds handling updated to prevent cutoffs of final line
- Relay's comms message row no longer takes up space on Strategic Map screen, where it's hidden
- Several keys no longer collide on French science_db translation
- Added missing numeric type check in science_db values
- Unix permissions fixed on scripts and resources
- Scenario names, descriptions, and settings now update when changing the interface language

## [2026-05]

### Added

- Target types system (analysis, beams, missiles, hacks, scannable, selectable)
- Per-type targeting in crew screens
- DroneOperations station with Sensors ShipSystem
- Icons across all crew screens
- Crew selection Alternative options expanded
- Internal docking as managed berths fully implemented
- PlayerControl `allowed_positions` settable via Lua
- Zone transform visualized on GM radar
- Larger color palette for debug renderer time series chart

### Changed

- GuiScrollContainer replaces GuiScrollText/GuiScrollFormattedText
- DatabaseViewComponent refactored with persistent scroll position
- Refactor sector naming
  - Sector naming conventions are now defined via Lua and can be changed by scenarios
  - Default sector naming now uses numeric 100x100 grids (`50-50`) instead of letter-number (`F4`). Internal coords 0,0 are now at top-left of sector 50-50.

### Fixed

- Missile types restored to science DB
- Autoconnect off-by-one (#2873)

## [2026-04]

### Added

- Strategic Map view to main screen (#2175)
- Rewritten cinematic camera
  - Redesigned fly-by and top-down modes
  - New modes: Orbital, chase, isometric,
  - New modifiers: Auto-zoom, auto-cycling camera modes
  - Target-of-target tracking revised and made available to all modes
  - Separate Top-down View screen removed as redundant
- Internal docking redesigned as managed berths
  - Docking Bay crew screen manages storage, berth assignment, launching, repair, resupply of internally docked ships
  - Berths can be defined via script or use a default group
- Extra crew screens
  - Drone Operations, control ships with drone control component
  - Missile Weapons and Beam Weapons screens split from Weapons
  - Target Analysis, shows Science details and model of linked entity
  - Probe Camera, 3D viewport of linked probe with rotational controls
- Modulated emissive texture shader support
- GM Screen features
  - Waypoint management on GM screen (routes, sets)
  - GM screenScreen time scale selector (1x, 2x, 4x, 8x)
- HackingTarget component, to track when a screen has selected a hackable target
- Scriptable hacking difficulty allows per-entity deviation from server setting
- DB link button for faction key/values on Science scan target
- Science, Relay, Operations keybinds

### Changed

- Engine controls moved on Single screen (room for docking/overheat indicator)
- Power Management screen rewritten
- GM screen chat/script comms overlay refactored
- "Request dock" button converted to a menu
- Trixie PXE netboot script updated
- GuiScrollContainer integrated across multiple screens (OptionsMenu, GuiSelector, CustomShipFunctions, DockingBayScreen, etc.)

### Fixed

- Control visibility on component removal
- MissileSystem mines hidden on LongRange radar
- Comms overlay, utility beam, docking, scanning, weapon storage validation, crew screens when components missing, zone labeling, scrollbar scrolling, strict compilation

## [2026-03]

### Added

- InternalCrew Lua helper functions
- Beam effects rendered on radar with fire color
- Callsigns assigned to player-launched ScanProbes
- Hacking minigame help
- Theme inheritance
- GM and Spectator zoom out to 10kU
- GM screen modal mouse cursors reimplemented
- MouseRenderer customization
- Dynamic FoV changes in Viewport
- i18n plural handling exposed to Lua
- `Entity:onDestroyed` using new SP callback
- Beam frequency randomization by default
- F12 colliders toggle in Debug builds
- DMX serial Break delay configurable
- EmptyEpsilon logo as window icon
- GuiScrollContainer for arbitrary/nested scrolling
- GM tweaks: Transform, Physics, Zone, DockingBay, Faction, AIController, Orbit, AvoidObject, Target, InternalRooms, MoveTo, Database, LifeTime, WarpJammer, Spin component editing and search

### Changed

- GuiRotationDial and AimLock rendering refactored
- Beam frequency validation
- Theme coverage expanded across GUI elements
- Lua docstrings reviewed and edited

### Fixed

- AvoidObject range edge cases (#2776)
- MSVC strict compilation (tweak.cpp with /bigobj)

## [2026-02]

### Added

- StdinLuaConsole history and commands
- Minesweeper flagging and remaining attempts tracker
- Lua API exposure: `MissileFlight`, `MissileHoming`, `ExplodeOnTimeout`, `JumpDrive.just_jumped`
- Explosions rendered on radar
- Voice chat disable via `voice_chat_enabled=0` pref
- Entity rotation on GM screen creation (drag after click)
- Scriptable utility beam ship system
- Abort jump keybinding

### Changed

- macOS CI/CD re-enabled with hdiutil workarounds
- Beam arc handling improved
- DatabaseViewComponent refactored
- Tutorials made repeatable
- Lua console improvements

### Fixed

- BillboardRenderer replication

## [2026-01]

### Added

- GM chat dialog can switch to scripted comms
- Relay/Ops states visually indicated

### Changed

- GuiOpenCommsButton states disambiguated
- Translation updates (German)

### Fixed

- Waypoints vector flagged as dirty after removal
- Scan autosolve prevention with multiple GuiScanDialogs
- Text entry cursor position in themed/long-content fields
- Functions marked dirty after message dismissal

## [2025-12]

### Added

- Hotkey menu Reset button
- CrewPositionSelection shows when main screen is split
- Pause keybind toggles out of pause
- Missing GuiThemeStyle hooks
- Lua functions: `isGamePaused()`, `isInsideZone()`, `setLocalSkybox()`, `getEntitiesWithComponent()`
- Sfx component for missile launches

### Changed

- GuiScrollingBanner refactored
- Interface page of Options Menu refactored
- `Convert<CrewPosition>` moved to `script/crewPosition.h`

### Fixed

- `ShipSystemsSystem` no longer updates on clients
- Wormhole exits hidden on client Spectator screens
- Broadside AI
- DMX event non-float numbers
- Scan probe stocking restored to space stations
- GM control codes enforced on privileged views
- ScienceDatabase `removeKey()` logic

## [2025-11]

### Added

- Lua thread support
- Sfx component and implementation
- Asteroid normal maps
- Viewport3D callsign toggle on top-down and cinematic views
- PowerDamageIndicator docking mode

### Changed

- Power and coolant request behaviors aligned
- LongRange radar component split; stable waypoint numbering
- AI ships default to flying to target instead of stopping 0.1U short
- GM screen click selects only closest entity
- Sector naming functions (`getSectorName()`) added to multiple scenarios
- Warp request/decharge behavior modified

### Fixed

- Hex values from Lua handled correctly
- Debug graph bounds checking
- Hotkey menu backtracking
- Crashes in AI and cinematic views

## [2025-10]

### Added

- GuiLabel text clipping support

### Changed

- Non-functional GameStateLogger removed
- Coolant sliders disabled when auto coolant enabled
- GuiMainScreenControls refactored
- GuiResizableDialog drag-to-reposition refactored
- Icons enhanced on buttons
- Scenario Broken Glass sector naming updated

### Fixed

- Translation markers and autoconnect label sizes

## [2025-09]

### Changed

- macOS CI/CD re-enabled with ARM64 support, then re-disabled
- Impulse keybinds ported to jump drive distance

## [2025-08]

### Changed

- Translation updates (German: main, science DB, ship names)

## [2025-07]

### Added

- Ship Selection main screen with options menu
- GM screen callsign toggle
- Spectator view callsign toggle and enhancements
- Relay radar centering toggleable
- Own faction relationship listed in database
- Explosion effect API
- Database visuals for technologies and natural
- GM mouse cursor customizable and modal
- Spawnable entity icons and traces associated

### Changed

- CrewPositionSelection panel enhanced
- PlayerShip list on ShipSelectionScreen better default selection
- Faction keys sorted alphabetically by locale name
- Info/custom buttons bar swapped
- Hotkey help categories use localized strings
- Translation updates (German)

## [2025-06]

### Added

- F1 keyboard reference to GM, cinematic, and top-down views
- Slider controls to GM tweaks
- Boolmask and enum support in tweak menu
- Jump controls can abort a jump in progress
- Missile weapon type stats to Science DB
- Partial clipboard support restored
- Debug renderers for collision shapes (radar, 3D)

### Changed

- GM screen creation window redesigned with descriptions, categories, filters
- Accurate jump timing in UI elements
- AI docking abort logic improved
- Android SDL version updated, 32-bit disabled
- Performance graphs improved
- Scenario updates: _Delta Quadrant Patrol Duty_, _Escape_, _Chaos of War_, _Deliver Ambassador Gremus_, _Locust Swarm_, _Doomed Outpost_, _Shoreline_, _Scurvy Scavenger_, _Fermi 500_, _Unwanted Visitors_, _What the Dickens_
- Translation updates (German, scenario-specific)

### Fixed

- Warp shader alpha handling
- Beam weapon range against large targets
- Undocking from internal docking
- Probe mesh rendering

## [2025-05]

### Added

- Warp/jump drive GM tweak sliders
- Autoconnect extended to N stations across M monitors
- Preferences for autoconnect server selection
- Beam weapons added to science database

### Changed

- Lua constants de-const'd and exposed
- Responsive layout for Science/Operations custom buttons
- Translation updates (French, German)

### Fixed

- Scanning synchronisation
- Shield synchronisation
- Missile supply drop not giving missiles
- `toJSON()` failing with nested tables
- Tutorial init function handling

## [2025-04]

### Added

- Default comms ship script
- Engineering hotkeys for previous/next system
- Cadet Patrol scenario
- Lua utilities for scenarios

### Changed

- Translation proofreading updates (French)

## [2025-03]

### Added

- New scenario: _Empty Space_
- Comms scenario utility

### Changed

- Tutorials start specific tutorial before autoconnect
- Log limit raised to 10,000 entries
- `getImpulseMaxSpeed()` returns both forward and reverse values

### Fixed

- Planets no longer block radar (legacy behavior restored)
- Lua error reporting for `onGMClick`
- French translations: _Early Evaluation Exercise_ (100%), _Borderline Fever_ (100%)
- Scenario payload and Cadet Patrol translations

## [2025-02]

### Added

- New scenario: _Push The Payload_
- Relay "center on ship" button

### Changed

- CPU ships now auto-repair
- Hardware.ini reimplemented with ECS

### Fixed

- Artifact pickups and collision callbacks
- Scenario updates: _Carrier_, _Borderline Fever_ translations

## [2025-01]

### Changed

- Lua script storage: keys deletable by setting to nil, complex data structures supported
- Mixed-size and mixed-color text rendering
- Scenario updates: _Allies and Enemies_, _Escape_, _Planet Devourer_, _Fermi 500_, _Shoreline_, _Close the Gaps_
- Translation updates (French)

## [2024-12-08]

### Added

- New scenarios
  - _Surf's Up!_ #2173
  - _Early Evaluation Exercise_ #2172
  - _Liberation Day_ #2163
- Scenario utilities
  - Comms scenario utility #2162
  - Player ship upgrade and downgrade #2171
- Features
  - MetaInfo file for Linux desktop metadata #2180
  - Desktop file and icon renamed for improved Linux integration #2179
  - Options can now be saved with custom config directory #2204
  - Enter key callback for server password dialog #2199
  - Failed-to-connect reason shown to client #c767a6150
  - Extracted translator comments from C++ and Lua sources #2245
- Translation markers added to many scenarios and scripts (#2243, #2249, #2236, #2225, #2223, #2219, #2174, #2176)

### Changed

- Server scanner updated to use new API; removed LAN/Internet selection toggle #289041c6e
- Radar signal signatures simplified into clearer bands #2227
- Carriers and Turrets scenario variations converted to translatable format #2165
- Lua console improvements: input line prefixing, command history #747c97f24
- Scenario "Birth of the Atlantis" updated with artifact radar signatures and probe suggestions #2153
- Scenario updates
  - _Defender Hunter_ updated #2209
  - _Deliver Ambassador Gremus_: initial heading set explicitly #2198
  - _Surf's Up!_: current orders display, comms utility integration, translation contexts #2252
  - Comms utility: updated comments, ordnance availability, bug fixes #2253
  - _Carriers and Turrets_ variation format updated #2165

### Fixed

- Custom button/info swapping not syncing to UI #2221
- Comms UI desync issue #2207
- Comms overlay showing focus highlight on previous selection #2201
- Auto repair attempting to repair systems that can't be repaired further #2144
- Combat maneuver generating heat without firing any thrusters #2142
- Camera glitches with small window offset #2233
- modelData documentation incorrectly referring to normal maps as specular maps #2232
- Ninja package build error using wiki instructions #2211
- Misspelled faction name #2195
- Maneuvering system oscillations in fast-turning ships #2151
- Internal docking breaking ships #2150
- Products checked for presence before processing goods #2167
- Cinematic view crash #2136
- Rotation behavior in tactical and single pilot views #2157
- Spelling errors in training scenario and science database #2152

### Translation additions

- German: _Surf's Up!_, _Capture the Flag_, _Delta Quadrant Patrol Duty_, _Allies and Enemies_, _Shoreline_, _Close the Gaps_, _Escape_, _Broken Glass_, _Fermi 500_, _Carriers and Turrets_, ship diversification utility, main and science database updates (#2257, #2251, #2241, #2222, #2208, #2203, #2197, #2155, #2147, #2169, #2178, #2161, #2167)
- French: _Carriers and Turrets_, _Surf's Up!_, _Liberation Day_, _Outpost_, _PvP_, _Defender Hunter_, comms scenario utility, player ship upgrade/downgrade utility, science database (#2244, #2238, #2224, #2226, #2217, #2220, #2214, #2216, #2239, #2213, #2215, #2212, #2218, #2235, #2237, #2242, #2259)

## [2024-10-03] (Pre-release)

### Added

- New scenarios
  - _Liberation Day_ #2163
- Scenario utilities
  - _Comms Scenario Utility_ #2162
  - _Player Ship Upgrade and Downgrade_ #2171
- Lua scripting API
  - `applyDamage()` function for applying damage from scripts
  - Pseudo-random number generator for reproducible random sequences
  - `log()` function for script-side logging
  - Warp drive script bindings (different max warp levels, warp speed control)
  - Command function Lua APIs (`command*` bindings)
  - Comms messages from scripts
  - SupplyDrop API
  - Zone script bindings and rendering
  - `getEnemiesInRadius()` function
  - Many additional entity and faction API bindings
- Game features
  - Stdin Lua console when running headless
  - Logging to stdout in Windows headless mode
  - Option to disable reactor overload explosion
  - Failed-to-connect reason now reported to client
  - Custom functions can be assigned to multiple stations simultaneously
  - Lua API to limit which crew positions can be used
  - Single click to select objects in GM screen
- Rendering
  - Warp jammer range rendering on radar
  - Radar trace for warp jammers
  - Configurable nebulae render range
  - Billboard rendering
  - Shield hit effect rendering
  - Engine emitters
  - Zone rendering
  - Mine trigger range rendering
  - Nebula GM screen rendering

### Changed

- Lua REPL now shows return results and stores command history
- Lua console improved with input line prefixing and history
- Server scanner unified: no LAN/Internet toggle, always lists all servers, prepares for Steam server listing
- Crew position refactored into a typed enum with helper set class
- Improved error handling in `require()` to avoid stack corruption
- Better error reporting when Lua-to-vecX conversion receives wrong data type
- Remove `'f'` suffix from numeric literal usage in Lua scripts
- Script documentation system started (new format)
- Removed unused files and cleaned up remaining TODOs
- Apple-specific bundle initialization moved from `main()` to SeriousProton engine
- Color config now loaded after resource paths are setup
- Keybindings locale now initialized after loading locale
- Limited multiplayer update rate of certain components to reduce network load
- Reduced network replication rate (fixed 500+kb/s/client issue)

### Fixed

- Maneuvering system inducing oscillations in fast-turning ships #2151
- Internal docking breaking ships #2150
- Lua script environment `require()` issues across different script environments
- Combat maneuver generating heat without firing any thrusters #2142
- Auto repair trying to repair systems that can't be repaired further #2144
- Hardware DMX blink effect (on/off times were swapped) #2143
- Missiles incorrectly getting hull component (making them targetable)
- AI controller incorrectly added to player ship templates
- Steam and Discord builds fixed
- Ships missing default AI
- Black hole radar trace
- Probe 3D model rendering
- Nebulae not rendering in 3D, beam effects rendered incorrectly
- Scan probes, shields count, beam weapon damage location
- Ship docking issues
- Player ship spawning from UI
- Cinematic view crash (#2136)
- Color config and keybinding locale initialization ordering

### Translation additions

- German: _Broken Glass_, _Fermi 500_ scenarios (#2155, #2147)
- German: scenario translations and main translation updates (#2154, #2161)

## [2024-08-09]

### Added

- Beam frequency and system target controls to Single Pilot station #2133
- Script callback error reporting to Lua console
- Missing script bindings

### Translation updates

- German (#2128)

### Fixed

- Missing translation wrappers in engineering screen #2125

## [2024-06-20]

### Added

- New scenario _Outpost V2_ #2123
- Hardware state for shields reconfiguring #2119
- `toJSON()` / `fromJSON()` Lua script functions
- French translation for _Borderline Fever_ scenario

### Changed

- Scenario updates
  - _Borderline Fever_ (#2110): localization fix, scenario utilities, new enemy ships, visual asteroids, science database entries

### Fixed

- Warp and jump commands now clamped
- Glitch post processor on certain hardware
- Translation marker conflicts resolved
- Loop index `_` replaced with named index `idx` to prevent localization issues
- Undefined behavior in scrollbar prevented
- Segfault prevented when ship template does not exist #2113
- Command-line parameters no longer written into `options.ini` (treated as temporary overrides only)

## [2024-05-16]

### Added

- Theme selection in options menu, with font changing on theme switch
- New wormhole visuals for 3D viewports and radar representation
- Lua `log()` function that writes only to log files (unlike `print()`)
- Mine radar icon separated from other icons for easier customization
- Arrow images split into multiple image files
- New translation files
  - `scenario_39_locusts.fr.po` and `.en.po`
  - `scenario_53_escape.fr.po`
  - `scenario_48_visitors.fr.po`
  - `scenario_58_race.fr.po`
  - `scenario_60_captureFlag.fr.po`
  - `control_code_scenario_utility.fr.po` and `.en.po`
- German translations for _Deliver Ambassador Gremus_, _Edge of Space_, _Locust Swarm_, _PvP_

### Changed

- Script error renderer removed (superseded by Lua console)
- Theme selector hidden when only one theme is available
- Place Station scenario utility updated with translation tags and contexts
- Scenario updates
  - _Planet Devourer_ (#2091): fewer black holes on hard difficulty, timer bug fix
  - _Fermi 500_ (#2081): localization fixes, GM stats buttons, distance info
  - _Escape_ (#2080): EE max health system, science database entries, refactored code
  - _Capture the Flag_ (#2083): settings instead of varieties, scenario utilities, refactored
  - _Deliver Ambassador Gremus_ (#2082): scenario utilities, visual asteroids, `getScenarioTime()`
  - _Unwanted Visitors_ (#2085): spawn ships utility, control code utility, damage control console
  - _Scurvy Scavenger_ (#2077): scenario utilities, versioning, GM button, eased gameplay
  - _Borderline Fever_: refactored with localization and scenario utilities
  - Translation contexts and tags added to multiple scenarios

### Fixed

- Voice paths in Scenarios 48 and 51
- Keybinding conflict between Lua console and ship voice
- Lua console key text labels set up
- `ShipTemplateBasedObject` hull max exceeding 100%
- Scenario 20 (Training 1) made playable again for non-English languages
- Spelling error in ship diversification utility

## [2024-04-28] (Pre-release)

### Added

- Lua console backported from ECS branch, replacing the script error renderer
- New keybindings
  - Direct power/coolant setting for Engineering (supports joystick bindings)
  - Arrow keys to move crew in Engineering, avoiding S key conflict with shields
- `setImpulseRequest()` function validating impulse request values
- `EE_CONF_DIR` environment variable to configure the configuration path
- New player ship template: _Saipan_ corvette carrier, with internal/external docking, energy sharing, hull repair, and probe supply
- New scenario utilities: CPU Ship Diversification Scenario Utility
- New scenarios: _Kessler_ #1982, _Locust Swarm_ #2032
- New API functions
  - `setSelectOnFocus()` method for textentry
- Auto-connect for ship windows
- New translation files
  - `spawn_ships_scenario_utility.en.po` and `.fr.po`
  - `cpu_ship_diversification_scenario_utility.fr.po`
  - `scenario_79_kessler.en.po` and `.fr.po`

### Changed

- Keybinding menu clarified with explanations that bindings work for joysticks as well
- Weapons hotkey menu label clarified to "Disable missile aim lock"
- Window angle input converted from slider to textentry
- Firing solution calculation improved, fixing NaN behavior in turn angle calculation
- Joystick bindings standardized
- Science screen shows max hull/shields, hides non-existing systems
- Science band colors increased in contrast for better accessibility
- Weapons tutorial clarified and expanded with homing and manual-aiming sections
- Radar and Helms tutorial text clarified and fixed
- Station selection screen rearranged with added crew info and headcount per station
- Combat maneuvers removed from helms tutorial
- `GuiAdvancedScrollText` performance improvements
- `GuiAdvancedScrollText` scrollbar click change based on text size
- Model scale for Striker (`dark_6_fighter`) changed from 5 to 3
- Place Station scenario utility updated: documentation, diagnostics, faction-based service availability
- Scenario updates
  - _The Omicron Plague_ (#2051): warp jammer range fix, goods purchase fix, repair crew buttons for damage control
  - _Planet Devourer_ (#2052): locale updates, custom UI elements on Damage Control console
  - _Broken Glass_ (#2053): locale adjustments, context label fix
  - _What the Dickens_ (#2041): all stations use modified comms, visual asteroids, instructional hints, defeat explanations
  - _Scurvy Scavenger_ (#2034): loop index conflict fix, Striker speed increase, varied contract prompts
  - _Unwanted Visitors_ (#2027): switched to scenario settings, external utilities, refactored code, science database entries
  - _Visitors_ (#2029): restored translation contexts for standardization
  - _Planet Devourer_ (#2008): translation capability updated, `devour.en.po` created
- Translation updates: French UI and scenarios (#2005, #2010, #2017, #2043, #2044, #2046, #2050, #2054, #2055, #2056, #2073), German UI and tutorial translation (#2045, #2057, #2065, #2071)
- Translation tags added to scenario utilities and scenarios

### Fixed

- New hotkeys improperly operating on selected system instead of hotkey system
- Duplicate default keybind for Science and Relay
- Crash when using impulse set keybinding
- `ShipsLogControl` update failure with duplicate text
- `GuiScrollbar` limits preventing full range on large lists
- Division by zero and out-of-range array indexing in `crewStationScreen`
- Missing translation tags added in scenarios (#2006)

## [2023-06-17]

### Added

- Scenario settings added for _Scavenger_, _Shoreline_, and _Patrol Duty_ scenarios #1988

## [2023-06-12] (Pre-release)

### Added

- New scenarios
  - _Broken Glass_ #1795, #1796, #1798
  - _Doomed Outpost_ #1838
  - _Chaos of War_ #1863
  - _Planetary Devourer_ #1972
- New utility scripts
  - Call sign generation utility for scenarios
  - CPU ship diversification utility for scenarios
- API functions
  - `FactionInfo:setNeutral()` for three-way faction relationships #1953
  - `WarpJammer:getHull()` and `WarpJammer:setHull()` exported for scripting #1828
- GM tweaks
  - ShipTemplateBasedObject (including stations) tab with acceleration and warp speed tweaks #1912
  - Beam heat and energy per fire sliders #1901
  - Repair crew count for PlayerSpaceship #1858
  - WarpJammer hull slider #1828
- New keybinds to adjust impulse by 1% and 10% increments #1948
- Player ship descriptions shown on ship selection screen (server side) #1981
- Reverse proxy status displayed in server creation screen #1920
- Icons on GuiListbox entries #1930
- Icons in GM object creation view's ship lists #1931
- ScienceDatabase entries for stations, technologies, and in-game features #1857
- Themed hover behavior on GuiListbox entries #1935
- New translations
  - Translation hooks for credits screen #1884
  - Extensive `_()` translation tagging in Xansta's scenarios (Scavenger, Shoreline, Patrol Duty, Outpost) #1890, #1897, #1945, #1950, #1961, #1979
  - French scenario translations
    - _The Omicron Plague_ #1771, #1772, #1782, #1783, #1784, #1785
    - _Broken Glass_ #1798, #1843, #1859
    - _Outpost_ #1844, #1868, #1870, #1875, #1880, #1882, #1883, #1887, #1889, #1895
    - _Patrol Duty_ #1890, #1896, #1976
    - _Scavenger_ #1945, #1950, #1979, #1985
    - _Shoreline_ #1897, #1936, #1983
    - _Defender Hunter_ audio clips #1790
    - Main UI #1973, #1986
  - German translations: Main UI (#1980), general updates (#1984)

### Changed

- Mission time clock now uses `hh:mm:ss`-formatted time #1773
- Stats on Operations screen resized to match other stations #1774
- Asteroid rendering on radar refactored #1902
- Strafe and boost power-damage indicators separated #1907
- Ship password dialog improvements: show asterisks, remember last used password, Enter callback #1778
- ScienceDatabase beam and shield frequency display simplified #1867
- Scenario settings initialization rewritten: always initialize settings on scenario start #1848
- HTTP script access uses server-selected player ship as default #1776
- `CpuShip` uses locale names for order display in GMInfo #1860
- Faction names on ship selection screen use `getLocaleFaction()` #1917
- Keyboard shortcut list population improved with i18n reload and more crew positions #1877
- Escape key ignored during autoconnect state #1919
- onDraw argument names aligned between definitions and implementations #1943
- GameStateLogger replaces float-to-string conversion with `to_chars` #1911
- Player ship call signs hidden for internally docked ships #1905
- Loop variable uses reference type in `GuiObjectCreationView` to prevent copying #1908
- `SpaceShip` extraneous `getGMInfo()` override removed #1921
- Scripting documentation edited and expanded
  - SpaceShip, SpaceStation, CpuShip, PlayerSpaceship, ShipTemplate, ShipTemplateBasedObject docs #1820, #1821, #1822, #1823, #1819
  - FactionInfo, ScienceDatabase, GameGlobalInfo docs #1851, #1852, #1853, #1842
  - SpaceObject, item, terrain, weapon functions #1824, #1825, #1826, #1827
  - GM functions and messages #1808
  - Scripting object functions #1809
  - EDockingState enum and EMainScreen enums #1806, #1898
  - ModelData functions #1854
  - Energy functions and collisions clarified #1864
  - Faction relationship documentation corrected #1871, #1954
- Build changes
  - RPM CPack builds set `CMAKE_INSTALL_PREFIX` for correct resource paths #1840
  - Android NDK bumped to 23c, enabling 64-bit ARM v8 builds #1888
  - Android API properly set in APK name
  - 64-bit ARM Android builds added for newer devices
  - `update_locale` build target fixed
- README expanded with download, install, community, and docs sections #1856
- README links ARM v8 Android build, notes emulation #1965
- Reference to `emptyepsilon.org` removed
- Scenario updates
  - _Broken Glass_ GM buttons grouped and translation tags added #1843
  - _Borderline Fever_ converted from scenario variations to scenario settings #1841
  - _Outpost_ updated with typos, science database entry, translation tags #1949
  - _Chaos of War_ database entry safeguards for translated versions #1863
  - _Planetary Devourer_ call sign generation and CPU ship diversification moved to utility files #1972
  - _The Omicron Plague_ bugs fixed #1783, #1784, #1785, #1787, #1794
- Translation updates: French (#1772, #1781, #1793, #1859, #1866, #1868, #1882, #1883, #1887, #1889, #1895, #1936, #1973, #1976, #1979, #1985, #1986), German (#1980, #1984)

### Fixed

- `ShipTemplate:setHull()` and `ShipTemplateBasedObject:setHull()` respect limits #1811
- `ShipTemplate:getSystemName()` uses import values for enum conversion #1834
- `ShipTemplate:copy()` respects tube count limit for tubes, instead of beam count limit #1810
- Inability to repair systems fixed
- `CpuShip:orderAttack()` no longer targets non-hostile ships #1812
- `SpaceShip` no longer attempts to dock with itself #1906
- Relay probe launch button disabled when ship has 0 probes #1918
- Relay can once again select alert level buttons #1786
- GM chat windows properly un-minimized after closing #1928
- `GuiSelfDestructIndicator` typo fixed
- `GuiEntryList` clears entries when passing options and values to `setOptions()` #1916
- `BeamEffect` checks existence of source and target before use #1874
- Main screen comms info no longer persists after it should be closed
- Banner text now cleared on scenario reset #1775
- Heading and velocity displays fixed on Single Pilot and Tactical screens
- URL for EmptyEpsilon website in scripting reference fixed #1791
- WarpJammer mesh loading fixed with better OBJ format handling
- Scenario fixes
  - _The Omicron Plague_ bugs fixed #1783, #1784, #1785, #1787, #1794
  - Custom ships missing from science database in _Scenario 20_ worked around #1869
  - Scenario settings initialized on scenario start #1848
  - Spelling mistakes fixed across 4 scenarios
- `update_locale` build target fixed

## [2022-10-28]

### Added

- Button on cinematic view automatically changes view to another ship every 30 seconds #1753
- API functions
  - `WarpJammer:getRange()` gets the jamming range #1759
  - `WarpJammer:get`/`setHull()` manages the jammer's hull strength #1759
- New scenarios
  - _The Omicron Plague_ #1738
- New translations
  - German scenario translations
    - _Battlefield_ #1746
    - _Training: Cruiser_ #1746
    - _Empty Space_ #1746
    - _What the Dickens_ #1745
    - _Defender Hunter_ #1742
    - _Surrounded_ #1742
    - _Waves_ #1733
  - Translation hooks #1732
- New settings
  - Hotkey for fullscreen toggle #1750
  - Analog joystick bindings for science scanning minigame (`SIENCE_SCAN_PARAM_SET_`...) #1770
  - Hotkeys for setting alert levels (`RELAY_ALERT_`...) #1765

### Changed

- Scripting documentation now lists class name with each member #1737, #1747
- Documentation for certain API functions improved #1743, #1759
- Sound attenuation at distance changed 1ef5a10
- Build changes
  - Code files restructured into more modular groups
- Scenario updates
  - _Basic Battle_ asteroid spawning updated
- Translation updates
  - French #1734
  - German #1733, #1742, #1745, #1746, #1758

### Fixed

- Missile tube indicators once again point from the tube's direction, instead of straight ahead #1751
- UI layer registration fixed c9b22b0
- Segfault crashes on radar views fixed #1760, #1763, #1766
- Glow effect interpolation fixed #1762
- Crash when sorting multiplayer object layers in radar view fixed
- UI layout infinite loop fixed
- Flickering/z-fighting between nebulae and other elements improved #1736
- Removed parens from resource filenames to fix `cmake`
- Relay text no longer flashes on update in upper corner #1735
- Text fields no longer scroll if they aren't multiline inputs
- Text cursor position now resets if text field contents are updated
- Avoid Operations screen crashes when ship is destroyed
- Scenario fixes
  - Missing `formatTime()` function added to `utils.lua` #1757

## [2022-03-16]

### Added

- Satellite ship templates, meshes, and textures #1696
- New reinforcement types added to default station comms script #1701
- Earth texture for planets #1698
- GUI is now themeable 79b7dde, #1681
- Steam SDK integration
  - Steam P2P connections possible
- Ships can now dock internally or externally to other ships, based on class 55e7992
- DMX events added for activating self-destruct sequence, countdown #1504
- Experimental multi-monitor support
- Configuration file path now logged
- Server port now configurable on server setup screen
- API functions
  - `getFactionInfo()` returns a FactionInfo reference e36c7ea
  - Ship template functions `setExternalDockClasses()` and `setInternalDockClasses()` to configure how other classes of ship dock 55e7992
  - `sectorToXY()` converts a sector name to x/y coordinates #1651
  - `SpaceObject:sendCommsMessageNoLog()` hails a player ship to send a message, but doesn't log a failed delivery
- New translations
  - French scenario translations
    - Tutorials #1715
    - _Empty space_ #1666
    - _Battlefield_ #1665
    - _Surrounded_ #1663
  - Translation hooks #1617, #1623, #1624, #1629, #1637, #1638, #1639, #1640, 52f8905, #1656, #1660, #1664, #1683, #1691, #1700, #1705, #1731
- New settings
  - Hotkeys for top-down view (`TOPDOWN_`...) #1593
  - Hotkeys for cinematic view (`CINEMATIC_`...) #1593
  - `guitheme` and default GUI theme file `resources/gui/default.theme.txt` 79b7dde
  - `script_cycle_limit` to limit loop execution in scripts #1678
  - `multimonitor` to toggle experimental multi-monitor mode 7d5309b

### Changed

- Glitch, warp shaders converted
- Netboot script uses newer EmptyEpsilon and Debian versions
- Toggle buttons can now include icons
- Cinematic view readded
- HVLI damage buffed
- Scenarios now have their own locale files
- Engineering now shows unused coolant
- Options menu redesigned
- Database page layout refactored
- SpaceObject faction can now be changed during gameplay e36c7ea
- UI autolayout system replaced with SeriousProton 2 layout manager
- Warp, jump energy draw rebalanced 9c3198b
- Coolant distribution behavior changed d7efba3
- Scenario selection menu performance improved
- Linux app icon path changed to `hicolor` subdirectory #1658
- Text editing in multiline fields improved
- Server settings are now configurable while running 9e46814
- Crew position selection screen redesigned 43f2dfe, b0e1be7
- Sector naming patterns changed; use negative numbers "west" of 0, standardize capitalization "north" and "south" #514, #1628, #1651
- Settings files' path handling simplified
- Scenario settings localization handling improved
- API changes
  - `ShipTemplateBasedObject:setShieldsMax()` documentation improved #1729
  - `globalMessage()` now has a configurable timeout 274ae83
- Build updates
  - `CONFIG_DIR` removed
  - CI now builds Steam variant
  - CI now uses Visual Studio 17 2022
- Scenario updates
  - _Basic Battle_ victory alert converted from buttons to message #1730
  - _Fermi 500_ updated to version 2.1.0 #1725
  - _Basic_ renamed to _Basic Battle_ 263453f
  - _Beacon of Light_ updated #1699
  - _Surrounded_ now has a victory condition #1688
  - New station placement script `place_station_scenario_utility.lua` #1689
  - _Chaos of War_ updated to version 2 #1689
  - _Defender Hunter_ updated to version 10 #1661
  - Scenario sector name handling updated #1628, #1651
  - _Allies and Enemies_ updated to version 1 #1624
- Translation updates
  - French #1630, #1631, #1633, #1634, #1635, #1636, #1641, #1643, #1644, #1645, #1646, #1647, #1648, #1649, #1650, #1655, #1657, #1663, #1682, #1697, #1706, #1712, #1713, #1714, #1723
  - German #1627, #1707, #1711, #1726
  - Scenario translation contexts standardized #1615, #1617, #1620, #1621, #1622, #1623, #1625, #1642, #1721
- Changed settings
  - `touchscreen` applies only to Android builds
  - `last_server` now includes port number

### Fixed

- GM screen and custom function callbacks avoid undefined behavior
- Netboot build now set to `noninteractive` to skip keyboard layout checks
- Typos in tutorial, science database #1716
- Self-destruct dialog layout fixed
- Localized scenario audio clips are now played instead of English #1704
- Hotkeys no longer trigger UI controls that are explicitly made invisible
- Scripting reference document sorting, missing references, and errors fixed #1708, #1709, #1710, #1717
- Player ships flagged as indestructible can no longer be destroyed by reactor overloads #1702, #1703
- Station selection button no longer obscured in database view
- Hotkey binding page layout fixed
- Side 3D main screen now appears more consistently on widescreen displays 7df93ed
- Game crash on ship destruction while in Engineering fixed
- `SpaceObject:beamEffect()` example fixed
- Planet textures no longer flipped #1687
- Heading tooltip on Helm radar fixed #1684
- Custom functions now sorted on the server rather than the client
- Drawing selection boxes on GM screen fixed
- Random static effect on player ship destruction fixed #1670
- Nebulae inside zones no longer z-fight/flicker #1673
- Missing resource files logged on startup #1668
- Text on main screen cleared when resetting a scenario #1672
- Autoconnections to main screen fixed
- Target reticule in 3D viewport/main screen fixed #1675
- Power, coolant text alignment on Engineering screen fixed
- Text input now stops if a text field is removed while focused
- Avoid crashing when system damage is disabled
- You can no longer target yourself if you belong to a faction that's hostile to yourself
- Streaming ACN (sACN) now sends UDP data as expected 384df5f
- Packed resource handling in home directories fixed #1654
- Debug graphs no longer render offscreen #1653
- GM screen pause hotkey now toggles pause button state #1652
- MSVC builds fixed
- Display of localized hotkeys fixed
- Android config file check fixed
- Positional offset in ship's log text fixed
- Font size on waypoints fixed
- Successful hacking attempts now actually hack systems #1626
- API fixes
  - `globalMessage()` output now resized to fit text 274ae83
- Scenario fixes
  - _Birth of the Atlantis_ handles objects without warp jammers #1719
  - _Borderline Fever_, _Chaos of War_ ship template references fixed #1676
  - Enemies in _Waves_ no longer stay idle when spawned
  - _Birth of the Atlantis_ progress can now continue if player moves away from the artifact
  - _Basic_ message stating time remaining fixed

## [2021-11-27]

### Added

- Scenario settings can now be localized

### Changed

- Warp jammer behavior updated
- Player state reset and game simulation paused after selecting a new scenario
- Translation updates
  - French #1613, #1614, #1616

### Fixed

- Player ship in _Basic_ now gets warp drive even if its template doesn't include one

## [2021-11-12]

This release replaced core engine components, and it and future releases require GL 2.1 compatibility, a potentially breaking change for older devices.

### Added

- Scenario settings can now have default values [2dfb7c](https://github.com/daid/EmptyEpsilon/commit/2dfb7cc889a7ff55ceb00d76cc829400bc05aeb4)
- New master server registration screen with connection status #1567
- Multi-line text entry fields #1567
- New debug-build hotkey for FPS (<kbd>F10</kbd>) #1567
- Desktop launcher icon installed on Linux desktops #405, #1558
- Touch controls added for main screen #1553
- GL debug output through OpenGL extension [KHR_debug](https://www.khronos.org/opengl/wiki/Debug_Output) in debug builds #1549
- 3D model and packed resource support for Android #1535, #1540
- Back key on Android now works like <kbd>ESC</kbd> on other systems to back out of screens/exit #1567
- Beam weapons can now do different types of damange than just Energy
- API functions
  - `getScenarioSetting()` returns scenario-specific settings #1567
  - `SpaceShip:setBeamWeaponArcColor()` and `setBeamWeaponDamageType()`
- New scenarios
  - New _Basic_ scenario combines former _Basic_ and _Quick Basic_ scenarios with new settings [cb9e158](https://github.com/daid/EmptyEpsilon/commit/cb9e1586fcbc07da6558cca95db415fc88d0b928)
- New translations
  - French scenario translations
    - _Defender Hunter_ #1604, #1614
    - _Basic_ #1611
    - _Clash in Shangri-La_ #1594, #1610
    - _What the Dickens_ #1520, #1523
    - _Training: Cruiser_ #1519
    - _Escape_ #1515, #1523
    - _Deliver Ambassador Gremus_ #1514, #1523
    - _Ghost from the Past_ #1510
    - _Birth of the Atlantis_ #1508
  - Translation hooks #1486, #1499, #1506, #1511, #1512, #1522, #1567
  - German scenario translations
    - _Basic_ #1525, #1606
    - _Ghost of the Past_ #1525
    - _Birth of the Atlantis_ #1525, #1548
    - Tutorials #1487
- New settings
  - `server_scenario` setting to skip server creation and immediately start the scenario #1599
  - Fine-grained joystick control option for impulse throttle #1567
  - Main screen field-of-view angle configurable in the graphics tab of the Options screen and via `main_screen_camera_fov` #1555
  - Many new hotkeys #1567

### Changed

- Styling on scripting reference docs #1609
- Radars are now drawn in layers #1595
- Images on database screen are now treated as icons if a 3D model is associated with the entry #1587
- Explosion particles improved #1583
- Particle system performance improved #1580, #1584
- Vectors pass values by reference, improving memory performance #1579
- Zones implementation complete #529
- Credits updated
- Text is now selectable in input fields, and inputs handle text cursor movement better #1567
- Touchscreen functionality is now assumed by default, and the `touchscreen` setting now only forces mouse emulation when set to `0` and ignores any other value #1567
- Player ship jump/warp drive settings moved from global options to GM screen #1567
- Server creation menus redesigned #1567
- Model and View references improved #1541, #1547
- Lights now computed as directional in rendering #1539
- Android version now requests `INTERNET` and `ACCESS_NETWORK_STATE` permissions #1531
- Selector and indicator arrow images split into separate image resource files #1503
- Ship template script files reorganized
- UI image, texture, mesh, sound effect, and scenario audio clip files reorganized
- Custom functions are now indexed and can be reordered #1492
- UI selector text can now be resized #1489
- Hotkey UI entry fields widened #1485
- Rotating model view rendering improved #1476
- Build changes
  - LTO enforced on build targets #1608
  - Floating point number warnings addressed
  - Use `cmake`'s `tar` instead of `7z`, removing the dependency #1581
  - `json11` replaced with nlohmann/json #1572
  - Debian, macOS packaging updated #1571, #1576
  - Debug Android builds allow debugger to connect #1562
  - CI now builds with `ninja`
  - GL 2.1. / ES 2.0 compatibliity checks added #1546
  - Android APK build process updated #1531, #1540, #1552
  - CMake downloads SDL2 #1567
  - CMake-driven config header #1474
  - `ninja` build tool output colorized #1457
  - Source build version numbers fixed #1473
  - Use POSIX mingw
  - Default window title hardcoded #1474
  - Android builds use `OpenGL_GL_PREFERENCE=LEGACY` #1479
- SFML usage converted to SeriousProton/SDL/GLM
  - SFML references removed from CI #1571
  - Assert calls replaced with SDL #1567
  - Packaged resource handling now uses standard library for filesystem access #1560
  - Pointers now use SeriousProton ID types #1543
  - 3D meshes now optimized by [meshoptimizer](https://meshoptimizer.org/) #1542
  - Shaders migrated to new format #1533
  - CI updated to use SDL2 #1529
  - Input converted from SFML to SDL #1530, #1567
  - Rendering converted from SFML to SDL #1534, #1567
  - Rendering code uses SeriousProton abstractions instead of directly calling SFML
  - Unused render layers removed
  - HTTP server replaced with SeriousProton 2's
  - Shaders now require GL 2.0 #1483
  - Angle difference measurement moved out of SFML namespace
  - Fixed pipeline projection matrix removed #1481
  - SFML threads replaced with standard library
  - SFML `Clock` replaced with SeriousProton `SystemStopwatch`
  - Redundant `FindSFML.cmake` removed
  - GLM library moved to SeriousProton engine
  - SFML vectors replaced with GLM
  - SFML networking removed
    - Philips Hue devices now use SeriousProton HTTP requests #1475
    - SFML networking code replaced with SeriousProton code #1468
- API changes
  - `Planet` API and rendering adjusted #1590
  - `getScenarioVariation()` deprecated in favor of `getScenarioSetting()` #1567
- Scenario updates
  - More specific loop index variable name in _Basic_
  - All players receive timer warning in _Basic_
  - _Basic_ now uses scenario settings instead of deprecated variations
  - _Birth of the Atlantis_ updated with minor fixes #1567
  - _Shoreline_ updated to version 2 #1559
  - Scenario header setting fields no longer case sensitive #1567
  - Scenario `Type`/`Category` fields reorganized #1567
  - _Defender Hunter_ comms scripts #1522
  - Tutorial script files reorganized
  - Common tutorial script code moved into functions in `tutorialUtils.lua`
  - `comms_station_scenario_06_central_command.lua` script removed and inlined into _Edge of Space_
  - Short-range radar tutorial updated #1494
  - Dummy ships in tutorial can no longer be hailed #1494, #1495
  - _Borderline Fever_ updated to version 5.1.3 #1484
- Translation updates
  - French #1505, #1507, #1592, #1601, #1605, #1612, #1613
  - Czech #1500
  - German #1472, #1490, #1496

### Fixed

- Enemy ship in shields tutorial is now less aggressive #1607
- Improve handling of malformed objects #1603
- Scenario names and description translation display fixed
- Beam and turret logic fixed #1602
- Wormhole rendering on radar fixed #1588
- Username no longer ignored during autoconnect #1491, #1585
- Mines no longer spawn particles when running headless #1584
- Filesystem pathing build failures with GCC10 fixed #1582
- Unused audio recording functions for voice chat removed from Android builds, preventing crashes on certain devices #1574
- Combat maneuver hotkeys fixed
- Planets now use specular lighting #1566
- Beam arc rendering fixed #1567, #1600
- `get.lua` example in built-in HTTP server page fixed #1567
- Netboot crash fixed when `autoconnect=` setting value is null #1561
- Handling of meshes with more than 64k vertices fixed #1556
- Lighting positions fixed #1551
- Specular lighting fixed #1545
- UI element clicks on Android fixed #1538
- Tilde/backtick key (<kbd>`</kbd>) fixed for hotkey binding #1530
- Depth cutoff for 3D viewports fixed #1532
- `CpuShip:orderFlyFormation()` behavior with warp ships improved #1527, #1567
- Random noise overlay fixed
- Debug update time info graph (<kbd>F11</kbd>) fixed
- New UI elements are now properly initialized
- IP addresses fit better in server creation #1489
- GM tweak menu resized to prevent ship menu from overflowing #1488
- Empty model data no longer reported as unused
- macOS bundling during builds fixed #1469
- Server IP address entry field fixed #1468

## [2021-06-23]

### Added

- Language translation setting under interface options in Options screen #1423
- Ships can now have reverse speed and acceleration values #1353
- Hotkeys added to increase and decrease warp speed #1448
- Ship energy consumption, coolant, and heat rates can now be configured via scripting and GM tweaks #825, #1446
- Server browser shows a reason when a client disconnects #940, #1435
- Packaging added for macOS (DMG) and Windows (MSI) builds #1438
- Angle calculation functions added to `utils.lua` script #1408
- Preferences can now be saved on Android #1425
- API functions
  - `SpaceShip:getJumpDelay()` #1463
  - `SpaceShip:getDockingState()` #1463
  - `SpaceShip:get`/`setSystemHeatRate()` and `get`/`setSystemCoolantRate()` #1446
  - `PlayerSpaceship:get`/`setEnergyShieldUsePerSecond()`, `get`/`setEnergyWarpPerSecond()`, and `SpaceShip:get`/`setSystemPowerRate()` for energy consumption values #1446
  - `ScienceDatabase:setModelDataName()` sets a model for a science database entry #1152, #1434
  - `getGameLanguage()` returns selected translation language #1426
- New scenarios
  - _Training: Cruiser_ combat scenario #1424
- New translations
  - Translation hooks #1374, #1393, #1395, #1396, #1398, #1400, #1401, #1402, #1403, #1407, #1416
- New settings
  - `main_screen_flags` can toggle spacedust, headings, and callsigns on main screens #1430
  - `www_directory` sets relative path for the HTML server #1452

### Changed

- GM tweak no longer shows shields with IDs greater than the ship's shield count #1455
- Scanned beam-less or shield-less hostile ships no longer show  frequency graphs #1451
- Exuari ships now have custom radar icons #1424
- Shaders and 3D rendering refactored #1359
- Key/value GUI component code refactored #1443
- Reputation removed from station comms #1162, #1217, #1442
- Warp jammer ranges are now exported #1444
- Discord integration now supports Linux #1431
- 3D viewports/main screen now require GL 2.0 #1427, #1428
- Custom buttons and messages now appear automatically on related screens #1394
- Particle system compatibility improved #1392
- Scenario updates
  - _Basic_ scenario GM functions enhanced #1409
- Translation updates
  - Common buttons grouped for easier translation #1418
  - German translation updated #1467
  - French translation updated #1393, #1397, #1414, #1420

### Fixed

- `gcc` compilation warnings addressed
- Localization updating scripts fixed
- UI elements don't flicker or reposition when one is removed #1047, #1181
- "Defend a Waypoint" order fixed in ship comms script #1466
- Ship scan description now appears after selecting another ship with no scan description #1456, #1464
- Nebulas honor radar range #1462
- Object visibility on radar fixed #1461
- Radar is blacked out inside nebula #1461
- Short-range radar is always visible #1461
- CMake warnings on GNUInstallDirs addressed #1459
- 3D models no longer try to be rendered if 3D rendering is disabled #1458
- Hotkey remapping screen no longer removes joystick bindings #1454
- Clients no longer register duplicate missile explosions #1453
- Resizing the window while using a widescreen 3D side main screen no longer results in unstable 3D rendering #1450
- Radar no longer interferes with widescreen 3D side main screen #1447
- Comms no longer overlap reputation counter and clock on Relay #1442
- Rendering fixes on some older GPUs #1440
- Android builds fixed #1436
- Radars render correctly on Android #758, #1413
- Black hole render blending fixed #1429
- GM info can now be translated #1417, #1433
- SFML window activated before rendering 3D #1410
- Reversed textures on 3D models fixed #294, #1405, #1419

## [2021-03-31]

### Fixed

- Reverts hotkey config translation tags from #1382, preventing a crash

## [2021-03-30]

### Added

- macOS CI builds #1389
- API functions
  - `getActivePlayerShips()` returns a list of player ships #864, #1361
- New translations
  - Translation hooks #1279, #1377, #1383

### Changed

- Build now uses C++17 and updated CMake #1368, #1385
- Particle engine improvements #1367, #1370
- Translation updates
  - French translation updated #1371
  - Extended characters added to German translation #1357

### Fixed

- `clang` build fixed
- Building with older `gcc` versions fixed
- Hotkey configuration bug fixes #1384
- 3D viewports/main screen are no longer letterboxed on narrow windows #1373, #1376
- Particle spacedust no longer uses uninitialized data #1375
- Explosion GFX fixed #1364
- Text in radar views is now readable at all resolutions #1031, #1362
- Translation fixes
  - Fixes in Czech translation of science database #1378
  - Translation hook on GM object creation view fixed #1372

## [2021-03-16]

### Added

- New textures for planets and moons #1337
- Particle instancing for improved performance #1310
- Billboard shader, improving performance of quad rendering #1303
- GM info shows missile and mine ownership #1294
- Hotkey binding interface added to Options screen #1050, #1283
- GM controls for asteroids
- Proxy servers can be named #1040
- Cross-platform compiling added to CI #1241, #1248, #1345
- Native build support for MSVC #1186, #1266
- Generic stations report reputation value to comms #1217, #1270
- Reputation counter and timer to Operations screen #1017, #1221, #1285
- Missile size, owner, and target ID added to game state log
- New UI typeface BigShoulders
- API functions
  - `queryScienceDatabaseById()` to return a ScienceDatabase object with the given `multiplayer_id` value #1214
  - `getSize()` for `asteroid` and `visualAsteroid`
  - `SpaceShip:get`/`setSystemPowerFactor()` to set reactor output #1071, #1244
  - Crew positions added to scripting reference #1273
  - Documentation for `CpuShip` AI scripting functions #1300
  - Scriptable scan probes: `PlayerSpaceship:commandLaunchProbe()`, `onProbeLink`/`Unlink()`, `commandSet`/`ClearScienceLink()`, and `ScanProbe:get`/`setTarget()`, `get`/`setOwner()`, `onArrival()`, `get`/`setSpeed()` #1295, #1298, #1306, #1307
  - `Artifact:onCollision`/`PlayerCollision()` to script artifact pickups and interactions #1326
  - `Artifact:setRadarTraceIcon`/`Scale`/`Color()` to customize artifact radar traces #1309
  - Scriptable missiles: `get`/`setTarget()`, `get`/`setLifetime()`, `get`/`setMissileSize()`, `getOwner()` for `HomingMissile`, `HVLI`, `Nuke`, `EMPMissile` #1291, #1294
  - `Mine:getOwner()` #1294
- New scenarios
  - _Chaos of War_ team combat scenario #1293
- New translations
  - Translation hooks #1188, #1194, #1196, #1197, #1200, #1201, #1202, #1207, #1208, #1210, #1211, #1212, #1213, #1215, #1218, #1219, #1247
  - French translation of science database #1151
- New settings
  - `font_regular`, `font_bold` settings for customizing fonts
  - Default keybindings for Weapons, Helms, Engineering screens #1289

### Changed

- Convert UTF-8 text elements to ASCII #1357
- Full player names now shown in crew position GM tweak view #1350
- Missile sounds change pitch based on missile size #1347
- Radar range GM tweaks moved from Player tab to Ship #1312
- Ships use radar ranges for targeting and firing #1327, #1348
- All ships have settable radar ranges #1312
- Voice chat toggle keys can now be rebound #1288
- Hacking dialog closes when target is out of range #1290
- Reactor output can be configured via GM menu or scripting #1071, #1244
- UI can make radar transparent #1277
- Radar tig visibility is now responsive to radar range #1276
- Hacking selection uses translated strings #1257
- `script_reference` path changed in bundled builds #1251
- Comms script text edited #1238
- Faction info text edited
- Removed `get`/`setWeaponTubeSize()` functions in favor of `get`/`setTubeSize()` #1025, #1222
- `scriptstorage.json` path uses `$HOME` environment variable
- Supply freighters can have jump drives
- GM tweak menu jammer improved
- Relay and comms functions refactored
- Updates in the script reference documentation
- Graphics performance improvements
  - GFX of beam effects and explosions improved #1296
  - 3D reticule moved to shaders #1314
  - Starfield background converted to a cubemap #1313, #1341
  - Shader initialization now skipped if OpenGL is unavailable #1308
  - Quads replaced with triangles #1322, #1349
  - Fixed lighting removed #1340
  - `glm` required as a build dependency #1346
  - Spacedust converted to shader for performance #1329
  - Debug views moved to shader #1332
- Translation updates
  - Czech translation updated #1355, #1358
  - Italian translation updated #1272
  - German translation updated #1258, #1280, #1324
  - French translation expanded #1151, #1153, #1154, #1182, #1183, #1243, #1245, #1250, #1258, #1261, #1263, #1265, #1269
- Scenario updates
  - _Waves_ refactored
  - _Basic_ scenario logs variant on error #1155, #1216
  - _Fermi 500_ updated #1302
  - _Capture the Flag_ updated #1301
  - Many scenarios edited for typos, clarity, code consistency #1231, #1230, #1232, #1233, #1234, #1236, #1237

### Fixed

- Cinematic view now honors ship selection #1356
- Builds on Fedora fixed #1352
- Show ship's own short-range radar range on Relay if player ship is hostile to its own faction #1311
- `SpaceStation:setCommsFunction()` no longer crashes if using a function imported via `require` #1170
- Black holes no longer spawn near stations at the start of _Basic_ #1292
- Music can stop playing or remain disabled on screen exit #883
- `getVelocity()` scripting documentation fixed #1281
- Player ship names on GM screen now update if renamed #1268
- Science database entries no longer duplicated on client reconnection #1240, #1254
- Windows build targets improved #1252
- Fix installation path for Discord integration library #1253
- Use 64-bit Discord integration on 64-bit builds
- Scripting documentation compiler now works with Python 3 #1246
- Friendly AI ships attempt to avoid friendly fire #589
- Engineering values no longer rounded to be off by 1 #949, #1223
- Game state logging now stops when launching a new scenario in the same session
- Game state logging no longer attempts to log missiles that don't exist #1227
- Positional sound attenuation effect increased #1226
- Sounds play on remote clients #1224, #1225
- Weapon tubes no longer desync on load/unload #1048
- Black holes confirm whether an object still exists before trying to move it #1180
- Discord library issue blocking Linux builds #1000
- Ship templates now have and use a default AI
- Scenario and ship template typos #1156, #1157
- Pathing algorithm now accounts for ship size to better avoid mines and asteroids
- French translation of space station templates #1151
- _Escape_ scenario messages and buttons now appear for Engineering+ screen #1286
- Bugs in _Scurvy Scavenger_, _Borderline Fever_ scenarios #1284

## [2020-11-23]

### Added

- Updates in the script reference documentation
- More variations of the "Adder" ship line and new frigates
- Mission settings can be read from scripts (like `areBeamShieldFrequenciesUsed()`, etc.) #1038
- New AI "evasion" for unarmed transports which tries to avoid enemies #1092
- `scripts` directory README #1094
- Scenario scripts can be compiled with LDoc to generate documentation #923
- Scan probes, jump drive ranges added to GM tweak menu
- New translations
  - German translation #1086
  - Initial Italian translation
  - Czech UI translation
- API functions
  - `getSectorName()` that can be called without needing a SpaceObject #1095
  - `getEEVersion()` returns the EE release version
  - `Zone:getLabel()` #1097
  - `ScanProbe:getLifetime()` and `ScanProbe:setLifetime()`
  - `CpuShip:orderRetreat()` #1089
  - `ElectricExplosionEffect:setOnRadar()` and `ExplosionEffect:setOnRadar()`
- New scenario _Scurvy Scavenger_

### Changed

- Missiles and nukes explode at the end of their lifetime #689
- Nukes and EMPs try to avoid areas
- Control code is no longer case sensitive
- Ships without beams will try to restock their missiles when they run out
- All transport ships use the new AI "evasion" by default
- Alerts are now centered in their UI container #1105
- Comms scripts refactored, edited, and reformatted #992, #1117
- UI optimized for ships with only front shields
- UI improved for navigating database entries in Science
- Scenario selection UI scrolls to last selected scenario #1018
- Scenario updates
  - _Deliver Ambassador Gremus_ updated to version 4 #1107
  - _Defender Hunter_ updated #1109
  - _Delta Quadrant Patrol Duty_ updated #1111
  - PvP scenario with bug fixes, script reformatted #1116, #1119
  - _Borderline Fever_ updated to version 5 #1120
  - _Capture the Flag_ updated to version 1.7
  - _Basic_, _Quick Basic_ refactored

### Fixed

- Aim lock is now working with auto rotate
- Hull strength is rounded up before it is displayed to avoid ships with `0` health #1099
- Hacking difficulty and selected games are stored #1011
- `BlackHole`s and `WormHole`s no longer affect `Zones`, `Beams` and `ElectricExplosions`
- Scenarios with the same file name as a default scenario don't show up twice #1010 #1081
- Won't attempt to spawn repair crew into ships with no rooms #1100

## [2020-08-25]

### Added

- `SpaceShip:hasSystem()`
- `SpaceShip:getTubeLoadTime()` and `SpaceShip:setTubeLoadTime()

### Fixed

- fix a crash on restarting due to an invalid iterator in the database

## [2020-08-07]

### Added

- Script function `commsSwitchToGM()` that allows to switch to a GM chat in comms
- translations added to ship templates and station names
- french translation
- `ShipTemplate::getLocaleName()`
- Script function `getScenarioTime()` allows to retrieve the game time
- Science database can be filled and edited from within scenarios. Additional methods have been added to the Lua API
  - `destroy()` can be used to remove selective entries or the whole pre-filled database from within scenarios
  - `getScienceDatabases()` returns a table of all databases at the root level.
  - sub entries can be traversed with `getEntries()` and `getEntryByName()`
  - key value pairs can be inquired and manipulated through `setKeyValue()`, `getKeyValue()`, `getKeyValues()` and `removeKey`.
  - `queryScienceDatabase()` allows to easily query for deeply nested entries
- Science database entries allow to display an image `ScienceDatabase:setImage()`
  - The image files have to be available on all clients in order to be displayed.
- more descriptions in the script reference
- allow to set a callback function when a new player ship is created on the ship selection screen `onNewPlayerShip`
- `allowNewPlayerShips()` can be used in scenarios to disable ship creation from ship selection screen
- tube size can be changed by GM
- GM tweak menu has been updated and is now able to modify much more settings
- GM can create VisualAsteroid, Planet and Artifact
- GM can create Player ships
- GM can limit the maximal health of a system
- added script functions `SpaceShip:setTubeSize()` and `SpaceShip:getTubeSize()`
- added the option to set hotkeys to reset system power to 100% or other discrete values
- added `SpaceShip::getJumpDriveCharge()` and `SpaceShip::setJumpDriveCharge()`
- added `SpaceShip:getAcceleration()` and `SpaceShip:setAcceleration()`
- Scenario "Unwanted Visitors" added
- added `SpaceShip:getDockedWith()`
- added `SpaceShip:getSystemHackedLevel()` and `SpaceShip:setSystemHackedLevel()`
- script function `onGMClick()` is capable of capturing GM click locations
- new file `ee.lua` that has constants for the most enums
- ships can repair and restock missiles on docked ships (`setRepairDocked()`, `setRestocksMissilesDocked()`)


### Changed

- Science database entries are sorted alphabetically.
- Minimum MacOS compatibility version has been set to `10.10`
- scrollbars are hidden if all text fits on screen
- layout of the science database was changed
- `local` is used more in all lua scripts
- the last selected scenario is pre-selected when exiting a scenario
- assets from `HOME` directory are read before `RESOURCE_BASE_DIR`
- missiles can not be fired during warp
- radar rotation option is also used by operations and single pilot

### Fixed

- _Ready_ button can no longer be clicked without having a ship selected
- Translations with context are no longer ignored #879
- calculate energy drain of the warp drive by its actual speed
- it is no longer possible to warp instantly out of a backwards movement
- entered IP addresses in the server browse menu are stripped of whitepaces
- fixed misplacement of the red/yellow alert overlay on split screen #902
- the `util_random_transports.lua` now selects all possible transports
- planets generate valid lua code again when exporting
- GM messages are deleted on mission resets
- `WormHole::onTeleportation()` is called for all SpaceObjects, not just ships
- Wormhole effect is no longer visible after exiting the wormHole
- beam positions for `battleship_destroyer_5_upgraded` fixed


## [2020-04-09]

### Added

- Options menu settings to allow radar views on Helms, Weapons, and Science stations (and their derivative crew 3/4 stations) to rotate around the player ship, instead of the ship rotating within the radar view.
- Adjustable and customizable impulse engine sounds.
  - Options menu settings for enabling impulse engine sounds across all stations, main screen only, or disabled, as well as setting its volume separate from master sound and music.
  - `setImpulseSoundFile()` ship template function to set a custom engine sound.
  - Default impulse sound moved from `resources/engine.wav` to `resources/sfx/engine.wav`.
  - New engine sound for the MP52 Hornet.
- Power Management station keybindings, sharing Engineering's.
- `SpaceShip::setWarpSpeed()` scripting function to set a ship's speed per warp level.
- Optional control code for the Spectate station.
- Translation markers added to many more game features, including player stations and weapon names.
- Custom functions added to Ship Log screen.
- `autoconnect_address` option to specify a server to autoconnect to, instead of relying on server autodiscovery.
- Toggleable player ship capabilities in ship templates, scripting, and the GM tweak menu: scanning (`canScan()`), hacking (`canHack()`), docking (`canDock()`), combat maneuvering (`canCombatManeuver()`), self destruction (`canSelfDestruct()`), and probe launching (`canLaunchProbe()`)
- `set` and `getSelfDestructDamage` and `SelfDestructSize` scripting functions to modify player ship self-destruction explosion size and damage.
- Probe radar radius is now visible on the GM screen.
- Mission clock on Relay and GM screens counts up from 0 seconds at the start of each scenario. Ship's Log UI is now also synchronized to this clock for consistency.
- `SpaceObject::onDestroyed()` callback when an object is destroyed, even if not by damage.

### Changed

- Reducing coolant in a system distributes it automatically to other systems, even if they are all empty.
- Warp drive energy usage scales to system damage and power level.
- Options menu is paginated to accommodate additional options.
- Black holes do even more damage closer to their center; more objects sucked into a black hole should be destroyed by damage and trigger the appropriate callback.
- Borderline Fever scenario refactoring
  - Added expedite dock function to Relay, added show player ship details on player console, added enemy behavior change option, reorganized GM buttons, GM buttons to display player ship details, take advantage of resizable asteroids by randomly resizing them, Added cartography office to relay for stations when docked, added possibility to revive repair crew, added possibility to recover lost coolant, handle rare nil case for angle of attack, reduce average size of warp jammer range
- Delta Quadrant Patrol Duty scenario refactoring
  - Add status summary to relay screen, Localize variables, Take advantage of resizable asteroids through randomization, fix beam presence recognition code, Add goods randomization arrays, Add list of player ship names for Crucible and Maverick as well as set up code, fix check for warp drive presence on player ship, fix placement of station Research-19, Change station Maverick to Malthus, Switch to placing station data in comms_data structure, fix transport handling, Add cartography office, fix Kojak mission, remove old diagnostic code, simplify freighter cargo interaction, fix reference to global getLongRangeRadarRange (deprecated), add chance for repair crew to be revived
- Defender Hunter scenario refactoring
  - Move constant definitions to their own function, Fix player ship beam determination code, Add goods randomization tables, move station placement function list creation to its own function, localize variables, move station data to comms_data structure, take advantage of resizable asteroids through randomization, add possibility of repair crew revival, add possibility of coolant recovery
- Escape scenario refactoring
  - Update goods handling, switch to putting more data in comms_data structure for stations, add use case for another set of debris, make asteroids vary in size at random, add freighter communication options, add more junk yard dogs, add more harassing Exuari during repair journey, add Engineering messages when max repairable health reached

### Fixed

- Tutorial no longer crashes when started.
- Missile tube sizes and HVLI projectiles are properly replicated to clients.
- Warp/glitch shaders no longer affect paused games.
- Persistent scripting storage (ie. `ScriptStorage.get()`) is no longer wiped upon load in a new EE instance.
- Engineering station no longer sometimes crashes while loading.
- Fixed some situations that could cause crew screens to crash when selecting Main Screen controls on Linux builds.
- Ship's Log screen no longer overlaps some station selection controls.
- Destroyed player ships no longer persist and appear multiple times in the ship selection screen.
- Joystick event handling no longer results in crew stations persisting after a player exits them.
- When the window is resized, the rendered area no longer shifts out of the window's bounds when warp/jump/glitch effects occur.

## [2020-03-22]

### Added

- Localization functions.
- Mappable joystick controls.
- Push-to-talk voice chat using opus.
  - Server chat is mapped to the Backspace key.
  - Same-ship crew chat is mapped to the Tilde (~) key.
- `proxy` and `serverproxy` preferences to run an EmptyEpsilon instance as a
  proxy or reverse proxy server.
- `getScriptStorage()` scripting function to access persistent data storage,
  and `:get()` and `:set()` functions to retrieve and add or modify it.
- `setColors()` and `getColors()` GUI functions, and R/G/B color profiles, for
  GuiButtons.
- `SpaceShip:getDynamicRadarSignatureGravity()`, `...Electrical()`, and
  `...Biological()` scripting functions.
- Shield generator frequency selector to Engineering+.
- Strategic Map (Relay without comms), Comms Only (Relay without map),
  and Spectator (GM without editing) stations in the alternative/extras
  category.
- GMs can tweak coolant and short/long-range radar range on player ships.

### Changed

- Long-range radar range (and short-range radar range) are now per-ship
  settings, rather than server-wide. Long-range radar range option no
  longer appears on the scenario selection menu.
  - `get...`, `setLongRangeRadarRange()` and `setShortRangeRadarRange()`
    scripting functions added to ShipTemplate and PlayerSpaceship.
- Clients set a username on the main menu, which also appears in the ship
  selection screen.
- DB button for targeted ship information appears to the left of the info
  on the Science and Operations stations.
- Callsigns appear on the cinematic view.
- Android always uses landscape mode.
- Fixes to patrol duty scenario.
- `instance_name` now also appears in the window title.

### Fixed

- OpenGL crash issue with mesh views.
- Alignment of touchscreen calibration button text.

## [2020-02-18]

### Added

- `ScanProbe:onExpiration()`, `ScanProbe:onDestruction()`, and
  `PlayerSpaceship:onProbeLaunch()` callback scripting functions.
- Scan object (`s`) and cycle objects not yet fully scanned (`c`) hotkeys
  added to Science and Operations.
- `Artifact:setSpin()` scripting function.
- Scripting reference docs for SpaceObjects.
- Beam frequency and system target selectors added to the Tactical station.
- `pauseGame()` and `unpauseGame()` scripting functions.
- `startpaused` option for `headless` servers.
- A simple Discord bot, located in `/discordbot` within the git repository.

### Changed

- Moved shield calibration hotkey configs in the preferences file from
  Engineering to Weapons. **This is a breaking change** if these hotkeys
  are already set in the preferences file:
  - `SHIELD_CAL_INC`
  - `SHIELD_CAL_DEC`
  - `SHIELD_CAL_START`
- Radar signatures for AI and player ships change dynamically based on
  ship activity, such as impulse power and jump drive activation.

### Fixed

- `Asteroid:setSize()` now works as expected.
- Pathfinding objects that start a scenario on the same coordinates are no
  longer flung millions of units away when the game is unpaused.
- Hacking settings are now replicated to clients.
- Raw radar signature waveforms when objects are beyond long-range radar range.
- `headless` servers no longer attempt to use or require graphics.

## [2020-01-15]

### Added

- Crucible corvette-class popper ship.
- Maverick corvette-class gunner ship.
- Terran Stellar Navy (TSN), United Stellar Navy (USN), and Celestial Unified
  Fleet (CUF) factions.
- `SpaceShip:setScanState()` and `SpaceShip:setScanStateByFaction()` scripting
  functions.
- `Planet:getPlanetRadius()` and `Planet:getCollisionSize()` scripting
  functions.
- `Mine:onDestruction()` callback scripting function.
- Planet radius in the game state log and viewer, and to GM screen script
  exports.
- Standalone Ship's Log view, moved from the Single Pilot station to Extras.
- `registry_registration_url` and `registry_list_url` settings in options.ini,
  to point at a custom Internet master registry server. Only `http://` URLs are
  allowed. For an example master server, see the `masterserver` directory in
  `daid/SeriousProton`.

### Changed

- _Shoreline_ and _Borderline Fever_ scenarios refactored to fix errors and add
  enhancements.
- Slowed down Hue lighting updates and added transition channel.
- Removed an extraneous ZIP from the build.
- Ship and target passed to the comms script interface.

### Fixed

- Crashes when the server port is already in use.
- Missing radar trace images for ships.
- Typos in scenarios.
- Carrier ships (ships that are docking targets) attempting to dock with
  themselves, preventing them from being able to dock with stations or other
  docking targets.
- Crashes caused by excessive recursion in the AI path planner.
- Game completion condition for the Minesweeper hacking game.

## [2019-11-01]

### Fixed

- Downgrade drmingw from 0.9.2 to 0.8.2 in order to avoid DLL issues on Windows 7.

## [2019-10-28]

### Added

- Hacking minigame refactored with difficulty selector. #683
- Engineering can mitigate and repair hacking.
- `BeamEffect` scripting functions:
  - `BeamEffect:setSource()` and `setTarget()` for targeting.
  - `setTexture()` and `setRing()` for visualization.
  - `setBeamFireSound()` and `setBeamFireSoundPower()` for audio.
  - `setDuration()`
- `SpaceShip:getBeamFrequency()`, `PlayerSpaceship:getBeamSystemTarget()`, and `PlayerSpaceship:getBeamSystemTargetName()` scripting functions.
- `self_destruct_countdown` length in seconds is now configurable in options.ini.
- `ship_window_flags` setting in options.ini to configure space dust, headings, and callsigns on window views.
- _Allies and Enemies_ scenario.

### Changed

- Improve missiles:
  - Missiles can have a size.
  - Missile size affects speed, turn rate, and radar icon size.
  - Damage and particle effects can now scale.
  - Ships can have missile tube sizes.
- Last server connection is remembered after being disconnected. #624
- "All" tutorial is listed first. #698
- _Borderline Fever_ scenario updated to use new scripting features.
- Circles designating warp jammer areas are now red if controlled by an enemy or orange if not. #704

## [2019-09-10]

### Changed

- Custom ship function caption updates can now refresh.

### Fixed

- Build the Windows package in CI.

## [2019-09-09]

### Added

- Progress sliders as a GUI control.
- `setRestocksScanProbes()` and getter scripting functions for configuring ships and stations.
- `setMaxCoolant()` and getter scripting functions to modify the total coolant available to Engineering/Power Management.
- GM screen allows modifier keys:
  - `Shift` adds objects to the current selection
  - `Ctrl` only selects stations and ships
  - `Alt` only selects objects from the same faction as the faction selector
- GM screen message overlay.
- tinyci implementation.

### Changed

- Can press Enter to connect after entering a server's IP address. #627
- Passwords are no longer case sensitive. #657
- Password field focus point is now visible. #626
- F1 help overlay shows modifier keys.

### Fixed

- Prevent compilation failures in Hue lights counter. #648
- Sun appears correctly on clients in the _Empty Space_ scenario. #651
- Avoid crashes when a ship is destroyed on the same tick as firing a beam. #622
- Fix a distance calculation issue.
- Copied ship templates report correct impulse acceleration and combat maneuver stats.
- Fix GL blackout issue on main screen and ship windows. #649

### Removed

- Code::Blocks project file removed in favor of CMake.

## [2019-05-21]

### Added

- _Borderline Fever_ scenario.
- _Capture the Flag_ scenario.
- _Escape_ scenario.
- More features for Hue light controls.
- `warp_post_processor_disable` flag in options.ini to disable warp effects. #636

### Changed

- Remove headings and callsigns from ship window views.
- Clarify dangers and variation descriptions in the _What the Dickens_ scenario.
- Convert scenario audio to OGG format.
- Code::Blocks project file updated.
- Add Maverick ship type and minor fixes for the _Defender Hunter_ scenario.

### Fixed

- Avoid a crash when calling `isEnemy()` or `isFriendly()` on a destroyed object.
- Planets can no longer hide in nebulas.
- Rear shield info no longer shows front shield damage reduction.
- Typos in scenarios.

## [2019-01-19]

### Added

- _What the Dickens_ scenario and audio resources.
- `getFiringSolution()` script method for calculating missile trajectories.
- Additional weapon sounds.
- `onTakingDamage()` and `onDestruction()` scripting event listeners added to `shipTemplateBasedObject`s and warp jammers.
- `onTeleportation()` scripting event listener added to wormholes.

### Changed

- GM actions management refactored.
- Improve _Defender Hunter_ scenario behaviors when played on a headless server without a GM pause.
- `onPickUpCallback()` script function renamed to `onPickUp()` and extended to SupplyDrop objects.

### Fixed

- Button state issues.
- Systems actually degrade when energy drops to critical levels.
- Issues with the _Birth of Atlantis_ scenario, including a potentially broken trigger and larger warp jammer ranges. #584
- Serial port configuration on Linux.

## [2018-11-16]

### Added

- _Carriers and turrets_ scenario and ship resources.
- _Defender Hunter_ scenario and audio resources.
- _Patrol Duty_ scenario and audio resources.
- _Close the Gaps_ scenario and ship resources.
- `Wormhole:getTargetPosition()` scripting function.

### Changed

- Upgrade SFML to 2.5.
- Update CMakeLists.
- `Artifact` object pickups can emit a callback.

### Fixed

- Improved display of disabled system damage.
- Typos in tutorials and database.
- Ships in formation don't unintentionally dock with stations.
- _Beacon_ scenario now uses `mission_state`. #582
- GL state lifecycle bug.

## [2018-09-06]

### Added

- `Zone()` scripting function for colored, labeled zones. #529
- _Shoreline_ scenario.
- _Fermi 500_ scenario.
- Callsigns for GM comms.
- `variation` scenario setting for headless servers.

### Fixed

- Small bugfix on finding MINGW DLLs.
- DMX: Fix E1.31 DMP layer packet octet 118 value.
- Typos in scenarios.
- Custom button placement in station GUIs.
- Radar overlay on macOS no longer blacked out.

## [2018-02-15]

### Added

- _Deliver Ambassador Gremus_ scenario.
- Scripts can set CpuShip orders.

### Changed

- Clean up the GUI code.
- SpaceObject:takeDamage allows setting the origin, frequency and system_target.

### Fixed

- Different approach to prevent the radar from capturing clicks. #498

## [2018-01-05]

### Changed

- Allow spawning explosions from scripts.

### Fixed

- Hang on start of tutorial with no tutorial selected.
- Add DMX cues for system status. #506

## [2017-12-25]

### Changed

- Make lower sector naming more logical.
- Reduced the amount of debug symbols in release builds.

### Fixed

- Custom buttons for single pilot ships.
- Case of OpenAL32.dll filename to match what was generated by the openal-soft sources.

## [2017-12-22]

### Added

- Compiler optimization flags.
- Attempt to make Philips Hue hardware work.
- Script function to play sound files on the server.

### Changed

- Pacing for beam aiming practise.
- Select selectable objects instead of targetable.
- Blackhole text in regard to escaping with different types of engines.
- Moved hardware devices to a separate directory.

### Fixed

- Rendering of far away planets.  Now done in multiple passes.
- Ship template was updating the wrong template. Fixes #494
- Tutorial correctly states that hull is only repaired when docked. Fixes #495
- Typos
- Custom fuction being removed before getting called. Fixes #501
- Missile Volley AI never firing. Fixes #500

### Removed

- `GameMasterUI` class. Issue #491

## [2017-11-03]

### Added

- Game Master slides to control combat speed.
- Random object creation helper functions.
- Joystick controls for single pilot screen.
- Weapon hotkeys for tactical and single pilot screens.

### Changed

- Can set a description on each object based on scan state.
- Darken screen when your ship is destroyed.

### Fixed

- (Possibly) Crash on the relay station when your ship is destroyed.
- Main screen buttons properly reset state on target follow selection.
- Spelling on _Birth of the Atlantis_ scenario.
- `TOGGLE_AIM_LOCK` will only work if button state is properly set.

## [2017-05-06]

### Added

- Number of hotkeys for the tactical, engineering+ and single pilot screens.
- Hotkeys to navigate between the screens
- Attempt to disable screen saving when netbooting
- "Can be destroyed" flag for ship objects
- 3D sprite for black hole
- script function to set the number and maximum of probes

### Changed

- Adjusted the tutorial

### Fixed

- Typo in the tutorial
- Communication dialogs not opening for second time on Game Master screens
- Options.ini diffusion

## [2017-02-23]

### Added

- Tutorial menu
- Default hotkeys
- F1 shows the available hotkeys

### Changed

- Re-factored the all tutorial into individual stations

### Fixed

- Joystick bug that allowed the combat power to cool down while moving backwards

## [2017-01-19]

### Added

- 5U circle around players on the Game Master screen
- Target drone for the quick basic scenario to practice firing missiles
- `setShieldFrequency` function
- `getEnergy`/`setEnergy` functions that take `max_energy_level` into consideration
- CMake error if `DRMINGW_ROOT` is not set

### Changed

- Improved callback handling to prevent closures from being deleted while in use
- Renamed shield system to shield generators
- Timing of rescue ship in _Beacon of Light_ scenario

### Fixed

- Operations screen not being able to select things
- Set `RESOURCE__BASE__DIR` to fix missing resource directory when compling on FreeBSD
- Null pointer exception in getSystemHealth

## [2016-09-02]

### Added

- Operations tutorial (disabled)
- Option to loop tutorials from the command line
- Reset button when the tutorial is looping
- variant of the basic scenario that waits for the game master to start it so crews can get used to the interface
- Fully scanned ships now show frequencies and subsystem status in the science screen sidebar pages
- Scanned targets subsystems are colored red when damaged
- Ship control codes, which prevent a player from selecting a ship without the correct code
- `setControlCode(string control_code)` to add a control code to a ship via script or template
- Player page for the game master tweaks panel, to set control codes, see energy levels and manned stations
- Show the effectiveness of the beam subsystem on the Engineering screen (effects the rotation speed)
- Place/delete waypoints from the Operations screen
- Sound volume can be set in the options
- Help overlay and keyboard hotkey display
- Basic build instructions
- Relay can hack ship subsystems
- Planets can orbit other objects
- Scrolling banner of information for the cinematic screen
- Show planets in the 3D world

### Changed

- Adjusted the nebula in the basic scenario
- Avoid spawing asteroids on the player start position
- Game master friendly spawned ships are already scanned when created
- Expanded utils.lua (more documentation, `setCirclePos` and `vectorFromAngle`)
- Avoid spawning black holes too close to stations in the basic scenario
- Updated fighters and advanced gunships to the new template
- Systems become degraded when low on power (< 10%)
- Increased the height of the frequency graphs for better contrast
- Radar signatures can be referenced in scripts
- Game masters can change object callsigns and descriptions
- Replaced the hotkey system with something better
- Revised the options menu
- Improved the cinematic screen

### Fixed

- Prevent bad use of faction friend/foe calls from crashing the game
- Game crashed if the game master presses a button that is removed durring event handling
- Calls for reinforcements were impeded
- Science screen from overlapping or running off the bottom edge of the screen
- Orders not showing on the game master screen
- Text entry fields #373

## [2016-06-24]

### Fixed

- Fix issues preventing JC-88 from jumping in the _Birth of Atlantis_ scenario
- Initialize beam and turret arc values to fix crashes when drawing beam arcs on Odin dreadnoughts

## [2016-06-23]

### Added

- New scenarios
    - Quick Basic scenario (for quick setup and with a time limit)
    - The _Birth of Atlantis_ scenario, with less combat and focused more on features
- New ships and ship options
    - Jump Carrier ship template, capable of quickly carrying docked ships across extremely long distances
    - Maximum jump drive distance configurable per ship (`setJumpDriveRange()`)
    - Beam turrets, an option to make beam weapons rotate within an arc (`setBeamWeaponTurret()`)
    - Stations repair the hull of any docked ship
    - Flag to toggle whether ships and stations share energy with docked ships (`setSharesEnergyWithDocked()`)
    - Option for player ships to have automatic coolant distribution (`setAutoCoolant()`)
- New sounds
    - Self-destruct sequence
    - Shields up/down
- New Game Master screen features
    - Player ships' radar range indicators
    - Button to copy Lua script lines for selected objects to the clipboard
    - Option for the Game Master to intercept and respond to all player hails
    - Player ship selection on the game master screen
- New Engineering(+) screen features
    - Show the effects of boosting subsystem power
    - Flashing overheating warning icon
- New Science/Operations screen features
    - Target's hull information
- New Tactical screen features
    - Combat manuever controls
- New Relay/comms features
    - Ship's log overlay, which replaces the log screen
    - Colors for ship's log entries
- New spectator views
    - Top-down 3D view UI to follow a player ship (press <kbd>H</kbd> to expose UI)
    - Cinematic view; fly-by camera that follows player ship, with optional target lock. Same keyboard controls as top-down 3D view
- New main screen controls
    - Overlays can be displayed on the main screen
    - Target lock view, selectable if a player has a weapons station and main screen controls
    - Comms windows on main screen, selectable if a player has a comms station
- Game log and log viewer features (`/logs/index.html`)
    - Show the probe radius
    - Zoom slider
    - More faction colors
    - File picker input
    - Log station factions to game state log
- New scripting features
    - Scripts can move player crew positions (`transferPlayersToShip()`, `transferPlayersAtPositionToShip()`) and check if a station is occupied (`hasPlayerAtPosition()`)
    - Scenario type identifiers
    - Scenario descriptions can span multiple lines
    - `utils.lua` function to create a grid of objects
- Search list for Linux serial devices
- On-screen keyboard for text communications on touchscreen devices

### Changed

- AI
    - AI ships refill missiles when docked at a station
    - AI takes advantage of non-standard jump drive ranges
- Crew station interfaces
    - Alert overlay size reduced
    - Edges of warp jammers are more obvious
- Weapons/Tactical station interfaces
    - Aim lock buttons moved
    - Weapon tube control width reduced
- Relay station interface
    - Distant sector designations improved
    - Database view margins standardized
    - Change Relay's zoom control to a slider
- Science/Operations station interface
    - Synchronize the Science/Operations screen's zoom slider behavior with the mouse wheel zoom
    - Adjust Science station layout to avoid overlaps
    - Adjust Science info sidebar's database lookup button size and position to avoid overlap
    - Move Operations screen communication buttons to avoid overlapping the radar
- Engineering(+) station interface
    - Only show combat recharge modifier on Engineering screen's Maneuverability subsystem if the ship has combat maneuvers available
    - Engineering subsystem bars are more visible
    - Moved shield buttons on Engineering+ screen to avoid overlap
- Ship selection screen interface
    - Show which crew stations are occupied by players
    - Show how many players occupy each ship
    - Changed Ship Window angle selection to a slider
    - Changed selectors with only two options into toggle buttons
    - Show server's long-range radar range in U instead of raw values
    - Reworded headings and buttons
- Scripting
    - Moved callsigns and `setCallSign()` to _spaceObject_, allowing scripts to assign callsigns to any object
- Game state logging (`/logs/`) and log viewer (`/logs/index.html`)
    - Draw non-ship objects as circles
    - Sector designations
    - Moved the scenario loading code out of the scenario selection screeen
    - Show ship and station factions
    - Reset coordinates when loading a log if they are not a number
    - Move game state logging from server creation to start of scenario
    - Scale objects with zoom
    - Cap mouse wheel changes to avoid breaking the zoom
- Ships and ship options
    - Player ship hulls strengthened
    - Repair speeds increased slightly
- Expand and restyle the HTTP API sandbox (`/www/index.html`)
- Auto connect selects on filters rather than index

### Fixed

- Crew station interfaces
    - Missile tube state changes are more accurately reflected on the Weapons screen
    - Sector name rendering at edge of radar improved
    - Communications "OK" button doesn't overlap notification text
- Expand slider ranges on Game Master screen's Tweak UI
- Game state logging (`/logs/`) and log viewer (`/logs/index.html`)
    - Operations screen's communication buttons from appearing in the database view
    - Autoplay on game state log viewer
    - Game state logger performance
- Resolve issues with the weapons phase of the tutorial
- When exiting a scenario while using auto-connect, return to the auto-connect screen instead of ship selection
- Setting `on_value` on hardware blink effects

### Removed

- Swear words from communication scripts
- Text from red/yellow alert overlays

## [2016-06-02]

### Added

- New web folder content (`/www/index.html`)
    - HTTP API examples and sandbox
- Game state logs (`/logs/`) and log viewer (`/logs/index.html`)
    - Basic log viewer using HTML and Javascript
- Top-down 3D spectator view controls
    - Top-down controls for zooming (<kbd>R</kbd> and <kbd>F</kbd>) and panning (<kbd>WASD</kbd>)
    - Lock camera to player ships with <kbd>L</kbd>
    - Select player ships with <kbd>J</kbd> and <kbd>K</kbd>
    - GUI controls; visibility toggled with <kbd>H</kbd>
- Game Master screen interface features
    - Button to copy Lua script lines for all objects to clipboard
    - Buttons to create an asteroid or supply
- Single Pilot interface features
    - Combat manuever controls
- Helms station interface features
    - Missile tube indicators for helm
- Science station interface features
    - Raw scanner overlay on probe view
    - Button to open the Database view for the targeted ship
- Weapons station interface features
    - Icon for HVLI ammo
- Music features
    - Music playback on clients
    - Option to toggle music playback; defaults to play music only on Main Screen clients, with options to always or never play music
- Faction communications for Ktlitans
- AI ships include missile counts in status reports
- Basic logging of model pack contents

### Changed

- Game Master screen
    - Ship Tweak UI elements standardized
    - Tweak UI's speed slider range expanded to 35
    - Missile storage capacity and amount converted to sliders
    - Warp and jump drive toggles converted to toggle buttons
- Engineering station interface
    - New Engineering ship room background
    - Shields reduce more damage when overpowered
- Ships and ship features
    - When a ship takes hull damage, damage only 1 random subsystem instead of 5
- Helms/Tactical/Single Pilot station interface
    - Combat maneuver control is a two-dimensional rectangle instead of two sliders, allowing boosting and strafing at the same time
- Weapons/Tactical station interface
    - Improved the weapons UI when the shield frequency feature is disabled
- Replaced `std::stoi` calls with `toInt()` for consistency
- Standardized Database screen margins and distance between elements
- Ship and station communication scripts edited

### Fixed

- Window title is "EmptyEpsilon" on all platforms
- Communications button usable on Single Pilot screen
- Game state logging (`/logs/`)
    - Log information on stations
    - Game state log entry converted to Boolean
    - Small fixes to the game state logger
- Correctly modify player ship in _Edge of Space_ scenario
- Fix system-to-shield connection on ships with more than 2 shields

## [2016-05-22]

### Added

- Station descriptions
- Name of missile tube on the firing button
- Show the "ship destroyed" dialog even if the game is paused
- Game state logging (`/logs/`)
    - Log the game state to JSON during gameplay for post-game analytics
- Ships and ship options
    - Flavia and Flavia Falcon light transport frigate, to replace the deprecated tug
    - Player variant of the Flavia (Flavia P.Falcon)
    - Starhammer II corvette ship template
    - Player variant of the Piranha frigate ship template
    - Defense platform ship template, to replace deprecated weapons platform
    - Ship templates to replace strikeship and advanaced striker
    - Beam weapon and engine emitter positions on some models
    - Extra set of 3d models for use as frigates
- Headless server options
- Allow tweaking weapon tube details and availability at load time
- Allow game master to change a ship's callsign

### Changed

- Scenarios
    - Use new ship templates in scenarios
    - Use new power/coolant request functions in the tutorial
- Crew station interfaces
    - Reduce alert overlay
- Science Database content
    - Add faction descriptions to Science database
    - Moved descriptions in the database to the rightmost column
    - Add ship descriptions
- Weapons/Tactical station interface
    - Label directional facing of weapons tubes
- Relay station interface
    - Waypoints can be dragged to change their position
    - Limit number of waypoints to 9
- AI
    - Prevent AI from firing missiles on scan probes
    - Improve AI missile behavior
- Ships and ship options
    - Adjust model sizes
    - Adjust beam weapon ranges
    - Allow scripts to set the number of repair crews in a ship template
- Use `pngcrush` to reduce file sizes

### Fixed

- Parts of the tutorial failing to appear
- Docking hardware event
- Iterating over the `small_objects` map doesn't modify it
- Ready button's enabled state on ship selection screen
- HVLI fires in correct direction
- Nebula positioning

## [2016-05-07]

### Added

- Try to support uDMX hardware
- Stalker sniper-type cruiser ship template
- Direction to waypoints outside radar range on Helms screen
- Waypoint color settings in `colors.ini`
- Basic scenario Game Master improvements
    - Game Master functions to manually spawn enemy waves and random allies
    - Blank variant with no enemies and no victory condition
    - Game Master functions to manually award victory
- Comments to scenario code
- Freighter ship templates

### Changed

- Clicking outside of a target on the Weapons station unselects the current target
- Reverse default order of weapon tube rows on Weapons/Tactical screens
- Shield frequency configuration moved from Engineering station to Weapons
- Power Management screen shows both the actual and requested levels of power and coolant for subsystems
- Move the alert overlay behind controls
- Docking is now defined by which classes are allowed to dock with a ship
- Improved the feedback of the "Link to Science" button on Relay
- Edit tutorial text

### Removed

- Custom ship template in the PvP scenario

### Fixed

- Friendly ship broadcasts
- Adjust ship station selection button
- hacked ships communications pointing to old script in _Ghost from the Past_ scenario
- missile AI only fires the tubes with a targeting solution
- AI only tries to jump with the drive is charged
- main screen controls
- station selection overlap
- broadcast to friendlies

## [2016-04-30]

### Changed

- Use generic distance unit (`U`) instead of kilometers/km
- Waypoint rendering
- Improve use of forward declarations
- Use a different icon for weapons tubes that can launch only mines

### Removed

- gui2.h *catch all* header

### Fixed

- Science cannot select targets when probe view is active
- Prevent multiple simultaneous communications to the same object
- Fix a compile warning

## [2016-04-28]
### Added
- icon to show missle tube direction
- corvette class ships *disabled*
- player variant of the corvette class ship *disabled*
- frigate variations *disabled*
- abort the game on script errors in important files
- ship templates can be copied
- quick debug button to show all ship models in a single overview
- all colors of the new models to the model\_data
- allow combat manuvering data to be set on active ships
- added functions to remove game master function buttons
- allow the amount of repair crew to be set per ship template and at runtime
- functions to get the current radar range
- draw the engine/tube/beam positions in the rotating model view when debugging
- allow the beam weapon energy and heat to be set per beam
- missile tubes have a direction

### Changed
- increase system power usage
- power and coolant take time to change
- append callsign when broadcasting
- msgamedev model to point in the proper direction
- slight improvement to the database view when there are lots of items
- science database uses a tree structure
- how the probe link is implemented in science
- player cruiser and missile cruiser use the directional tubes
- mines are fired in the direction of the tube
- missile path projections are only shown when loaded
- station selection from row of buttons to a drop down
- transparent wormhole images
- higher resolution blackhole image

### Removed
- custom ship templates from the _Ghost from the Past_ scenario
- obsolete functions

### Fixed
- crash when models are ot found
- slight layout
- database scroll bar overlapping with database entry
- label in game master screen for laser damage
- asking a friendlies status made it defend the player
- do not drain energy from docked ship when energy is full
- player spaceships and stations from being incorrectly reported as not used models
- margin calculations
- game master script buttons overlayed with ship orders

## [2016-04-12]
### Added
- allow the game master to close communications
- allow safe destory of GuiElements
- allow clipboard paste in text fields
- function to shutdown the game
- function to get what the game master has selected.
- examples of how to use the addGMFunction
- option to set margins on controls
- function to change the scenario to a different one.
- log to a file in windows
- allow the user to specify the serial port for DMX with or without /dev/ on linux
- server can register with the online master server
- browsing for LAN and internet servers
- server password
- 4 new ship models
- scan probe model
- logging to show which model data deinitions are not used by ship templates
- damage/power indicator for beam info
- engineering column icons
- show current frequency on the beam and shield curves in engineering

### Changed
- improve the dynamic layout of the ship selection screen for wide screens
- improve the dynamic layout of the serer start screen using the new column auto layout
- changed the default release log level to info
- use a different icon for the warp and jump drives
- server screen uses less magic numbers
- return to the scenario selection instead of closing the server
- improve science radar positions on wide screens
- improve the layout of engineering controls
- system icons updated

### Fixed
- unfocusElement which only worked for the top level element of the tree
- possibly fixes keyboard related crashes
- changes to server name were never applied
- scroll bar look
- touchscreen calibration
- main screen first person view rotating like an idiot

## [2016-04-07]
### Added
- indication that chat has changed on game master chat dialogs that are minimized
- image for the resize corner
- include ship tweaks when exporting from the game master screen with F5
- icons for _Tactical_ and _Single Pilot_
- option to tweak ships from the game master interface
- indicators ticks for power and coolant
- function to broadcast faction messages
- AI ships inform when taking new orders
- state to let the communication officer to know when the other side closed communication
- option to abort docking
- scan state for ships
- icons for each support OS
- joystick controls for 3/4 player tactical screens
- allow for direct and hex value entry
- per station settings for which weapons they supply

### Changed
- cursor blinks in text emptry field
- constrain resizable dialogs to the window
- game master can have multiple sessions
- updated icons for stations
- updated logo on the main menu
- more realistic asteroid texture
- new cursor design
- resized button icons to fit better
- round beam range on 100m intervals
- game master screen now has multiple pages
- broadcast function has three thresholds: allies, neutral, all
- new shield, hull and self destruct icons
- increased the sharpness of the skybox
- updated the star field image
- images for active/disabled/hovered buttons
- images for regular/focused text inputs
- updated colors
- alpha transparency for UI elements

### Fixed
- text centering
- shield icon using speed icon
- inverted pause button
- create button visible through the cancel button on game master screen
- clicking outside the radar circle but inside its reactangle caused callbacks

[Unreleased]: https://github.com/daid/EmptyEpsilon/compare/EE-2018.02.15...HEAD
[2018-02-15]: https://github.com/daid/EmptyEpsilon/compare/EE-2018.01.05...EE-2018.02.15
[2018-01-05]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.12.25...EE-2018.01.05
[2017-12-25]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.12.22...EE-2017.12.25
[2017-12-22]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.11.03...EE-2017.12.22
[2017-11-03]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.05.06...EE-2017.11.03
[2017-05-06]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.02.23...EE-2017.05.06
[2017-02-23]: https://github.com/daid/EmptyEpsilon/compare/EE-2017.01.19...EE-2017.02.23
[2017-01-19]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.09.02...EE-2017.01.19
[2016-09-02]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.06.24...EE-2016.09.02
[2016-06-24]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.06.23...EE-2016.06.24
[2016-06-23]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.06.02...EE-2016.06.23
[2016-06-02]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.05.22...EE-2016.06.02
[2016-05-22]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.05.07...EE-2016.05.22
[2016-05-07]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.04.30...EE-2016.05.07
[2016-04-30]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.04.28...EE-2016.04.30
[2016-04-28]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.04.12...EE-2016.04.28
[2016-04-12]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.04.07...EE-2016.04.12
[2016-04-07]: https://github.com/daid/EmptyEpsilon/compare/EE-2016.02.29...EE-2016.04.07
