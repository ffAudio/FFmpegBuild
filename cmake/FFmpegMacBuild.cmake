#[[

Inclusion of this file configures builds of FFmpeg for both arm64 and x86_64 architectures.

This requires yasm and clang.

]]

cmake_minimum_required (VERSION 3.15 FATAL_ERROR)

include_guard (GLOBAL)

#

find_program (
    PROGRAM_CLANG clang
    DOC "clang executable used to build FFmpeg. This cache variable isn't actually used, just checked for existence."
    )

find_program (
    PROGRAM_YASM yasm
    DOC "yasm executable used in building FFmpeg. This cache variable isn't actually used, just checked for existence."
    )

if (NOT (PROGRAM_YASM AND PROGRAM_CLANG))
    message (FATAL_ERROR "On MacOS, clang and yasm are required to build FFmpeg!")
endif ()

#

if (PROJECT_IS_TOP_LEVEL)
    set (all_flag ALL)
else ()
    unset (all_flag)
endif ()

foreach (arch IN ITEMS x86_64 arm64)

    message (STATUS "Configuring FFmpeg build for arch ${arch}...")

    set (sourceDir "${CMAKE_CURRENT_BINARY_DIR}/ffmpeg_arch_sources/${arch}/${FFMPEG_NAME}")

    # each arch needs its own copy of the source tree ¯\_(ツ)_/¯
    file (COPY "${FFMPEG_SOURCE_DIR}" DESTINATION "${sourceDir}/.." # cmake adds an extra nested
                                                                    # directory when copying
          USE_SOURCE_PERMISSIONS FOLLOW_SYMLINK_CHAIN)

    set (outputDir "${ffmpeg_output_dir}/${arch}")

    preconfigure_ffmpeg_build (
        SOURCE_DIR "${sourceDir}" OUTPUT_DIR "${outputDir}"
        EXTRA_ARGS --enable-cross-compile --arch=${arch} "--cc=clang -arch ${arch}"
                   "--cxx=clang++ -arch ${arch}")

    create_ffmpeg_build_target (SOURCE_DIR "${sourceDir}" OUTPUT_DIR "${outputDir}"
                                BUILD_TARGET ffmpeg_build_${arch} ARCH ${arch} ${all_flag})

    set_target_properties (ffmpeg_build_${arch} PROPERTIES OSX_ARCHITECTURES ${arch})

endforeach ()
