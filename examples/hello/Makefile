#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# 1) to clean up all created files and directories, run:
# $ make distclean

# 2) to build everything, run:
# $ make

# 3) to build everything and execute test, run:
# $ make check

# add support for processing sub-makefiles
include $(dir $(lastword $(MAKEFILE_LIST)))make/p.mk

# clean-build provides default rule for 'distclean' goal
ifneq (distclean,$(MAKECMDGOALS))

# list of sub-makefiles
TO_MAKE := src/hello.mk

# we need version info under Windows
ifeq (WINXX,$(OS))
TO_MAKE += $(MTOP)/exts/version
endif

# process sub-makefiles and directories specified in TO_MAKE variable
$(call PROCESS_SUBMAKES,$(TO_MAKE))

endif # !distclean
