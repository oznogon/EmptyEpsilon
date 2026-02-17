cmake_minimum_required(VERSION 3.22.1)
project(EmptyEpsilonAndroid)

# Set C++17 standard as required by EmptyEpsilon
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add GLM C++17 flag
add_definitions(-DGLM_FORCE_CXX17=1)

# Download and build SDL2 from source
include(FetchContent)
FetchContent_Declare(
    SDL2
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG release-2.32.8
    GIT_SHALLOW ON
)
FetchContent_MakeAvailable(SDL2)

# Set SDL2_INCLUDE_DIRS for SeriousProton's find_package(SDL2) call,
# which uses this variable directly in target_include_directories.
# sdl2_SOURCE_DIR is set by FetchContent_MakeAvailable above.
set(SDL2_INCLUDE_DIRS "${sdl2_SOURCE_DIR}/include")

# Add custom FindSDL2.cmake module directory so find_package(SDL2) works
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Set flag to indicate we're building with Gradle (not legacy CMake Android toolchain)
# This prevents the old android_apk() command from being called
set(ANDROID_GRADLE_BUILD TRUE CACHE BOOL "Building with Android Gradle")

# Set SeriousProton path
# This should point to the SeriousProton symlink in this directory
if(NOT DEFINED SERIOUS_PROTON_DIR)
    set(SERIOUS_PROTON_DIR "${CMAKE_CURRENT_SOURCE_DIR}/SeriousProton" CACHE PATH "Path to SeriousProton")
endif()

# Set EmptyEpsilon path
# This should point to the EmptyEpsilon symlink in this directory
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/EmptyEpsilon ${CMAKE_BINARY_DIR}/EmptyEpsilon)
