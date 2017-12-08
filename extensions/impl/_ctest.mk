#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define rules for testing built executables - for the 'check' goal

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for the 'check' or 'clean' goals
DO_TEST_ONE_EXECUTABLE:=
DO_TEST_EXE:=

else # check or clean

TEST_COLOR := [36m

# run $(EXE) and send its stdout to $(EXE).out
# $1 - auxiliary parameters to pass to the executable
# $2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (on WINDOWS) or to LD_LIBRARY_PATH (on UNIX-like OS) environment variable
# $4 - environment variables to set for the executable, in form VAR=value
# $r - $(call FORM_TRG,EXE,$v)
# note: do not export variables $4 as target-specific ones here - to generate correct .bat/.sh build script in verbose mode
define DO_TEST_EXE_TEMPLATE
$(call STD_TARGET_VARS,$r.out)
$r.out: $r
	$$(call SUP,TEST,$$@)$$(call RUN_TOOL,$$< $1 > $$@,$3,$(subst $$,$$$$,$4))
endef

# it may be needed to create simlinks to just built shared libraries to be able to run tested executable
TEST_NEED_SHLIB_SIMLINKS := $(filter-out WIN%,$(OS))

# ensure TEST_NEED_SHLIB_SIMLINKS is a non-recursive (simple) variable
override TEST_NEED_SHLIB_SIMLINKS := $(TEST_NEED_SHLIB_SIMLINKS)

ifdef TEST_NEED_SHLIB_SIMLINKS

ifeq (,$(filter-out undefined environment,$(origin TEST_CREATE_SHLIB_SIMLINKS)))
include $(dir $(lastword $(MAKEFILE_LIST)))so_simlinks.mk
endif

# create simlinks to shared libraries to be able to run tested executable
# $$2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
$(call define_prepend,DO_TEST_EXE_TEMPLATE,$$r.out:| $$(call \
  TEST_FORM_SHLIB_SIMLINKS,$$2)$$(call TEST_CREATE_SHLIB_SIMLINKS,$$2)$(newline))

endif # TEST_NEED_SHLIB_SIMLINKS

# for the 'check' goal, run one built executable
# $1 - auxiliary parameters to pass to the executable
# $2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable
# $4 - environment variables to set for the executable, in form VAR=value
# $r - tested executable, e.g. $(call FORM_TRG,EXE,$v)
# returns: output file created by the executable: $r.out
DO_TEST_ONE_EXECUTABLE = $(eval $(DO_TEST_EXE_TEMPLATE))$r.out

# for the 'check' goal, run built executable (all variants of it)
# $1 - auxiliary parameters to pass to the executable
# $2 - built shared libraries needed by the executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable
# $4 - environment variables to set for the executable, in form VAR=value
# returns: list of output files created by the executables (one file for each variant)
DO_TEST_EXE = $(foreach v,$(call GET_VARIANTS,EXE),$(foreach r,$(call FORM_TRG,EXE,$v),$(DO_TEST_ONE_EXECUTABLE)))

endif # check or clean

# protect variables from modifications in target makefiles
# note: do not trace calls to TEST_NEED_SHLIB_SIMLINKS because it is used in ifdefs
$(call SET_GLOBAL,TEST_NEED_SHLIB_SIMLINKS,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DO_TEST_ONE_EXECUTABLE=r DO_TEST_EXE=EXE TEST_COLOR DO_TEST_EXE_TEMPLATE=r)