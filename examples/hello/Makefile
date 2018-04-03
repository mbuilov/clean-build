#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# 1) to build everything, run:
# $ make

# 2) to build everything and execute a test, run:
# $ make check

# 3) to delete all built artifacts - whole 'build' directory, just run:
# $ make distclean

# add support for processing sub-makefiles - define 'process_submakes' macro
include $(dir $(lastword $(MAKEFILE_LIST)))make/submakes.mk

# list of sub-makefiles
# Note: may use any variable to specify a list of sub-makefiles
#  (it is forbidden to redefine only specially registered "global" variables)
# Note: by convention, use variables in lower case as "local" ones,
#  variables in upper case may be defined in the environment
to_make:=

# clean-build provides default rule for the 'distclean' goal - delete whole 'build' directory,
#  do not need to process sub-makefiles for that
ifneq (distclean,$(MAKECMDGOALS))

# Note: if path is not absolute, 'process_submakes' macro assumes that it is
#  relative to the directory of current makefile
to_make += src/hello.mk

# Under Windows, executables and dynamic libraries should have version info.
# clean-build provides a rule for generating resource file with such info.
# Generated resource file will include "product_names.h" - a header with version info constants.
# CBLD_NEED_PRODUCT_NAMES_H - not empty and not 0 if "product_names.h" is needed (e.g. for the resource file)
# note: CBLD_NEED_PRODUCT_NAMES_H may be already defined by the clean-build if building under Windows
# Note: by convention, variables that may be defined in the environment, should be in UPPER case
# Note: to not overwrite environment variables, use ?= operator
CBLD_NEED_PRODUCT_NAMES_H ?=

# generate "product_names.h" if needed
# Note: CBLD_ROOT - path to clean-build - variable defined by 'make/project.mk'
ifneq (,$(CBLD_NEED_PRODUCT_NAMES_H:0=))
to_make += $(CBLD_ROOT)/extensions/version
endif

# remember values of variables possibly taken from the environment
$(call config_remember_vars,CBLD_NEED_PRODUCT_NAMES_H)

endif # !distclean

# process sub-makefiles and directories specified in our local 'to_make' variable
$(call process_submakes,$(to_make))
