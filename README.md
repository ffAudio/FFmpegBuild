This repository contains CMake scripts wrapping FFmpeg's horrendous build system into something sane and usable.

On MacOS, universal binaries are supported. (Technically, this repo's scripts build FFmpeg twice, once for arm64 and once for x86-64.)

To use FFmpeg from within a CMake project, run `cmake --install` within this directory, and then from the consuming project you can do:
```cmake
find_package (FFmpeg)
```
and it should work out of the box.

TO DO: iOS and Android!