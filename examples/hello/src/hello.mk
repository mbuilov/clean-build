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

# define rules for testing built executable and creating 'hello.out' output file
# note: 'exe_test_rule_ret' returns an absolute path to the generated output file - save returned path in "local" variable 'out'
# note: the same path value may be obtained as: $(addsuffix .out,$(call all_targets,exe))
# note: 'exe_test_rule_ret' macro uses a value of defined above 'exe' variable
out := $(exe_test_rule_ret)

# define custom rule - print output of tested executable to stderr, for this:
# 1) set makefile information for 'hello' (an introduced phony target) - this information is used by the 'suppress' function
#   in "makefile info" mode (enabled via "$(MAKE) M=1"); 'suppress' function pretty-prints what a rule is doing
# 2) register 'hello' as a leaf target - in those rule the 'suppress' function is used for updating percent of building targets
#
# Note: output of rules must go to stderr, stdout is used by clean-build only for logging executed commands - this is needed
#  for the (optional) generation of a build-script
# Note: must not use "local" variables (e.g. 'out') in rule bodies - may use only target-specific, automatic or "global"
#  (registered by 'set_global' macro) variables, here use $| (automatic variable) - list of order-only dependencies of the target,
#  for this rule it contains only the $(out)
# Note: 'cat_file' - one of clean-build defined shell utilities functions
$(call suppress_targets_ret,$(call set_makefile_info_ret,hello)): | $(out)
	$(call suppress,CAT,$|)$(call cat_file,$|) >&2

# to complete clean-build predefined 'check' goal, it is needed to update our target 'hello'
check: hello

# specify that 'hello' - is not a file, it is a PHONY target
.PHONY: hello

# define targets and rules how to build them
$(define_targets)
