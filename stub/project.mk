#------------------------------- delete this header --------------------------------------
#
# Note: This file should be copied to the directory of the project build system
#         and modified appropriately for the custom project
#
# Note: this file is under public domain, it may be freely modified by the project authors
#-----------------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/project.mk
# description:   project configuration makefile

# Assume custom project has the following directory structure:
#
# +- my_project/
#   +- make/
#   |  |- project.mk    (modified copy of this file)
#   |  |- overrides.mk  (support for 'config' goal and processing of 'pr_overrides' variable)
#   |  |- submakes.mk   (support for sub-makefiles)
#   |  |- c.mk          (support for building C/C++ sources)
#   |  ...
#   +-- src/
#   +-- include/
#   ...
#
# where 'make' - directory of the project build system, some of the files in it can be the copies of the files from
#  the clean-build 'stub' directory

# the only case when variable 'top' get overridden - after completing project configuration
ifneq (override,$(origin top))

# save values of the environment variables, define 'clean_build_required_version' variable
include $(dir $(lastword $(MAKEFILE_LIST)))prepare.mk

# top - project root directory
# Note: 'top' may be used in the target makefiles for referencing sources, other makefiles, project include paths, etc.
# Note: define 'top' according to the project directory structure shown above - path to 'my_project' folder
# Note: variable 'top' may be renamed/redefined by the project authors, this variable is not used by the clean-build
override top := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# cb_build - path to the directory where artifacts (object files, libraries, executables, etc.) are created
# Note: this variable is required by the clean-build and must be defined prior including core clean-build files
# Note: $(cb_build) directory is automatically created by the clean-build when building targets and automatically
#  deleted by the predefined 'distclean' goal
# Note: if needed, default value of variable 'cb_build' be freely changed by the project authors or specified in the
#  command line, e.g.: make -f my_project.mk cb_build=/tmp/build
cb_build := $(top)/build

# next variables are needed for generating:
# - header file with version info (see $(CBLD_ROOT)/extensions/version/version.mk)
# - under Windows, resource files with version info (see $(CBLD_ROOT)/compilers/msvc/stdres.mk)
# Note: default values should be likely changed by the project authors
product_names_h          := product_names.h
product_name             := Sample app
product_vendor_name      := Unkown Company/Author
product_vendor_copyright := Copyright (C) 2018 Unkown Company/Author

# global product version
# Note: this is the default value of 'modver' variable - per-module version number
# format: major.minor.patch
product_version := 1.0.0

# Note: may pre-define other clean-build macros here - predefined values will override default ones, e.g:
#  project_supported_targets := DEVEL PRODUCTION

# include core clean-build definitions, processing of the 'cb_config' and 'pr_overrides' variables,
#  check that the CBLD_ROOT variable - path to the clean-build - is defined
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# Note: may redefine core clean-build macros here, e.g.:
#  $(call define_prepend,cb_def_head_code,$$(info target makefile: $$(cb_target_makefile)))

endif # top
