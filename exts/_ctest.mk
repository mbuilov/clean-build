#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# should be included after $(CLEAN_BUILD_DIR)/c.mk

# rule for running test executable(s) for 'check' target

ifeq (,$(filter check clean,$(MAKECMDGOALS)))

# do something only for check or clean goal
DO_TEST_EXE:=

else # check or clean

TEST_COLOR := [0;36m

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - auxiliary parameters to pass to executable
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
# $r - $(call FORM_TRG,EXE,$v)
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$r.out)
$r.out: TEST_AUX_PARAMS := $1
$r.out: TEST_AUX_PATH   := $3
$r.out: TEST_AUX_VARS   := $(subst $$,$$$$,$4)
$r.out: $r
	$$(call SUP,TEST,$$@)$$(call RUN_TOOL,$$< $$(TEST_AUX_PARAMS) > $$@,$$(TEST_AUX_PATH),$$(TEST_AUX_VARS))
endef

ifeq (UNIX,$(OSTYPE))

# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $r - $(call FORM_TRG,EXE,$v)
TEST_EXE_SOFTLINKS = $(if $1,$r: | $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$1))$(TEST_NEED_SIMLINKS))

# create simlinks to shared libraries for running test executable
$(eval define DO_TEST_EXE_TEMPLATE$(newline)$(value DO_TEST_EXE_TEMPLATE)$(newline)$$(call TEST_EXE_SOFTLINKS,$$2)$(newline)endef)

# initial reset
CB_GENERATED_SIMLINK_RULES:=

# $1 - $(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d)
# $2 - $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)
# $d - built shared library in form <library_name>.<major_number>
ifndef TOCLEAN

define SO_SOFTLINK_TEMPLATE
$1: | $(LIB_DIR)/$2
	$$(call SUP,LN,$$@)$$(call LN,$2,$$@)
CB_GENERATED_SIMLINK_RULES += $d
endef

else # TOCLEAN

SO_SOFTLINK_TEMPLATE = $(TOCLEAN)

endif # TOCLEAN

# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
TEST_NEED_SIMLINKS = $(foreach d,$(filter-out $(CB_GENERATED_SIMLINK_RULES),$1),$(eval $(call \
  SO_SOFTLINK_TEMPLATE,$(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d),$(DLL_PREFIX)$(firstword $(subst ., ,$d))$(DLL_SUFFIX))))

endif # UNIX

# for 'check' target, run built executable(s)
# $1 - auxiliary parameters to pass to executable
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
DO_TEST_EXE = $(eval $(foreach v,$(call GET_VARIANTS,EXE),$(foreach r,$(call FORM_TRG,EXE,$v),$(newline)$(DO_TEST_EXE_TEMPLATE))))

endif # check or clean

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,TEST_COLOR DO_TEST_EXE_TEMPLATE=r \
  TEST_EXE_SOFTLINKS=r SO_SOFTLINK_TEMPLATE=d TEST_NEED_SIMLINKS=CB_GENERATED_SIMLINK_RULES DO_TEST_EXE=EXE)
