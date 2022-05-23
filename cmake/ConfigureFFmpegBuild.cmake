#[[

This file contains functions for configuring FFmpeg builds.


preconfigure_ffmpeg_build (OUTPUT_DIR <dir>
                           SOURCE_DIR <dir>
                          [EXTRA_ARGS <args...>])

Runs FFmpeg's configure script at CMake configure time.


create_ffmpeg_build_target (BUILD_TARGET <targetName> [ALL]
                            SOURCE_DIR <dir>
                            OUTPUT_DIR <dir>
                           [ARCH <archName>])

Creates a build target to execute the FFmpeg build.

]]

cmake_minimum_required (VERSION 3.15 FATAL_ERROR)

include_guard (GLOBAL)

include (CPackComponent)
include (GNUInstallDirs)

#

function (preconfigure_ffmpeg_build)

    set (options "")
    set (oneValueArgs OUTPUT_DIR SOURCE_DIR)
    set (multiValueArgs EXTRA_ARGS)

    cmake_parse_arguments (FOLEYS_ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FOLEYS_ARG_OUTPUT_DIR)
        message (
            FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called without required argument OUTPUT_DIR!")
    endif ()

    if (NOT FOLEYS_ARG_SOURCE_DIR)
        message (
            FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called without required argument SOURCE_DIR!")
    endif ()

    # clean first
    execute_process (COMMAND "${FFMPEG_MAKE_EXECUTABLE}" distclean
                     WORKING_DIRECTORY "${FOLEYS_ARG_SOURCE_DIR}" COMMAND_ECHO STDOUT)

    file (REMOVE_RECURSE "${FOLEYS_ARG_OUTPUT_DIR}")

    set (
        CONFIGURE_COMMAND
        "./configure
        --disable-static
        --disable-doc
        --disable-asm
        --enable-shared
        --shlibdir=${FOLEYS_ARG_OUTPUT_DIR}
        --libdir=${FOLEYS_ARG_OUTPUT_DIR}
        --incdir=${FOLEYS_ARG_OUTPUT_DIR}/${CMAKE_INSTALL_INCLUDEDIR}
        --prefix=${FOLEYS_ARG_OUTPUT_DIR}")

    if (IOS OR ANDROID)
        set (
            CONFIGURE_COMMAND
            "${CONFIGURE_COMMAND}
                --enable-cross-compile
                --disable-programs
                --enable-pic")

        if (IOS)
            set (CONFIGURE_COMMAND "${CONFIGURE_COMMAND} --target-os=darwin")
        else ()
            set (CONFIGURE_COMMAND "${CONFIGURE_COMMAND} --target-os=android")
        endif ()
    endif ()

    separate_arguments (ffmpeg_config_command UNIX_COMMAND "${CONFIGURE_COMMAND}")

    if (FOLEYS_ARG_EXTRA_ARGS)
        list (APPEND ffmpeg_config_command ${FOLEYS_ARG_EXTRA_ARGS})
    endif ()

    execute_process (
        COMMAND ${ffmpeg_config_command} WORKING_DIRECTORY "${FOLEYS_ARG_SOURCE_DIR}" COMMAND_ECHO
                                                           STDOUT COMMAND_ERROR_IS_FATAL ANY)

endfunction ()

#

function (create_ffmpeg_build_target)

    set (options ALL)
    set (oneValueArgs BUILD_TARGET SOURCE_DIR OUTPUT_DIR ARCH)
    set (multiValueArgs "")

    cmake_parse_arguments (FOLEYS_ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT FOLEYS_ARG_BUILD_TARGET)
        message (
            FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called without required argument BUILD_TARGET!")
    endif ()

    if (NOT FOLEYS_ARG_SOURCE_DIR)
        message (
            FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called without required argument SOURCE_DIR!")
    endif ()

    if (NOT FOLEYS_ARG_OUTPUT_DIR)
        message (
            FATAL_ERROR "${CMAKE_CURRENT_FUNCTION} called without required argument OUTPUT_DIR!")
    endif ()

    #

    function (ffmpeg_make_lib_filename libname filename_out)

        set (filename "")

        if (CMAKE_SHARED_LIBRARY_PREFIX)
            set (filename "${CMAKE_SHARED_LIBRARY_PREFIX}")
        endif ()

        set (filename "${filename}${libname}")

        if (CMAKE_SHARED_LIBRARY_SUFFIX)
            set (filename "${filename}${CMAKE_SHARED_LIBRARY_SUFFIX}")
        endif ()

        set (${filename_out} "${filename}" PARENT_SCOPE)

    endfunction ()

    #

    set (ffmpeg_libs_output_files "")

    foreach (libname IN ITEMS avutil swresample avcodec avformat swscale)
        ffmpeg_make_lib_filename ("${libname}" libfilename)

        set (lib_path "${FOLEYS_ARG_OUTPUT_DIR}/${libfilename}")

        list (APPEND ffmpeg_libs_output_files "${lib_path}")

        if (FOLEYS_ARG_ARCH)
            set (install_dest "${CMAKE_INSTALL_LIBDIR}/${FOLEYS_ARG_ARCH}")
        else ()
            set (install_dest "${CMAKE_INSTALL_LIBDIR}")
        endif ()

        target_link_libraries (
            ffmpeg INTERFACE "$<BUILD_INTERFACE:${lib_path}>"
                             "$<INSTALL_INTERFACE:${install_dest}/${libfilename}>")

        install (FILES "${lib_path}" DESTINATION "${install_dest}" COMPONENT ffmpeg_${libname})

        cpack_add_component (ffmpeg_${libname} DISPLAY_NAME "FFmpeg ${libname} library" GROUP ffmpeg
                             DEPENDS ffmpeg_base)
    endforeach ()

    #

    if (FOLEYS_ARG_ARCH)
        set (comment "Building FFmpeg for arch ${FOLEYS_ARG_ARCH}...")
    else ()
        set (comment "Building FFmpeg...")
    endif ()

    if (FOLEYS_ARG_ALL)
        set (all_flag ALL)
    endif ()

    add_custom_target (
        "${FOLEYS_ARG_BUILD_TARGET}"
        ${all_flag}
        COMMAND "${FFMPEG_MAKE_EXECUTABLE}" -j4
        WORKING_DIRECTORY "${FOLEYS_ARG_SOURCE_DIR}"
        COMMENT "${comment}"
        VERBATIM USES_TERMINAL)

    add_custom_command (
        TARGET "${FOLEYS_ARG_BUILD_TARGET}"
        POST_BUILD
        COMMAND "${FFMPEG_MAKE_EXECUTABLE}" install
        BYPRODUCTS "${ffmpeg_libs_output_files}"
        WORKING_DIRECTORY "${FOLEYS_ARG_SOURCE_DIR}"
        VERBATIM USES_TERMINAL)

    add_dependencies (ffmpeg "${FOLEYS_ARG_BUILD_TARGET}")

endfunction ()
