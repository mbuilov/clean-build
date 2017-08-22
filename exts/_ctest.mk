#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# should be included after $(CLEAN_BUILD_DIR)/c.mk

# rule for running test executable(s) for 'check' goal

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for 'check' or 'clean' goals
DO_TEST_EXE:=

else # check or clean

TEST_COLOR := [0;36m

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - auxiliary parameters to pass to executable
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
# $r - $(call FORM_TRG,EXE,$v)
# note: not exporting variables $4 as target-specific ones here - to generate correct .bat/.sh script in verbose mode
# note: last line must be empty
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$r.out)
$r.out: TEST_AUX_PARAMS := $1
$r.out: TEST_AUX_PATH   := $3
$r.out: TEST_AUX_VARS   := $(subst $$,$$$$,$4)
$r.out: $r
	$$(call SUP,TEST,$$@)$$(call RUN_WITH_DLL_PATH,$$< $$(TEST_AUX_PARAMS) > $$@,$$(TEST_AUX_PATH),$$(TEST_AUX_VARS))

endef

# it may be needed to create simlinks to just built shared libraries to be able to run test executable
TEST_NEEDS_SIMLINKS := $(filter-out WINDOWS,$(OS))

# ensure TEST_NEEDS_SIMLINKS is a non-recursive (simple) variable
override TEST_NEEDS_SIMLINKS := $(TEST_NEEDS_SIMLINKS)

ifdef TEST_NEEDS_SIMLINKS

# remember all created simlinks in one global list
CB_GENERATED_SIMLINK_RULES:=

ifndef TOCLEAN

# $1 - $(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d)
# $2 - $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)
# $d - built shared library in form <library_name>.<major_number>
define SO_SOFTLINK_TEMPLATE
$1: | $(LIB_DIR)/$2
	$$(call SUP,LN,$$@)$$(call LN,$2,$$@)
CB_GENERATED_SIMLINK_RULES += $d
endef

# remember new value of CB_GENERATED_SIMLINK_RULES
ifdef MCHECK
$(call define_append,$(newline)$(call SET_GLOBAL1,CB_GENERATED_SIMLINK_RULES,0))
endif

else # TOCLEAN

# just clean generated simlinks
SO_SOFTLINK_TEMPLATE = $(TOCLEAN)

endif # TOCLEAN

# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# note: convert: <library_name>.<major_number> -> $(LIB_DIR)/$(DLL_PREFIX)<library_name>.$(DLL_SUFFIX).<major_number>
# note: convert: <library_name>.<major_number> -> $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)
TEST_CREATE_SIMLINKS = $(foreach d,$(filter-out $(CB_GENERATED_SIMLINK_RULES),$1),$(eval $(call \
  SO_SOFTLINK_TEMPLATE,$(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d),$(DLL_PREFIX)$(firstword $(subst ., ,$d))$(DLL_SUFFIX))))

# add simlinks and order-only dependencies for tested executable output, then generate rules for creating that simlinks
# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $r - $(call FORM_TRG,EXE,$v)
# note: convert: <library_name>.<major_number> -> $(LIB_DIR)/$(DLL_PREFIX)<library_name>.$(DLL_SUFFIX).<major_number>
TEST_EXE_SOFTLINKS = $(if $1,$r.out: | $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$1))$(TEST_CREATE_SIMLINKS))

# create simlinks to shared libraries for running test executable
# $$2 - built shared libraries needed by executable, in form <library_name>.<major_number>
$(call define_prepend,DO_TEST_EXE_TEMPLATE,$$(call TEST_EXE_SOFTLINKS,$$2)$(newline))

endif # TEST_NEEDS_SIMLINKS

# for 'check' target, run built executable(s)
# $1 - auxiliary parameters to pass to executable
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
DO_TEST_EXE = $(eval $(foreach v,$(call GET_VARIANTS,EXE),$(foreach r,$(call FORM_TRG,EXE,$v),$(DO_TEST_EXE_TEMPLATE))))

endif # check or clean

# protect variables from modifications in target makefiles
# note: do not trace calls to TEST_NEEDS_SIMLINKS because it is used in ifdefs
# note: do not trace calls to CB_GENERATED_SIMLINK_RULES because it is incremented
$(call SET_GLOBAL,TEST_NEEDS_SIMLINKS CB_GENERATED_SIMLINK_RULES,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,DO_TEST_EXE=EXE TEST_COLOR DO_TEST_EXE_TEMPLATE=r \
  SO_SOFTLINK_TEMPLATE=d TEST_CREATE_SIMLINKS=CB_GENERATED_SIMLINK_RULES TEST_EXE_SOFTLINKS=r)
