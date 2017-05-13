# 1) to clean up all created files and directories, run:
# $ make distclean

# 2) to build everything, run:
# $ make

# 3) to build everything and execute test, run:
# $ make check

# setup project variables
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk

# source clean-build definitions and functions
include $(MTOP)/defs.mk

# distclean target defined in $(MTOP)/defs.mk
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

TO_MAKE := hello.mk

# we need version info under Windows
ifeq (WINXX,$(OS))
TO_MAKE += $(MTOP)/exts/version
endif

# process makefiles and directories specified in TO_MAKE variable
include $(MTOP)/parallel.mk

endif # !distclean
