# _common.sh -- shared helpers for build scripts
#
# Sources: EE_DOCKCROSS_IMAGE, EE_CPACK_GEN, EE_CPACK_ARCH, EE_LTO_DISABLE env vars.

SDL2_VERSION="2.32.10"
SDL2_DIR_NAME="SDL2-${SDL2_VERSION}"
SDL2_URL="https://github.com/libsdl-org/SDL/releases/download/release-${SDL2_VERSION}/${SDL2_DIR_NAME}.tar.gz"

SUPPRESS_BOLTDB_WARNING=true

ensure_sdl2_source() {
    if [ ! -d "${SDL2_DIR_NAME}" ]; then
        if [ ! -f "${SDL2_DIR_NAME}.tar.gz" ]; then
            wget -q "${SDL2_URL}"
        fi
        tar zxf "${SDL2_DIR_NAME}.tar.gz"
    fi
}

ensure_dockcross() {
    local image="$1"
    local wrapper_name="${image//\//-}"
    if [ ! -f "${wrapper_name}" ]; then
        docker pull "dockcross/${image}"
        docker run --rm "dockcross/${image}" > "${wrapper_name}"
        chmod +x "${wrapper_name}"
    fi
    echo "${wrapper_name}"
}
