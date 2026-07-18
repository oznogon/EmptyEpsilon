#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-amd64}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"
BUILD_DIR="${EE_ROOT}/_build"

echo "==> Installing system dependencies for Fedora/${ARCH}"
dnf install -y -q \
    git gcc gcc-c++ cmake ninja-build findutils \
    SDL2-devel freetype-devel rpm-build

echo "==> Configuring EmptyEpsilon (RPM, ${ARCH})"
cmake \
    -S "${EE_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake \
    -DSERIOUS_PROTON_DIR="${SP_ROOT}" \
    -DCPACK_GENERATOR=RPM

echo "==> Building & packaging"
cmake --build "${BUILD_DIR}" --target package

if [ -f "${BUILD_DIR}/EmptyEpsilon.rpm" ]; then
    echo "==> Package: $(ls -lh "${BUILD_DIR}/EmptyEpsilon.rpm" | awk '{print $5, $NF}')"
    rpm -qip "${BUILD_DIR}/EmptyEpsilon.rpm" 2>/dev/null | grep -E "^Name|^Version|^Architecture"
else
    echo "==> ERROR: EmptyEpsilon.rpm not found!"
    for f in "${BUILD_DIR}/"*.rpm; do
        [ -f "$f" ] && ls -lh "$f"
    done
    exit 1
fi
