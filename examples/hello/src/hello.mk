#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add rules (target templates) for building C/C++ sources
include $(dir $(lastword $(MAKEFILE_LIST)))../make/c.mk

# include definition of 'exe_test_rule_r' macro - which generates a rule used for testing built C/C++ executables
include $(CBLD_ROOT)/extensions/ctest.mk

# we will build S-variant of 'hello' executable - the one which is statically linked with the C runtime
# note: variable 'exe' - specifies the name of built target executable and its optional variants
# note: variable 'src' - specifies a list of C/C++ sources from which to build the target (executable)
# note: variables 'exe' and 'src' - processed by the target templates added above via "include ...make/c.mk"
exe := hello S
src := hello.c

# define next rules only if 'check' is in the make goals list
ifneq (,$(filter check,$(MAKECMDGOALS)))

# define rules for testing built executable and creating 'hello.out' output file
?# note: 'exe_test_rule_r' returns an absolute path to the generated output file - save returned path in "local" variable 'out'
?# note: the same path value may be obtained as: $(addsuffix .out,$(call all_targets,exe))
?# note: 'exe_test_rule_r' macro uses a value of defined above 'exe' variable
?out := $(exe_test_rule_r)

# define custom rule - print output of tested executable to stderr, for this:
# 1) call 'set_makefile_info_r' - set makefile information for 'hello' (an introduced phony target) - this information is used by the
#  'suppress' function in "makefile info" mode (enabled via "$(MAKE) M=1"); 'suppress' function pretty-prints what a rule is doing
# 2) call 'suppress_targets_r' - register 'hello' as a leaf target - in those rule the 'suppress' function is used for updating percent
#  of building targets
#
# Note: output of any rule must go to stderr (i.e. >&2) or to file (e.g. >file), stdout is used exclusively by clean-build
#  only for logging executed commands - this is needed for the (optional) generation of a build-script (in "verbose" mode)
# Note: must not use "local" variables (e.g. 'out') in rule bodies - may use only target-specific, automatic or "global"
#  (registered by 'set_global' macro) variables, here use $| (automatic variable) - list of order-only dependencies of the target,
#  for this rule it contains only the $(out)
# Note: 'sh_cat' - one of clean-build defined shell utilities functions
$(call suppress_targets_r,$(call set_makefile_info_r,hello)):| $(out)
	$(call suppress,CAT,$|)$(call sh_cat,$|) >&2

# to complete clean-build predefined 'check' goal, it is needed to update our phony target 'hello'
check: hello

# specify that 'hello' - is not a file, it is a PHONY target
.PHONY: hello

endif # check

# expand target templates - define target files and rules how to build them
$(define_targets)
