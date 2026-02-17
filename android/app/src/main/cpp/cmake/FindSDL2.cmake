# FindSDL2.cmake - Custom module for Android Gradle build
#
# This module helps find SDL2 that was built via add_subdirectory
# in the wrapper CMakeLists.txt
#
# Sets:
#   SDL2_FOUND - True if SDL2 is found
#   SDL2_LIBRARIES - SDL2 library target
#   SDL2_INCLUDE_DIRS - SDL2 include directories

# SDL2 was already built via add_subdirectory in the parent CMakeLists.txt
# Just need to set the variables that the build expects

if(TARGET SDL2::SDL2)
    # SDL2 target already exists
    set(SDL2_FOUND TRUE)
    set(SDL2_LIBRARIES SDL2::SDL2)
    # sdl2_SOURCE_DIR is set by FetchContent_MakeAvailable(SDL2) in the parent CMakeLists.txt
    if(DEFINED sdl2_SOURCE_DIR)
        set(SDL2_INCLUDE_DIRS "${sdl2_SOURCE_DIR}/include")
    else()
        set(SDL2_INCLUDE_DIRS "${CMAKE_CURRENT_LIST_DIR}/../SDL2/include")
    endif()

    message(STATUS "Found SDL2 (via FetchContent): ${SDL2_LIBRARIES}")
else()
    set(SDL2_FOUND FALSE)
    message(FATAL_ERROR "SDL2::SDL2 target not found. SDL2 must be built before including this module.")
endif()
