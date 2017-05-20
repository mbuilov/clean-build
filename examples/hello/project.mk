# the only case when TOP is defined - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# specify version of clean-build build system required by this project
# note: do not take CLEAN_BUILD_REQUIRED_VERSION value from environment
CLEAN_BUILD_REQUIRED_VERSION:=

# if CLEAN_BUILD_REQUIRED_VERSION is not specified in command line, set default value
# note: CLEAN_BUILD_REQUIRED_VERSION must be overridden,
# because clean-build defines it as CLEAN_BUILD_REQUIRED_VERSION := 0.0.0
ifndef CLEAN_BUILD_REQUIRED_VERSION
override CLEAN_BUILD_REQUIRED_VERSION := 0.6.0
endif

# TOP - project root directory
# define this variable for referencing project files: sources, makefiles, include paths, etc.
# note: override TOP value occasionally set in environment or in command line
# note: TOP variable is not used by clean-build
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# BUILD - variable required by clean-build - path to built artifacts
# note: do not take BUILD from environment - set default value here
BUILD:=

# if BUILD is not specified in command line, set default value
# note: BUILD must be overridden,
# because clean-build defines it as BUILD:=
ifndef BUILD
override BUILD := $(TOP)/build
endif

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
# Note: do not take CONFIG_FILE from environment
CONFIG_FILE:=

# if CONFIG_FILE is not specified in command line, set default value
# note: CONFIG_FILE must be overridden,
# because clean-build defines it as CONFIG_FILE:=
ifndef CONFIG_FILE
# note: define CONFIG_FILE as recursive variable - in case if BUILD is also recursive
override CONFIG_FILE = $(BUILD)/conf.mk
endif

# define variable - for referencing clean-build files (defs.mk, parallel.mk, ...) in project makefiles
#
# Note: because use of environment variables in makefiles is discouraged,
#  this variable SHOULD NOT be taken from environment, instead,
#  it should be defined either in command line or in generated $(CONFIG_FILE)
#
# for this example MTOP may be defined automatically
# note: MTOP variable is not used by clean-build
MTOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../../)

# major.minor.patch
# note: PRODUCT_VER must be overridden,
# because clean-build defines it as PRODUCT_VER := 0.0.1
override PRODUCT_VER := 1.0.0

# next variables are needed for generating resource file under Windows
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

endif
