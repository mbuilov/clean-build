# stub of a project configuration makefile,
# this file is normally copied and modified appropriately for the custom project

# Note: this file is under public domain, it may be freely modified by the project authors

# NOTE *********************************************************************************
# according to the clean-build principles, it is acceptable to use environment variables
# only while autoconfiguration: in this file and the files included by this one
# **************************************************************************************

# Assume custom project have directory structure organized as follows:
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
# where 'make' directory - files of the project build system, some of them
#  may be copied and modified from the clean-build 'stub' directory

# the only case when variable TOP is overridden - after completing project configuration
ifneq (override,$(origin TOP))

# TOP - project root directory
# Note: TOP may be used in target makefiles for referencing sources, other makefiles, include paths, etc.
# Note: define TOP according to the project directory structure shown above - path to 'my_project' folder
override TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# BUILD - path to directory of built artifacts
# Note: this variable is required by clean-build and must be defined prior including clean-build files
# Note: $(BUILD) directory is automatically created by clean-build when building targets
#  and automatically deleted by the predefined 'distclean' goal
BUILD := $(TOP)/build

# version of clean-build required by this custom project
CLEAN_BUILD_REQUIRED_VERSION := 0.9.0

# next variables are needed for generating:
# - header file with version info (see $(MTOP)/extensions/version/version.mk)
# - under Windows, resource files with version info (see $(MTOP)/compilers/msvc/stdres.mk)
PRODUCT_NAMES_H  := product_names.h
VENDOR_NAME      := Unkown Company/Author
PRODUCT_NAME     := Sample app
VENDOR_COPYRIGHT := Copyright (C) 2015-2017 Unkown Company/Author

# global product version
# Note: this is default value for MODVER - per-module version number
# format: major.minor.patch
PRODUCT_VER := 1.0.0

# Note: may pre-define clean-build macros here - predefined values will override default ones, e.g:
#  SUPPORTED_TARGETS := DEVEL PRODUCTION

# include core clean-build definitions, processing of CONFIG and OVERRIDES variables,
#  define of MTOP variable - path to clean-build
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# Note: may redefine core clean-build macros here, e.g.:
#  $(call define_prepend,DEF_HEAD_CODE,$$(info target makefile: $$(TARGET_MAKEFILE)))

# autoconfigure for building C/C++ sources
#include $(MTOP)/configure/c_conf.mk

# Note: more autoconfigure includes may be added here to prepare for building other source types:
#  Java: include $(MTOP)/configure/java.mk
#  etc.

endif # TOP
