docking-bay -- new crew station
utility-beam -- new ship system
multiple-waypoint-routes
gm-timescale
faction-db-button
docking-request-menu
scriptable-hacking-difficulty

generic-scrolling-guicontainer 20260410 -- major changes to scrolling elements
guiscrollcontainer-customshipfunctions 20260410
guiscrollcontainer-guilistbox 20260410
guiscrollcontainer-guiselector-popup 20260410
gm-tweaks-parity-guiscrollcontainer 20260410 -- major changes to GM tweaks
refactor-help-overlay 20260410
fix-strict-compilation 20260410
fix-warnings 20260410
fix-position-attribute 20260410
2761-science-binds 20260410
2762-relay-binds 20260410

2848-2849-2850-refactor-player-transfer 20260411
refactor-comms-overlay 20260411
2703-target-cycle-keybinds 20260411
gm-orders-layout 20260411
gm-screen-short-range 20260411
expand-gm-info 20260411
show-missiles-on-gm 20260411
export-more-entities 202604011
search-fields 20260411
2712-cap-free-overpower 20260411
hotkeys-remapping-with-dialog 20260411 -- major changes to hotkeys
gm-create-tweak-missile 20260411 -- new scripting API
new-sp-line-drawing 20260411 -- major changes to all drawLines
on-scan-callbacks 20260411 -- new scripting API
disable-multimonitor-mouse-capture 20260411
default-wayland 20260411 -- change to SDL2 default behavior
171-banking-on-rotation 20260411
trixie-pxe 20260411
modulated-illumination -- new scripting API
2563-autocoolant-overload 20260411
refactor-guiprogressbar 20260411
reparent-gui-elements 20260411
power-management-layout 20260411

on-link-callback-order 20260412
docking-bay 20260412 -- remerge
utility-beam 20260412 -- remerge
on-scan-callbacks 20260412 -- remerge
refactor-guiprogressbar 20260412 -- remerge
gm-tweaks-parity-guiscrollcontainer 20260412 -- remerge
new-sp-line-drawing 20260412 -- remerge

master 20260417 -- remerge
script-command-todos 20260417
tweak-script_docs 20260417
fix-hover 20260417 -- patch required to handle GuiScrollContainer hover

prometheus-metrics 20260418 -- major networking, HTTP server changes
multiple-waypoint-routes 20260418

docking-bay 20260419

prometheus-metrics-applied 20260421 -- major networking perf changes
gm-timescale 20260421
utility-beam 20260421
docking-bay 20260421
multiple-waypoint-routes 20260421
hotkeys-remapping-with-dialog 20260421
guitooltip 20260421

split-weapons-screen 20260423

docking-request-menu 20260430

master 20260501 -- docking-request-menu merged
force-cpp17 20260501 -- mitigate GCC 16 build issues
extra-crew-screens 20260501

extra-crew-screens 20260502 -- Drone Lua API, Sensors system

extra-crew-screens 20260503
power-management-layout 20260503

help-exit-touchscreen 20260506

extra-crew-screens 20260507 -- radar signatures, TargetAnalysis

extra-crew-screens 20260508 -- fix probe targeting on Relay, add ProbeControl hotkeys

force-cpp17 20260509 -- Fix F44/GCC 16 builds
extra-crew-screens 20260509 -- implement RadarScreen
refactor-guiprogressbar 20260509

docking-bay 20260510 -- supply drop handling

GinjaNinja32/debug-graph 20260511
extra-crew-screens 202060511 -- ProbeScreen mouse rotation, RadarScreen mode selector
oz-fork-gui2_container 20260511 -- hard forking of GuiContainer API

power-management-layout 20260514 -- spurious debug messages
master 20260514 -- 2712-cap-free-overpower merged
split-weapons-screen 20260514 -- remove shield state and controls
extra-crew-screens 20260514 -- refactor FrequencyCurve, SignalQualityIndicator
new-cinematic-camera 20260514 -- major revision to cinematic camera, addition of Camera entity

extra-crew-screens 20260515 -- refactor crew screen backgrounds

extra-crew-screens 20260516 -- rotatable drawStretchedHV, drag checks on GuiSlider
docking-bay 20260516 -- fix DockingBayScreen background if component is missing

extra-crew-screens 20260517 -- RadarScreen autorotation, AnalysisTarget component
split-weapons-screens 20260517 -- label when relevant weapon is missing

generic-scrolling-guicontainer 20260526 -- fix mousewheel passthrough when not scrolling

master 20260531 -- script-command-todos, fix-player-mine-avoidance, fix-strict-compilation
refactor-comms-overlay 20260531 -- fix autoscroll behavior on long non-chat comms messages

master 20260604 -- gm-orders-layout, expand-gm-info, dkapell:autoconectOffset

master 20260605 -- gm-screen-short-range, 2848-2849-2850-refactor-player-transfer, export-more-entities

reverse-proxy-registry 20260606 -- proxy_registry_url, proxy_registry_password
