# 1) to clean up all created files and directories, run:
# $ make distclean

# 2) to build everything, run:
# $ make

# 3) to build everything and execute test, run:
# $ make check

# setup project variables
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk

# source clean-build definitions and function for processing sub-makefiles
include $(MTOP)/parallel.mk

# clean-build provides default rule for distclean goal
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

# list of sub-makefiles
TO_MAKE := hello.mk

# we need version info under Windows
ifeq (WINXX,$(OS))
TO_MAKE += $(MTOP)/exts/version
endif

# process sub-makefiles and directories specified in TO_MAKE variable
$(call PROCESS_SUBMAKES,$(TO_MAKE))

endif # !distclean
