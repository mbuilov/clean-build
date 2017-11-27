#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# the only case when variable TOP is overridden - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# TOP - project root directory - used in target makefiles for referencing sources, other makefiles, include paths, etc.
# Note: TOP variable is not used by clean-build and may be arbitrary named
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))..))

# specify version of clean-build build system required by this project
CLEAN_BUILD_REQUIRED_VERSION := 0.9.0

# next variables are needed for generating:
# - header file with version info (see $(MTOP)/exts/version/version.mk)
# - under Windows, resource files with version info (see $(MTOP)/WINXX/cres.mk)
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

# global product version
# Note: this is default value of MODVER - per-module version number
# format: major.minor.patch
PRODUCT_VER := 1.0.0

# BUILD - variable required by clean-build - path to the root directory of all built artifacts
BUILD := $(TOP)/build

# MTOP - variable required by clean-build - path to the root clean-build directory
# Note: normally, MTOP is defined in command line, but only for this example, MTOP may be deduced automatically
MTOP := $(abspath $(TOP)/../../..)

# include clean-build base definitions and support for CONFIG and OVERRIDES variables
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# autoconfigure for building C/C++ sources
# Note: more includes may be needed to prepare for building other source types: Java, etc.
include $(MTOP)/configure/c.mk

endif # TOP
