# auto-determine $(TOP) value
include $(dir $(lastword $(MAKEFILE_LIST)))conf.mk

# include templates for building C/C++ sources
include $(MTOP)/c.mk

# add definitions for running built executable
include $(MTOP)/exts/ctest.mk

# we will build S-variant of 'hello' executable - with statically linked C runtime
EXE := hello S
SRC := hello.c

# will run built executable
$(DO_TEST_EXE)

# if executable output exist - print it
hello: | $(call FORM_TRG,EXE,S).out
	$(call SUP1,CAT,$|,,1)$(call CAT,$|) >&2

# to complete 'check' target, need to update 'hello' target
check: hello

# hello - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(DEFINE_TARGETS)
