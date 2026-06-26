#!/usr/bin/env bash
set -euo pipefail

# build-macos.sh -- native macOS build (x86_64 or arm64)
#
# Produces a distributable .dmg by downloading the official SDL2 framework,
# attaching it, and running CPack with the DragNDrop generator.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"
WORKDIR="$(pwd)"

SDL2_VERSION="2.32.10"
SDL2_DIR_NAME="SDL2-${SDL2_VERSION}"
SDL2_DMG_NAME="${SDL2_DIR_NAME}.dmg"
SDL2_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/${SDL2_DMG_NAME}"

BUILD_DIR="${EE_ROOT}/_build"
SDL2_MOUNT="/Volumes/SDL2"
SDL2_CONFIG_DIR="${WORKDIR}"
SDL2_CONFIG_FILE="${SDL2_CONFIG_DIR}/sdl2-config.cmake"

echo "==> Installing Homebrew dependencies"
brew install cmake ninja 2>/dev/null || true

echo "==> Downloading SDL2 framework DMG"
if [ ! -f "${SDL2_CONFIG_DIR}/${SDL2_DMG_NAME}" ]; then
    curl -L -o "${SDL2_CONFIG_DIR}/${SDL2_DMG_NAME}" "${SDL2_URL}"
fi

echo "==> Attaching SDL2 DMG"
if ! mount | grep -q "${SDL2_MOUNT}"; then
    hdiutil attach "${SDL2_CONFIG_DIR}/${SDL2_DMG_NAME}" -quiet
fi

echo "==> Writing sdl2-config.cmake"
cat > "${SDL2_CONFIG_FILE}" <<EOF
# sdl2-config.cmake -- points to the SDL2 framework mounted from DMG
set(_SDL2_mountpoint ${SDL2_MOUNT})
find_library(SDL2_LIBRARIES SDL2 PATHS "\${_SDL2_mountpoint}")
find_path(SDL2_INCLUDE_DIRS SDL.h PATHS "\${SDL2_LIBRARIES}" PATH_SUFFIXES Headers)
set(SDL2_FRAMEWORK_PATH "\${_SDL2_mountpoint}/SDL2.framework")
set(SDL2_INCLUDE_DIR  "\${SDL2_FRAMEWORK_PATH}/Headers")
set(SDL2_INCLUDE_DIRS "\${SDL2_INCLUDE_DIR};\${SDL2_FRAMEWORK_PATH}")
EOF

echo "==> Configuring EmptyEpsilon for DragNDrop package"
cmake \
    -S "${EE_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo \
    -DCPACK_GENERATOR:STRING=DragNDrop \
    -DSDL2_DIR:PATH="${SDL2_CONFIG_DIR}" \
    -DSERIOUS_PROTON_DIR="${SP_ROOT}" \
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake

echo "==> Building & packaging"
cmake --build "${BUILD_DIR}" --target package

echo "==> Detaching SDL2 DMG"
hdiutil detach "${SDL2_MOUNT}" -quiet 2>/dev/null || true

echo "==> Package created successfully"
find "${BUILD_DIR}" -maxdepth 1 -type f -name "*.dmg" -exec ls -lh {} \;
