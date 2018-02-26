#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add rules for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))../make/c.mk

# include definition of 'exe_test_rule_ret' macro - which generates a rule used for testing built executables
include $(CBLD_ROOT)/extensions/ctest.mk

# we will build S-variant of 'hello' executable - the one which is statically linked with the C runtime
exe := hello S
src := hello.c

# generate rules for testing built executable and creating 'hello.out' output file
# save path to the generated output file in "local" variable 'out' (variable name chosen arbitrary)
# Note: the same path value may be obtained as: $(addsuffix .out,$(call all_targets,exe))
# Note: 'exe_test_rule_ret' macro uses the value of defined above 'exe' variable
out := $(exe_test_rule_ret)

# set makefile information for 'hello' - a phony target defined below
#  (this information is used by 'suppress' function, which pretty-prints what a rule is doing)
# Note: 'set_makefile_info' - one of clean-build predefined macros
$(call set_makefile_info,hello)

# define custom rule - print output of tested executable to stderr
# Note: output of rules must go to stderr, stdout is used by clean-build only for logging
#  executed commands - this is needed for the (optional) generation of a build-script
# Note: must not use "local" variables in rule bodies - may use target-specific or automatic variables,
#  e.g. $| - list of order-only dependencies of a target (here it contains only the $(out))
# Note: 'suppress' and 'cat_file' - are clean-build predefined macros
hello: | $(out)
	$(call suppress,CAT,$|)$(call cat_file,$|) >&2

# to complete clean-build predefined 'check' goal, it is needed to update our target 'hello'
check: hello

# specify that 'hello' - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(define_targets)
