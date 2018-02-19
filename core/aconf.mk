#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# build system autoconfiguration

# this file is included by $(cb_dir)/core/_defs.mk

# optional: the operating system we are building on (WINDOWS, LINUX, SUNOS, etc.)
# note: CBLD_OS value may affect default values of other variables (CBLD_BCPU, CBLD_UTILS, etc.)
ifeq (undefined,$(origin CBLD_OS))
ifneq (,$(filter /%,$(CURDIR)))
# CYGWIN_NT-6.1 MINGW64_NT-6.1 SUNOS LINUX ...
CBLD_OS := $(call toupper,$(shell uname))
else ifneq (,$(findstring :,$(CURDIR)))
CBLD_OS := WINDOWS
else
# unknown
CBLD_OS:=
endif
endif # !CBLD_OS

# optional: processor architecture of the tools of the Build machine
# note: equivalent of '--build' Gnu Autoconf configure script option
# note: CBLD_BCPU specification may also encode format of executable files, e.g. CBLD_BCPU=m68k-coff, it is checked by the C compiler
ifeq (undefined,$(origin CBLD_BCPU))
ifndef CBLD_OS
# unknown
CBLD_BCPU:=
else ifneq (,$(filter WIN%,$(CBLD_OS)))
# x86 IA64 AMD64 ARM ARM64 ...
ifneq (undefined,$(origin PROCESSOR_ARCHITEW6432))
CBLD_BCPU := $(PROCESSOR_ARCHITEW6432)
else
CBLD_BCPU := $(PROCESSOR_ARCHITECTURE)
endif
else ifneq (,$(filter SUN%,$(CBLD_OS)))
# amd64 i386 sparcv9 sparc ...
CBLD_BCPU := $(firstword $(shell isainfo))
else
# arm aarch64 m68k mips mips64 ppc ppc64 ppcle ppc64le sparc sparc64 i386 i686 x86_64 ...
CBLD_BCPU := $(shell uname -m)
endif
endif # !CBLD_BCPU

# optional: processor architecture we are building the package for
# note: equivalent of '--host' Gnu Autoconf configure script option
# note: CBLD_CPU specification may also encode format of executable files, e.g. CBLD_CPU=m68k-coff, it is checked by the C compiler
ifeq (undefined,$(origin CBLD_CPU))
CBLD_CPU := $(CBLD_BCPU)
endif

# optional: processor architecture of build helper Tools created while the build
# note: CBLD_TCPU do not affects the built package
# note: CBLD_TCPU specification may also encode format of executable files, e.g. CBLD_TCPU=m68k-coff, it is checked by the C compiler
ifeq (undefined,$(origin CBLD_TCPU))
CBLD_TCPU := $(CBLD_BCPU)
endif

# flavor of system shell utilities (such as cp, mv, rm, etc.)
# note: $(CBLD_UTILS) value is used only to form name of standard makefile with definitions of shell utilities
# note: normally CBLD_UTILS get overridden by specifying it in command line, for example: CBLD_UTILS:=gnu
ifeq (undefined,$(origin CBLD_UTILS))
CBLD_UTILS := $(if \
  $(filter WIN%,$(CBLD_OS)),cmd,$(if \
  $(filter CYGWIN% MINGW% LINUX%,$(CBLD_OS)),gnu,unix))
endif

# makefile with the definitions of shell utilities
utils_mk := $(cb_dir)/utils/$(CBLD_UTILS).mk

ifeq (,$(wildcard $(utils_mk)))
$(error file '$(utils_mk)' was not found, check $(if $(findstring file,$(origin \
  utils_mk)),values of CBLD_OS=$(CBLD_OS) and CBLD_UTILS=$(CBLD_UTILS),value of overridden 'utils_mk' variable))
endif

# remember autoconfigured variables: CBLD_OS, CBLD_BCPU, CBLD_CPU, CBLD_TCPU and CBLD_UTILS (if they are not defined
#  as a project variables and so are not already saved by the $(cb_dir)/core/confsup.mk)
$(call config_remember_vars,CBLD_OS CBLD_BCPU CBLD_CPU CBLD_TCPU CBLD_UTILS)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_OS CBLD_BCPU CBLD_CPU CBLD_TCPU CBLD_UTILS)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: core
$(call set_global,utils_mk,core)
