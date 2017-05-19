# the only case when TOP is defined - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# specify version of clean-build required by this project
override CLEAN_BUILD_REQUIRED_VERSION := 0.6.0

# TOP - project root directory
# define this variable for referencing project files: sources, makefiles, include paths, etc.
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# BUILD - variable required by clean-build - path to built artifacts
#
# Note: do not take BUILD from environment - reset it
# Note: if BUILD is defined in make command line, it will not be reset
BUILD:=

ifndef BUILD
# ok, BUILD was not specified in make command line, set default value
override BUILD := $(TOP)/build
endif

# clean-build generated config file (optional)
#
# Note: generated config file will remember values of command-line or overridden variables, including BUILD variable.
#  But, because config file is referenced via $(BUILD), to use non-default BUILD value,
#  it must be specified in command line every time, for example:
#  $ make BUILD:=/tmp
#
# Note: by completing 'distclean' goal, defined by clean-build, $(BUILD) directory will be deleted
#  - together with $(CONFIG_FILE) generated under $(BUILD)
override CONFIG_FILE := $(BUILD)/conf.mk

# define variable - for referencing clean-build files (defs.mk, parallel.mk, ...) in project makefiles
#
# Note: following general rules for working with variables,
#  this variable SHOULD NOT be taken from environment, instead,
#  it should be defined either in command line or in generated $(CONFIG_FILE)
#
# for this example MTOP may be defined automatically
MTOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../../)

# major.minor.patch
override PRODUCT_VER := 1.0.0

# next variables are needed for generating resource file under Windows
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Michael M. Builov
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

endif
