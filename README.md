# clean-build
Non-recursive unharmful cross-platform build system based on GNU Make

Copyright (C) 2015-2017 Michael M. Builov (mbuilov@gmail.com)

Current version: 0.1

License: GPLv2 or later

Minimum supported GNU Make version: 3.81

Out-of-the-box supported operating systems: WINDOWS, LINUX, SOLARIS

Main features:

- non-recursive build
- massive parallelism, almost unlimited scaling by CPU number
- modular, extensible design
- multi-platform, using native tools only (no CYGWIN or other UNIX emulation layer is required to build targets on WINDOWS)
- support for cross-makefiles dependencies
- support for cross-compilation
- builtin support for building targets written on languages: C, C++, Java, Scala, Wix
- support for C/C++ precompiled headers on LINUX and WINDOWS
- support for auto generation of source-header dependencies (for C/C++)
- support for compiling many-sources-at-once on WINDOWS
- support for debugging, checking and tracing of target makefiles
- predefined patterns for building shared and static libraries, executables, kernel modules and java archives
- support for custom rules generating multiple target files at one call
