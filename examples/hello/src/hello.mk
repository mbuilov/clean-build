#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add rules for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))../make/c.mk

# add support for testing built executables
include $(MTOP)/exts/ctest.mk

# we will build S-variant of 'hello' executable - one with statically linked C runtime
EXE := hello S
SRC := hello.c

# generate rules for testing built executable and creating 'hello.out' file
$(DO_TEST_EXE)

# set makefile information for 'hello' - a phony target defined below
# (this info is used by the SUP function, which pretty-prints what a rule is doing)
$(call SET_MAKEFILE_INFO,hello)

# if executable output exist - print it to stderr
# note: all output of rules should go to the stderr, stdout is used
#  by the clean-build only for printing executed commands - this is
#  needed for build-script generation
# note: $| - automatic variable - list of order-only dependencies of the target
# note: pass 1 as 4-th argument to SUP function to not update percents of executed makefiles
hello: | $(call FORM_TRG,EXE,S).out
	$(call SUP,CAT,$|,,1)$(call CAT,$|) >&2

# to complete predefined 'check' goal, it is needed to update target 'hello'
check: hello

# specify that 'hello' - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(DEFINE_TARGETS)
