#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
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

# clean-build provides default rule for the 'distclean' goal, do not handle it here
ifneq (distclean,$(MAKECMDGOALS))

# list of sub-makefiles
# Note: may use any variable to specify a list of sub-makefiles,
#  it is forbidden to redefine only specially registered "global" variables
# Note: by convention, use variables in lower case as "local" ones,
#  variables in upper case may be defined in the environment
# Note: if path is not absolute, 'process_submakes' macro assumes that it is
#  relative to the directory of current makefile
to_make := src/hello.mk

# we need version info under Windows - use predefined rule to generate it
# Note: CBLD_OS - target operating system - one of the variables required by
#  clean-build that must be defined for the build
# Note: CBLD_ROOT - path to clean-build - variable defined by 'make/project.mk'
ifneq (,$(filter WIN%,$(CBLD_OS)))
to_make += $(CBLD_ROOT)/extensions/version
endif

# process sub-makefiles and directories specified in our local 'to_make' variable
# Note: 'process_submakes' - macro defined by the included above 'make/submakes.mk'
$(call process_submakes,$(to_make))

endif # !distclean
