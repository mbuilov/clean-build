#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# 1) to build everything, run:
# $ make

# 2) to build everything and execute a test, run:
# $ make check

# 3) to delete built artifacts - 'build' directory, just run:
# $ make distclean

# add support for processing sub-makefiles
include $(dir $(lastword $(MAKEFILE_LIST)))make/submakes.mk

# list of sub-makefiles
# Note: may use any variable to specify a list of sub-makefiles,
#  it is forbidden to redefine only specially registered "global" variables
# Note: by convention, use variables in lower case as "local" ones,
#  variables in upper case may be defined in the environment
to_make:=

# clean-build provides default rule for the 'distclean' goal - delete whole 'build' directory,
#  do not need to process sub-makefiles for that
ifneq (distclean,$(MAKECMDGOALS))

# Note: if path is not absolute, 'process_submakes' macro assumes that it is
#  relative to the directory of current makefile
to_make += src/hello.mk

# Under Windows, executables and dynamic libraries should have version info - use predefined
#  rule to generate "product_names.h", which is included in the version info resource file.
# CBLD_GENERATE_PRODUCT_NAMES_H - not empty and not 0 if "product_names.h" should be generated
# note: CBLD_GENERATE_PRODUCT_NAMES_H may be already defined by the clean-build if building under Windows
CBLD_GENERATE_PRODUCT_NAMES_H ?=

# Note: CBLD_ROOT - path to clean-build - variable defined by 'make/project.mk'
ifneq (,$(CBLD_GENERATE_PRODUCT_NAMES_H:0=))
to_make += $(CBLD_ROOT)/extensions/version
endif

endif # !distclean

# process sub-makefiles and directories specified in our local 'to_make' variable
# Note: 'process_submakes' - macro defined by the included above 'make/submakes.mk'
$(call process_submakes,$(to_make))
