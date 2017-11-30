#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# project configuration file

# Note: this is a modified copy of the $(CLEAN_BUILD_DIR)/stub/project.mk

# NOTE *********************************************************************************
# according to the clean-build principles, it is acceptable to use environment variables
# only while autoconfiguration: in this file and the files included by this one
# **************************************************************************************

# Assume custom project has the following directory structure:
# 
# +- my_project/
#   +- make/
#   |  |- project.mk    (modified copy of this file)
#   |  |- overrides.mk  (support for 'config' goal and OVERRIDES variable)
#   |  |- parallel.mk   (support for sub-makefiles)
#   |  |- c.mk          (support for building C/C++ sources)
#   |  ...
#   +-- src/
#   +-- include/
#   ...
#
# where 'make' - directory of the project build system,
#  some of the files in it can be copies of the files of clean-build 'stub' directory

# the only case when variable TOP is overridden - after completing project configuration
ifneq (override,$(origin TOP))

# TOP - project root directory
# Note: TOP may be used in target makefiles for referencing sources, other makefiles, include paths, etc.
# Note: define TOP according to the project directory structure shown above - path to 'my_project' folder
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# BUILD - path to the root directory of all built artifacts
# Note: this variable is required by clean-build and must be defined prior including core clean-build files
# Note: $(BUILD) directory is automatically created by clean-build when building targets
#  and automatically deleted by the predefined 'distclean' goal
BUILD := $(TOP)/build

# version of clean-build required by this custom project
CLEAN_BUILD_REQUIRED_VERSION := 0.9.0

# next variables are needed for generating:
# - header file with version info (see $(MTOP)/extensions/version/version.mk)
# - under Windows, resource files with version info (see $(MTOP)/compilers/msvc/stdres.mk)
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

# global product version
# Note: this is default value of MODVER - per-module version number
# format: major.minor.patch
PRODUCT_VER := 1.0.0

# Note: may pre-define clean-build macros here - predefined values will override default ones, e.g:
#  SUPPORTED_TARGETS := DEVEL PRODUCTION

# MTOP - path to clean-build build system
# Note: normally MTOP is defined in command line,
#  but for this example, MTOP may be deduced automatically
MTOP := $(abspath $(TOP)/../..)

# include core clean-build definitions, processing of CONFIG and OVERRIDES variables,
#  define MTOP variable - path to clean-build
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# Note: may redefine core clean-build macros here, e.g.:
#  $(call define_prepend,DEF_HEAD_CODE,$$(info target makefile: $$(TARGET_MAKEFILE)))

# autoconfigure for building C/C++ sources
include $(MTOP)/configure/c_conf.mk

# Note: more autoconfigure includes may be added here to prepare for building other source types:
#  Java: include $(MTOP)/configure/java.mk
#  etc.

endif # TOP
