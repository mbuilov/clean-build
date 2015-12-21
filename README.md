# clean-build
non-recursive crossplatform build system based on GNU make version 3.81

current version: 0.1

license: GPLv2

main features:

- non-recursive build
- massive parallelism, almost unlimited scaling by CPU number
- modular, extensible design
- multi-platform, using native platform tools (no cygwin or other unix emulation required to build on windows)
- cross-makefiles dependencies
- support for cross-compilation
- builtin support for languages: C, C++, Java, Scala, Wix
- support for C/C++ precompiled headers on linux and windows
- support for auto dependencies generation (for C/C++)
- support for compiling many-sources-at-once on windows
- support for debuging, checking and tracing of target makefiles
- predefined patterns for building shared and static libs, executables, kernel modules and jars
- support for rules generating multiple targets at one call
