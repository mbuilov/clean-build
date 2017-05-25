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

# next variables are needed for generating resource file under Windows
# and for generating pkg-config files for libraries
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
#  - for the case when BUILD is defined in command line also as recursive variable
CONFIG = $(BUILD)/conf.mk

# adjust project defaults, add missing definitions
# CONFIG - may be either user-defined one (specified in command line) or previously clean-build generated config file
# Note: if CONFIG is user-defined one, it also may try to source clean-build generated config file
# Note: if CONFIG is user-defined and non-empty, it must exist
# Note: if CONFIG is clean-build generated one, it may not exist
ifneq (,$(CONFIG))
ifeq ("command line","$(origin CONFIG)")
ifeq (,$(wildcard $(CONFIG)))
$(error cannot include $(CONFIG))
endif
endif
-include $(CONFIG)
endif

endif # TOP
