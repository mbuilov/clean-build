# the only case when TOP is defined - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# TOP - project root directory
# define this variable for referencing project files: sources, makefiles, include paths, etc.
# note: TOP variable is not used by clean-build
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# specify version of clean-build build system required by this project
CLEAN_BUILD_REQUIRED_VERSION := 0.6.3

# BUILD - variable required by clean-build - path to built artifacts
BUILD := $(TOP)/build

# clean-build generated config file (optional)
#
# Note: generated config file will remember values of command-line or overridden variables, including BUILD variable.
#  But, if config file is referenced via $(BUILD), then to use non-default BUILD value,
#  it must be specified in command line every time, for example:
#  $ make BUILD=~/build
#
# Note: by completing 'distclean' goal, defined by clean-build, $(BUILD) directory will be deleted
#  - together with $(CONFIG_FILE), if it was generated under $(BUILD)
#
# note: define CONFIG_FILE as recursive variable - for the case when BUILD is defined in command line as recursive
# note: clean-build will override CONFIG_FILE to make it non-recursive (simple)
CONFIG_FILE = $(BUILD)/conf.mk

# major.minor.patch
PRODUCT_VER := 1.0.0

# next variables are needed for generating resource file under Windows
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

# define variable - for referencing clean-build files (defs.mk, parallel.mk, ...) in project makefiles
#
# Note: because use of environment variables in makefiles is discouraged,
#  this variable SHOULD NOT be taken from environment, instead, it should be defined
#  in command line (and later it may be taken from generated $(CONFIG_FILE))
#
# Only for this example MTOP may be defined automatically
# note: MTOP variable is not used by clean-build
MTOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../../)

# source variables overrides from previously generated config file, if it exist
-include $(CONFIG_FILE)

endif
