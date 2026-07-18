#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:-amd64}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"
BUILD_DIR="${EE_ROOT}/_build"
WORK="${EE_ROOT}/_work"

LLVM_MINGW_VERSION="20260616"
LLVM_MINGW_URL="https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-22.04-x86_64.tar.xz"
LLVM_MINGW_DIR="${WORK}/llvm-mingw"

SDL2_VERSION="2.32.10"
SDL2_SRC_URL="https://github.com/libsdl-org/SDL/archive/refs/tags/release-${SDL2_VERSION}.tar.gz"
SDL2_MINGW_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/SDL2-devel-${SDL2_VERSION}-mingw.tar.gz"
SDL2_SRC_DIR="${WORK}/SDL-release-${SDL2_VERSION}"
SDL2_MINGW_DIR="${WORK}/SDL2-${SDL2_VERSION}"
SDL2_SYSROOT="${WORK}/sdl2-sysroot"

echo "==> Installing system packages"
sudo apt-get update -qq
sudo apt-get install -y -qq cmake ninja-build pkg-config xz-utils

echo "==> Downloading llvm-mingw (${LLVM_MINGW_VERSION})"
if [ ! -d "${LLVM_MINGW_DIR}" ]; then
    mkdir -p "${LLVM_MINGW_DIR}"
    wget -qO- "${LLVM_MINGW_URL}" | tar xJ -C "${LLVM_MINGW_DIR}" --strip-components 1
fi
export PATH="${LLVM_MINGW_DIR}/bin:${PATH}"

case "${ARCH}" in
    amd64)
        MINGW_TARGET="x86_64-w64-mingw32"
        MINGW_SUBDIR="x86_64-w64-mingw32"
        ;;
    arm64)
        MINGW_TARGET="aarch64-w64-mingw32"
        MINGW_SUBDIR="aarch64-w64-mingw32"
        ;;
    *)
        echo "ERROR: unknown architecture ${ARCH}" >&2
        exit 1
        ;;
esac

if [ "${ARCH}" = "amd64" ]; then
    echo "==> Downloading SDL2 MinGW development archive (${SDL2_VERSION})"
    if [ ! -d "${SDL2_MINGW_DIR}" ]; then
        wget -qO- "${SDL2_MINGW_URL}" | tar xz -C "${WORK}"
    fi
    SDL2_PREFIX="${SDL2_MINGW_DIR}/${MINGW_SUBDIR}"
else
    echo "==> Building SDL2 from source for arm64 MinGW (${SDL2_VERSION})"
    if [ ! -d "${SDL2_SRC_DIR}" ]; then
        wget -qO- "${SDL2_SRC_URL}" | tar xz -C "${WORK}"
    fi
    rm -rf "${SDL2_SYSROOT}"
    mkdir -p "${SDL2_SYSROOT}" "${SDL2_SRC_DIR}/_build"
    cmake \
        -S "${SDL2_SRC_DIR}" \
        -B "${SDL2_SRC_DIR}/_build" \
        -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Windows \
        -DCMAKE_C_COMPILER="${MINGW_TARGET}-gcc" \
        -DCMAKE_CXX_COMPILER="${MINGW_TARGET}-g++" \
        -DCMAKE_INSTALL_PREFIX="${SDL2_SYSROOT}" \
        -DSDL_SHARED=ON \
        -DSDL_STATIC=OFF
    cmake --build "${SDL2_SRC_DIR}/_build"
    cmake --install "${SDL2_SRC_DIR}/_build"
    SDL2_PREFIX="${SDL2_SYSROOT}"
fi

echo "==> Configuring EmptyEpsilon (ZIP, ${ARCH}, cross)"
cmake \
    -S "${EE_ROOT}" \
    -B "${BUILD_DIR}" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_SYSTEM_NAME=Windows \
    -DCMAKE_C_COMPILER="${MINGW_TARGET}-gcc" \
    -DCMAKE_CXX_COMPILER="${MINGW_TARGET}-g++" \
    -DCMAKE_PREFIX_PATH="${SDL2_PREFIX}" \
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake \
    -DSERIOUS_PROTON_DIR="${SP_ROOT}" \
    -DCPACK_GENERATOR=ZIP

echo "==> Building & packaging"
cmake --build "${BUILD_DIR}" --target package

pkg=""
for f in "${BUILD_DIR}/"*.zip; do
    [ -f "$f" ] && { pkg="$f"; break; }
done

if [ -n "${pkg}" ]; then
    echo "==> Package: $(ls -lh "${pkg}" | awk '{print $5, $NF}')"
else
    echo "==> ERROR: EmptyEpsilon.zip not found!"
    ls -la "${BUILD_DIR}" 2>/dev/null || true
    exit 1
fi
