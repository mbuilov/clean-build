#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(clean_build_dir)/stub/project.mk
# description:   project configuration makefile

# Assume custom project has the following directory structure:
# 
# +- my_project/
#   +- make/
#   |  |- project.mk    (modified copy of this file)
#   |  |- overrides.mk  (support for 'config' goal and OVERRIDES variable)
#   |  |- submakes.mk   (support for sub-makefiles)
#   |  |- c.mk          (support for building C/C++ sources)
#   |  ...
#   +-- src/
#   +-- include/
#   ...
#
# where 'make' - directory of the project build system,
#  some of the files in it can be the copies of the files of clean-build 'stub' directory

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
# - header file with version info (see $(CLEAN_BUILD)/extensions/version/version.mk)
# - under Windows, resource files with version info (see $(CLEAN_BUILD)/compilers/msvc/stdres.mk)
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

# CLEAN_BUILD - path to clean-build build system root directory
# Note: normally CLEAN_BUILD is defined in command line,
#  but for this example, CLEAN_BUILD may be deduced automatically
CLEAN_BUILD := $(abspath $(TOP)/../..)

# include core clean-build definitions, processing of CONFIG and OVERRIDES variables,
#  define CLEAN_BUILD variable - path to the clean-build root directory
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# Note: may redefine core clean-build macros here, e.g.:
#  $(call define_prepend,def_head_code,$$(info target makefile: $$(target_makefile)))

endif # TOP
