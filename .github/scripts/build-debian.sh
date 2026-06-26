#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-amd64}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"
BUILD_DIR="${EE_ROOT}/_build"

echo "==> Installing system dependencies for Debian/${ARCH}"
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
    build-essential cmake ninja-build zip unzip \
    libsdl2-dev libfreetype-dev

echo "==> Configuring EmptyEpsilon (DEB, ${ARCH})"
cmake \
    -S "${EE_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake \
    -DSERIOUS_PROTON_DIR="${SP_ROOT}" \
    -DCPACK_GENERATOR=DEB

echo "==> Building & packaging"
cmake --build "${BUILD_DIR}" --target package

if [ -f "${BUILD_DIR}/EmptyEpsilon.deb" ]; then
    echo "==> Package: $(ls -lh "${BUILD_DIR}/EmptyEpsilon.deb" | awk '{print $5, $NF}')"
    dpkg --info "${BUILD_DIR}/EmptyEpsilon.deb" | grep -E "Package|Version|Architecture"
else
    echo "==> ERROR: EmptyEpsilon.deb not found!"
    find "${BUILD_DIR}" -maxdepth 1 -type f -name "*.deb" -exec ls -lh {} \;
    exit 1
fi
