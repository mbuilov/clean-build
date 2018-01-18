#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/project.mk
# description:   project configuration makefile

# Assume custom project has the following directory structure:
#
# +- my_project/
#   +- make/
#   |  |- project.mk    (modified copy of this file)
#   |  |- prepare.mk    (preparation for project configuration)
#   |  |- overrides.mk  (support for 'config' goal and processing of CBLD_OVERRIDES variable)
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

# remember values of the environment variables, define 'clean_build_required_version' variable
include $(dir $(lastword $(MAKEFILE_LIST)))prepare.mk

# top - project root directory
# Note: 'top' may be used in the target makefiles for referencing sources, other makefiles, project include paths, etc.
# Note: define 'top' according to the project directory structure shown above - path to 'my_project' folder
# Note: variable 'top' is not used by the clean-build makefiles
override top := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# CBLD_BUILD - path to the directory where artifacts (object files, libraries, executables, etc.) are created
# Note: this variable is required by the clean-build and must be defined prior including core clean-build files
# Note: $(CBLD_BUILD) directory is automatically created by the clean-build when building targets and automatically
#  deleted by the clean-build predefined 'distclean' goal
# Note: CBLD_BUILD may be defined as a macro, for example:
#  CBLD_BUILD=/tmp/builds/$(notdir $(top))
CBLD_BUILD ?= $(top)/build

# next variables are needed for generating:
# - header file with version info (see $(CBLD_ROOT)/extensions/version/version.mk)
# - under Windows, resource files with version info (see $(CBLD_ROOT)/compilers/msvc/stdres.mk)
product_names_h   := product_names.h
product_name      := Sample app
product_vendor    := Michael M. Builov
product_copyright := Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build

# global product version
# Note: this is the default value of 'modver' variable - per-module version number
# format: major.minor.patch
product_version := 1.0.0

# Note: to export project variable, add it to 'project_exported_vars' list, e.g.:
#  export MY_VAR := my_value
#  project_exported_vars := MY_VAR
# - this is needed to allow to override environment variables and to avoid tracing of exported variables

# Note: may pre-define clean-build macros here - predefined values will override default ones, e.g:
#  project_supported_targets := DEVEL PRODUCTION

# CBLD_ROOT - path to clean-build build system
# Note: normally CBLD_ROOT is defined in command line or taken from the environment, but for this bundled
#  example it may be deduced automatically
CBLD_ROOT := $(abspath $(top)/../..)

# include core clean-build definitions, processing of CBLD_CONFIG and CBLD_OVERRIDES variables,
#  check that CBLD_ROOT variable - path to the clean-build - is defined
include $(dir $(lastword $(MAKEFILE_LIST)))overrides.mk

# Note: may redefine core clean-build macros here, e.g.:
#  $(call define_prepend,cb_def_head,$$(info target makefile: $$(cb_target_makefile)))

# Note: if some project variables may be taken from the environment (like PROJ_VAR ?= default value), add those
#  variables to the generated configuration makefile $(CBLD_CONFIG) here:
# $(call config_remember_vars,PROJ_VAR)

endif # top
