# Searches for OpenSSL 1.1 DLLs and copies them to the build output.
# On Windows the Hue V2 device requires libssl-1_1.dll / libcrypto-1_1.dll
# at runtime (loaded dynamically by tcpSocket).
#
# Note: some x64 OpenSSL builds use the -x64 filename suffix and the
# binary references libcrypto-1_1-x64.dll internally. We copy both the
# original and the de-suffixed names so LoadLibrary can resolve the
# dependency chain.
set(OPENSSL11_ARCH "")
set(OPENSSL11_DLL_DIR "")

if(WIN32)
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(OPENSSL11_ARCH "x64")
    else()
        set(OPENSSL11_ARCH "x86")
    endif()

    if(NOT OPENSSL11_DLL_DIR)
        execute_process(
            COMMAND powershell -NoProfile -Command
                "Get-ChildItem -Path 'C:/Program Files','C:/Program Files (x86)' -Recurse -Filter 'libssl-1_1*.dll' -ErrorAction SilentlyContinue -Depth 4 | ForEach-Object { $_.DirectoryName } | Select-Object -First 1"
            OUTPUT_VARIABLE _ps_result
            OUTPUT_STRIP_TRAILING_WHITESPACE
            ERROR_QUIET
        )
        if(_ps_result AND EXISTS "${_ps_result}/libssl-1_1.dll" OR EXISTS "${_ps_result}/libssl-1_1-${OPENSSL11_ARCH}.dll")
            set(OPENSSL11_DLL_DIR "${_ps_result}")
        endif()
    endif()

    if(NOT OPENSSL11_DLL_DIR)
        message(WARNING "OpenSSL 1.1 DLLs not found on system.")
        message(WARNING "Install OpenSSL from https://slproweb.com/products/Win32OpenSSL.html")
        message(WARNING "Or set OPENSSL11_DLL_DIR in CMake to the directory containing libssl-1_1.dll")
    else()
        message(STATUS "OpenSSL 1.1 DLLs found in: ${OPENSSL11_DLL_DIR}")
    endif()
endif()

function(openssl11_copy_dlls TARGET)
    if(WIN32 AND OPENSSL11_DLL_DIR)
        foreach(_base libssl libcrypto)
            set(_dll_orig "")
            if(EXISTS "${OPENSSL11_DLL_DIR}/${_base}-1_1.dll")
                set(_dll_orig "${OPENSSL11_DLL_DIR}/${_base}-1_1.dll")
            elseif(EXISTS "${OPENSSL11_DLL_DIR}/${_base}-1_1-${OPENSSL11_ARCH}.dll")
                set(_dll_orig "${OPENSSL11_DLL_DIR}/${_base}-1_1-${OPENSSL11_ARCH}.dll")
            endif()

            if(_dll_orig)
                get_filename_component(_dll_orig_name "${_dll_orig}" NAME)
                add_custom_command(TARGET ${TARGET} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_dll_orig}" "$<TARGET_FILE_DIR:${TARGET}>/${_dll_orig_name}"
                    COMMENT "Copying ${_dll_orig_name}"
                )
                string(REGEX REPLACE "-${OPENSSL11_ARCH}" "" _dll_simple_name "${_dll_orig_name}")
                if(NOT _dll_simple_name STREQUAL _dll_orig_name)
                    add_custom_command(TARGET ${TARGET} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_dll_orig}" "$<TARGET_FILE_DIR:${TARGET}>/${_dll_simple_name}"
                        COMMENT "Copying ${_dll_orig_name} as ${_dll_simple_name} (symlink)"
                    )
                endif()
            endif()
        endforeach()
    endif()
endfunction()
