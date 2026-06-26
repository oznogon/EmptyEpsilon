#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/_common.sh"

EE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SP_ROOT="$(cd "${EE_ROOT}/../SeriousProton" && pwd)"
WORKDIR="$(pwd)"

IMAGE="${EE_DOCKCROSS_IMAGE:?dockcross_image is required}"
CPACK_GEN="${EE_CPACK_GEN:-DEB}"
CPACK_ARCH="${EE_CPACK_ARCH:-}"
LTO_FLAGS=()

if [ "${EE_LTO_DISABLE:-}" = "true" ]; then
    LTO_FLAGS=(
        -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF
        -DCMAKE_CXX_FLAGS="-O2 -fno-lto"
        -DCMAKE_C_FLAGS="-O2 -fno-lto"
        -DCMAKE_EXE_LINKER_FLAGS="-fno-lto"
        -DCMAKE_SHARED_LINKER_FLAGS="-fno-lto"
        -DCMAKE_MODULE_LINKER_FLAGS="-fno-lto"
    )
fi

SDL2_DOCKCROSS_DIR="${SDL2_DIR_NAME}/install_${IMAGE//\//-}"
BUILD_DIR="${EE_ROOT}/_build"

echo "==> Dockcross image: ${IMAGE}"
echo "==> CPack generator: ${CPACK_GEN}"
echo "==> EE root:         ${EE_ROOT}"
echo "==> SP root:         ${SP_ROOT}"
echo "==> SDL2 target:     ${SDL2_DOCKCROSS_DIR}"

# Download SDL2 source if it does not exist
ensure_sdl2_source

# Fetch or reuse the dockcross wrapper
wrapper=$(ensure_dockcross "${IMAGE}")
echo "==> Dockcross wrapper: ${wrapper}"

if [ ! -d "${SDL2_DOCKCROSS_DIR}/lib/cmake/SDL2" ]; then
    echo "==> Building SDL2 for ${IMAGE} (cache miss)"
    mkdir -p "${SDL2_DIR_NAME}/build_${IMAGE//\//-}"
    ./"${wrapper}" bash -c "
        set -euo pipefail
        mkdir -p /work/${SDL2_DIR_NAME}/build_${IMAGE//\//-}
        cmake \
            -S /work/${SDL2_DIR_NAME} \
            -B /work/${SDL2_DIR_NAME}/build_${IMAGE//\//-} \
            -G Ninja \
            -DCMAKE_INSTALL_PREFIX=/work/${SDL2_DOCKCROSS_DIR} \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build /work/${SDL2_DIR_NAME}/build_${IMAGE//\//-} --target install
        rm -rf /work/${SDL2_DIR_NAME}/build_${IMAGE//\//-}
    "
else
    echo "==> SDL2 for ${IMAGE} cached at ${SDL2_DOCKCROSS_DIR}"
fi

echo "==> Configuring EmptyEpsilon"

# Build the cmake flag array as a single string for passing into bash -c safely.
CMAKE_FLAGS_ARRAY=(
    -S /work/EmptyEpsilon
    -B /work/EmptyEpsilon/_build
    -G Ninja
    -DCMAKE_BUILD_TYPE=RelWithDebInfo
    -DCMAKE_PROJECT_EmptyEpsilon_INCLUDE=version.cmake
    -DSDL2_DIR=/work/${SDL2_DOCKCROSS_DIR}/lib/cmake/SDL2
    -DSERIOUS_PROTON_DIR=/work/SeriousProton
    -DCPACK_GENERATOR="${CPACK_GEN}"
)

if [ -n "${CPACK_ARCH}" ]; then
    CMAKE_FLAGS_ARRAY+=("${CPACK_ARCH}")
fi

if [ ${#LTO_FLAGS[@]} -gt 0 ]; then
    CMAKE_FLAGS_ARRAY+=("${LTO_FLAGS[@]}")
fi

./"${wrapper}" bash -c "
    set -euo pipefail
    export SUPPRESS_BOLTDB_WARNING=true
    cd /work
    cmake ${CMAKE_FLAGS_ARRAY[*]}
    cmake --build /work/EmptyEpsilon/_build --target package
"

echo "==> Package created successfully"
find "${BUILD_DIR}" -maxdepth 1 -type f \( \
    -name "EmptyEpsilon.deb" -o \
    -name "EmptyEpsilon.rpm" -o \
    -name "EmptyEpsilon.zip"  -o \
    -name "EmptyEpsilon.dmg" \
\) -exec ls -lh {} \;
