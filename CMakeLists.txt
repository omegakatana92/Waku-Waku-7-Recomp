cmake_minimum_required(VERSION 3.21)
project(wakuwak7 VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# The neogeorecomp toolkit: the in-tree copy (a submodule in a clean
# checkout), or a checkout next to this project. The in-tree copy carries the
# generic v0.2.0 fixes (watchdog, bank guard, 4:3 fullscreen, M1 bank mask).
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp/CMakeLists.txt)
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp)
else()
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/../neogeorecomp)
endif()
set(NEOGEORECOMP_DIR ${ng_default} CACHE PATH "neogeorecomp checkout")
add_subdirectory(${NEOGEORECOMP_DIR} neogeorecomp_build)

find_package(Python3 COMPONENTS Interpreter QUIET)

# Your unzipped MAME "wakuwak7" set and "neogeo" system ROMs. The build reads
# them where they are; nothing derived from them is committed.
set(WAKUWAKU7_ROM_DIR "" CACHE PATH "Directory with your wakuwak7 and Neo Geo BIOS ROM files")
# Optional: entry points a previous run found at runtime (--dump-misses).
set(WAKUWAKU7_ENTRIES "${CMAKE_BINARY_DIR}/entries.txt" CACHE FILEPATH "Extra entry points for the recompiler")

# Stage 1: the generator.
add_executable(wakuwak7_recomp src/recomp_main.c src/game.c)
target_link_libraries(wakuwak7_recomp PRIVATE m68krecomp_core)
target_include_directories(wakuwak7_recomp PRIVATE src)

# Stage 2: the player, with the generated C when ROMs are available.
set(GAME_SOURCES src/main.c)
set(GEN_DIR ${CMAKE_BINARY_DIR}/generated)
set(GEN_FILES 16)
if(WAKUWAKU7_ROM_DIR)
    set(GEN_SOURCES ${GEN_DIR}/recomp_table.c)
    math(EXPR last "${GEN_FILES} - 1")
    foreach(i RANGE ${last})
        if(i LESS 10)
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_0${i}.c)
        else()
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_${i}.c)
        endif()
    endforeach()
    # The entry list starts empty; the `profile` target fills it from a
    # scripted play session and the next build regenerates with it.
    if(NOT EXISTS ${WAKUWAKU7_ENTRIES})
        file(WRITE ${WAKUWAKU7_ENTRIES} "")
    endif()
    file(MAKE_DIRECTORY ${GEN_DIR})
    add_custom_command(
        OUTPUT ${GEN_SOURCES} ${GEN_DIR}/recomp_common.h
        COMMAND wakuwak7_recomp --rom-path ${WAKUWAKU7_ROM_DIR} --out ${GEN_DIR} --files ${GEN_FILES}
                --entries ${WAKUWAKU7_ENTRIES}
        DEPENDS wakuwak7_recomp ${WAKUWAKU7_ENTRIES}
        COMMENT "Recompiling Waku Waku 7 from ${WAKUWAKU7_ROM_DIR}")
    list(APPEND GAME_SOURCES ${GEN_SOURCES})
endif()

add_executable(wakuwak7 ${GAME_SOURCES} src/game.c)
if(WIN32)
    set_target_properties(wakuwak7 PROPERTIES OUTPUT_NAME "Waku Waku 7")
else()
    set_target_properties(wakuwak7 PROPERTIES OUTPUT_NAME "wakuwak7")
endif()
target_link_libraries(wakuwak7 PRIVATE neogeorecomp)
target_include_directories(wakuwak7 PRIVATE src ${GEN_DIR})
if(WAKUWAKU7_ROM_DIR)
    add_custom_target(profile
        COMMAND wakuwak7 --headless --rom-path ${WAKUWAKU7_ROM_DIR} --frames 6000
                --dump-misses ${WAKUWAKU7_ENTRIES}
        COMMAND wakuwak7 --headless --rom-path ${WAKUWAKU7_ROM_DIR} --frames 19000
                --input ${CMAKE_CURRENT_SOURCE_DIR}/tests/play_long.txt
                --dump-misses ${WAKUWAKU7_ENTRIES}
        DEPENDS wakuwak7
        COMMENT "Profiling scripted sessions for runtime-only entry points")
    if(Python3_Interpreter_FOUND)
        add_custom_target(audio-check
            COMMAND wakuwak7 --headless --rom-path ${WAKUWAKU7_ROM_DIR} --frames 12001
                    --input ${CMAKE_CURRENT_SOURCE_DIR}/tests/play_long.txt
                    --wav ${CMAKE_BINARY_DIR}/audio-check.wav
            COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_audio.py
                    ${CMAKE_BINARY_DIR}/audio-check.wav
            DEPENDS wakuwak7
            COMMENT "Checking Waku Waku 7 audio continuity")
    endif()
    target_compile_definitions(wakuwak7 PRIVATE WAKUWAKU7_HAVE_RECOMP)
    if(MSVC)
        # Generated routines are large; /bigobj lifts the section limit.
        # /O1 avoids MSVC's superlinear optimizer blow-up on the giant
        # dispatch functions and still runs the 68000 code at full speed.
        set_source_files_properties(${GEN_SOURCES} PROPERTIES COMPILE_OPTIONS "/bigobj;/O1")
    else()
        # GCC/Clang at -O3 spend a long time on these giant switch functions.
        set_source_files_properties(${GEN_SOURCES} PROPERTIES COMPILE_OPTIONS "-O1")
    endif()
endif()
if(MSVC)
    target_compile_definitions(wakuwak7 PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_compile_definitions(wakuwak7_recomp PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

# Ship the SDL2 DLL (when the window is built) next to the executable.
if(WIN32 AND TARGET SDL2::SDL2)
    add_custom_command(TARGET wakuwak7 POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_RUNTIME_DLLS:wakuwak7> $<TARGET_FILE_DIR:wakuwak7>
        COMMAND_EXPAND_LISTS)
endif()
