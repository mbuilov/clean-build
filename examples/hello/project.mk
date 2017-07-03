#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# the only case when TOP is defined - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# TOP - project root directory
# define this variable for referencing project files: sources, makefiles, include paths, etc.
# Note: TOP variable is not used by clean-build
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# specify version of clean-build build system required by this project
CLEAN_BUILD_REQUIRED_VERSION := 0.6.3

# BUILD - variable required by clean-build - path to built artifacts
BUILD := $(TOP)/build

# global product version
# Note: this is default value of MODVER - per-module version number
# format: major.minor.patch
PRODUCT_VER := 1.0.0

# next variables are needed for generating:
# - header file with version info (see $(MTOP)/exts/version/version.mk)
# - under Windows, resource files with version info (see $(MTOP)/WINXX/cres.mk)
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

# define variable - for referencing clean-build files (defs.mk, parallel.mk, ...) in project makefiles
#
# Note: because use of environment variables in makefiles is discouraged,
#  this variable SHOULD NOT be taken from environment, instead, it should be defined
#  in command line (and later it may be taken from generated $(CONFIG))
#
# But, only for this example MTOP may be determined automatically
# Note: MTOP variable is not used by clean-build
MTOP := $(abspath $(TOP)/../..)

# optional, clean-build generated config file (while completing 'conf' goal)
#
# Note: generated $(CONFIG) file will remember values of command-line or overridden variables;
#  by sourcing $(CONFIG) file, these variables are will be restored
#  and only new command-line values may override restored variables
#
# Note: by completing 'distclean' goal, defined by clean-build, $(BUILD) directory will be deleted
#  - together with $(CONFIG) file, if it was generated under $(BUILD)
#
# Note: define CONFIG as recursive variable
#  - for the case when BUILD is redefined in next included $(OVERRIDES) makefile
CONFIG = $(BUILD)/conf.mk

# adjust project defaults
# OVERRIDES may be specified in command line, which overrides next empty definition
OVERRIDES:=
ifdef OVERRIDES
ifeq (,$(wildcard $(OVERRIDES)))
$(error cannot include $(OVERRIDES))
endif
include $(OVERRIDES)
endif

# source clean-build generated config file, if it exist
-include $(CONFIG)

# clean-build path must be defined, to include clean-build definitions
ifndef MTOP
$(error MTOP - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: MTOP=/usr/local/clean-build or MTOP=C:\User\clean-build)
endif

endif # TOP
