#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rule templates for testing built executables - for the 'check' goal

ifndef cb_target_makefile
$(error 'defs.mk' must be included prior this file)
endif

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for the 'check' or 'clean' goals
exe_test_rule:=
exe_test_rule_ret:=

else # check or clean

CBLD_TEST_COLOR ?= [36m

# run (built) $(exe) and send its stdout to $(exe).out
# $1 - auxiliary parameters to pass to the executable (properly escaped by 'shell_escape' macro)
# $2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
# $3 - dll search paths separated by $(pathsep) - appended to $(dll_path_var) (i.e. PATH or LD_LIBRARY_PATH environment variable)
# $4 - environment variables to set for the executable, in form VAR=value, spaces must be replaced with $(space)
# $r - $(call form_trg,exe,$v) where $v - variant of the $(exe)
# note: define, but do not export variables $4 as target-specific ones here - to generate correct .bat/.sh build script in verbose mode
define exe_test_rule_templ
$(call std_target_vars,$r.out)
$(patsubst %,$r.out: %$(newline),$4)$r.out: $r
	$$(call suppress,TEST,$$@)$$(call run_tool,$$< $(subst $$,$$$$,$1) > $$@,$3,,$(foreach =,$4,$(firstword $(subst =, ,$=))))
endef

# it may be needed to create simlinks to just built shared libraries to be able to run tested executable
CBLD_TEST_NEED_SHLIB_SIMLINKS ?= $(filter-out WIN%,$(CBLD_OS))

ifdef CBLD_TEST_NEED_SHLIB_SIMLINKS

ifeq (,$(filter-out undefined environment,$(origin test_create_shlib_simlinks)))
include $(dir $(lastword $(MAKEFILE_LIST)))so_simlinks.mk
endif

# create simlinks to shared libraries to be able to run tested executable
# $$2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
$(call define_prepend,exe_test_rule_templ,$$r.out:| $$(call \
  test_form_shlib_simlinks,$$2)$$(call test_create_shlib_simlinks,$$2)$(newline))

endif # CBLD_TEST_NEED_SHLIB_SIMLINKS

# for the 'check' goal, run built executable (all variants of it)
# $1 - auxiliary parameters to pass to the executable (properly escaped by 'shell_escape' macro)
# $2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
# $3 - dll search paths separated by $(pathsep) - appended to $(dll_path_var) (i.e. PATH or LD_LIBRARY_PATH environment variable)
# $4 - environment variables to set for the executable, in form VAR=value, spaces must be replaced with $(space)
exe_test_rule = $(foreach v,$(call get_variants,exe),$(foreach r,$(call form_trg,exe,$v),$(eval $(exe_test_rule_templ))))

# same as 'exe_test_rule', but return a list of output files created by tested executables (one file for each variant)
exe_test_rule_ret = $(foreach v,$(call get_variants,exe),$(foreach r,$(call form_trg,exe,$v),$(eval $(exe_test_rule_templ))$r.out))

endif # check or clean

# remember value of CBLD_TEST_NEED_SHLIB_SIMLINKS - it may be taken from the environment
$(call config_remember_vars,CBLD_TEST_NEED_SHLIB_SIMLINKS)

# makefile parsing first phase variables
cb_first_phase_vars += exe_test_rule exe_test_rule_ret exe_test_rule_templ

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_TEST_COLOR CBLD_TEST_NEED_SHLIB_SIMLINKS cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: c_test
$(call set_global,exe_test_rule=exe exe_test_rule_ret=exe exe_test_rule_templ=r,c_test)
