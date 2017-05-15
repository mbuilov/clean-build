# setup project variables
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk

# include templates for building C/C++ sources
include $(MTOP)/c.mk

# add definitions for running built executable
include $(MTOP)/exts/ctest.mk

# we will build S-variant of 'hello' executable - with statically linked C runtime
EXE := hello S
SRC := hello.c

# will run built executable and create .out file
$(DO_TEST_EXE)

# add makefile info for phony target 'hello' (this info is used by SUP function)
$(call SET_MAKEFILE_INFO,hello)

# if executable output exist - print it
# note: $| - automatic variable - first order-only dependency of the target
# note: pass 1 as 4-th argument to SUP function to not update percents of executed makefiles
hello: | $(call FORM_TRG,EXE,S).out
	$(call SUP,CAT,$|,,1)$(call CAT,$|) >&2

# to complete 'check' goal, need to update 'hello'
# note: 'check' goal is one of clean-build predefined goals
check: hello

# hello - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(DEFINE_TARGETS)
