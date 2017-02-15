# 1) to clean up all created files and directories, run:
# $ make distclean

# 2) to build everything, run:
# $ make

# 3) to build everything and execure test, run:
# $ make check

include $(MTOP)/defs.mk

ifneq ($(filter distclean,$(MAKECMDGOALS)),)

distclean:
	$(call RM,$(CLOBBER_DIRS))

else # !distclean

TO_MAKE := hello.mk

# we need version info under Windows
ifneq ($(filter WINXX,$(OS)),)
TO_MAKE += version
endif

# 'check' is a fake target, without any rule to execute,
# test will run while completing 'all' target
check: all

include $(MTOP)/parallel.mk

endif # !distclean
