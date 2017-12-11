#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add rules for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))../make/c.mk

# add support for testing built executables - define DO_TEST_EXE macro
include $(MTOP)/extensions/ctest.mk

# we will build S-variant of 'hello' executable - one with statically linked C runtime
EXE := hello S
SRC := hello.c

# generate rules for testing built executable and creating 'hello.out' output file
# save the name of generated output file (the same as $(addsuffix .out,$(call ALL_TARGETS,EXE)))
OUT := $(DO_TEST_EXE_RET)

# set makefile information for the 'hello' - a phony target defined below
# (this information is used by the SUP function, which pretty-prints what a rule is doing)
# Note: SET_MAKEFILE_INFO - one of predefined clean-build macros
$(call SET_MAKEFILE_INFO,hello)

# define custom rule - print output of tested executable to stderr
# Note: any output of rules should go to stderr, stdout is used
#  by clean-build only for printing executed commands - this is
#  needed for the (optional) generation of build-script
# Note: $| - automatic variable - list of order-only dependencies of the target (but here is the only one - $(OUT))
# Note: pass 1 as 4-th argument to SUP function to not update percents of executed makefiles
hello: | $(OUT)
	$(call SUP,CAT,$|,,1)$(call CAT_FILE,$|) >&2

# to complete predefined 'check' goal, it is needed to update our target 'hello'
check: hello

# specify that 'hello' - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(DEFINE_TARGETS)
