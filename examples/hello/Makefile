#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# 1) to delete 'build' directory of built files, run:
# $ make distclean

# 2) to build everything, run:
# $ make

# 3) to build everything and execute test, run:
# $ make check

# add support for processing sub-makefiles
include $(dir $(lastword $(MAKEFILE_LIST)))make/parallel.mk

# clean-build provides default rule for the 'distclean' goal, do not handle it here
ifneq (distclean,$(MAKECMDGOALS))

# list of sub-makefiles
# Note: may use any variable to specify a list of sub-makefiles,
#  it is forbidden to redefine only specially registered 'global' variables
TO_MAKE := src/hello.mk

# we need version info under Windows - use predefined rule to generate it
# Note: OS - target operating system - one of the required
#  by clean-build variables that must be defined for the build
# Note: MTOP - path to clean-build - variable defined by 'make/project.mk'
ifneq (,$(filter WIN%,$(OS)))
TO_MAKE += $(MTOP)/extensions/version
endif

# process sub-makefiles and directories specified in our TO_MAKE variable
# Note: PROCESS_SUBMAKES - macro defined by the included above make/parallel.mk
$(call PROCESS_SUBMAKES,$(TO_MAKE))

endif # !distclean
