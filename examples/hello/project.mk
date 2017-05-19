# the only case when TOP is defined - after completing project configuration
ifneq (override,$(origin TOP))

# project configuration file

# specify version of clean-build required by this project
override CLEAN_BUILD_REQUIRED_VERSION := 0.6.0

# TOP - project root directory
# use this variable to reference project files: sources, makefiles, include paths, etc.
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# variable required by clean-build - path to built artifacts
BUILD := $(TOP)/build

# clean-build generated config file (optional)
# note: distclean goal, defined by clean-build will delete $(BUILD), together with $(CONFIG_FILE)
override CONFIG_FILE := $(BUILD)/conf.mk

# define variable - for referencing clean-build files in project makefiles
# note: following general rules for working with variables,
# this variable SHOULD NOT be taken from environment,
# instead, it should be defined either in command line or
# in generated config.mk (for example, included from project.mk)

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
