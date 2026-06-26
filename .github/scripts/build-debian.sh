#!/usr/bin/env bash
set -euo pipefail

# build-debian.sh -- native Debian build (amd64 / arm64)
#
# Installs system dependencies via apt, then builds EmptyEpsilon with the
# DEB CPack generator.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"

echo "==> Installing system dependencies"
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
    build-essential cmake ninja-build zip unzip \
    libsdl2-dev libfreetype-dev

BUILD_DIR="${EE_ROOT}/_build"

echo "==> Configuring (${EE_CPACK_GEN:-DEB})"
cmake \
    -S "${EE_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake \
    -DSERIOUS_PROTON_DIR="${SP_ROOT}" \
    -DCPACK_GENERATOR="${EE_CPACK_GEN:-DEB}" \
    ${EE_CPACK_ARCH:+"${EE_CPACK_ARCH}"}

echo "==> Building & packaging"
cmake --build "${BUILD_DIR}" --target package

echo "==> Package created successfully"
find "${BUILD_DIR}" -maxdepth 1 -type f \( \
    -name "EmptyEpsilon.deb" -o \
    -name "EmptyEpsilon.rpm" -o \
    -name "EmptyEpsilon.zip"  -o \
    -name "EmptyEpsilon.dmg" \
\) -exec ls -lh {} \;
