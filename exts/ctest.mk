#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# must be included after $(MTOP)/c.mk

ifndef DO_TEST_EXE_TEMPLATE

# rule for running test executable for 'check' target

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $2 - auxiliary parameters to pass to executable
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
# $r - $(call FORM_TRG,EXE,$v)
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$r.out)
$r.out: TEST_AUX_PARAMS := $2
$r.out: TEST_AUX_PATH   := $3
$r.out: TEST_AUX_VARS   := $(subst $,$$$$,$4)
$r.out: $r
	$$(call SUP,TEST,$$@)$$(info ----$$(TEST_AUX_VARS))$$(call RUN_WITH_DLL_PATH,$$< $$(TEST_AUX_PARAMS) > $$@,$$(TEST_AUX_PATH),$$(TEST_AUX_VARS))
$(TEST_EXE_SOFTLINKS)
endef

# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $r - $(call FORM_TRG,EXE,$v)
ifdef OSTYPE_UNIX
TEST_EXE_SOFTLINKS ?= $(if $1,$r: | $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$1))$(TEST_NEED_SIMLINKS))
endif

# $1 - $(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d)
# $2 - $(DLL_PREFIX)<library_name>$(DLL_SUFFIX)
# $d - built shared library in form <library_name>.<major_number>
define SO_SOFTLINK_TEMPLATE
$1: | $(LIB_DIR)/$2
	$$(call SUP,LN,$$@)$$(call LN,$2,$$@)
$(TOCLEAN)
CB_GENERATED_SIMLINK_RULES += $d
endef

# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
ifdef OSTYPE_UNIX
CB_GENERATED_SIMLINK_RULES:=
TEST_NEED_SIMLINKS ?= $(foreach d,$1,$(if $(filter $d,$(CB_GENERATED_SIMLINK_RULES)),,$(eval $(call \
  SO_SOFTLINK_TEMPLATE,$(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d),$(DLL_PREFIX)$(firstword $(subst ., ,$d))$(DLL_SUFFIX)))))
endif

ifneq ($(filter check clean,$(MAKECMDGOALS)),)

# for 'check' target, run built executable(s)
# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $2 - auxiliary parameters to pass to executable
# $3 - dlls search paths: appended to PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS) environment variable to run executable
# $4 - environment variables to set to run executable, in form VAR=value
DO_TEST_EXE ?= $(eval $(foreach v,$(call GET_VARIANTS,EXE),$(newline)$(foreach r,$(call FORM_TRG,EXE,$v),$(DO_TEST_EXE_TEMPLATE))))

endif # check

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_EXE_TEMPLATE TEST_EXE_SOFTLINKS SO_SOFTLINK_TEMPLATE TEST_NEED_SIMLINKS DO_TEST_EXE)

endif # DO_TEST_EXE_TEMPLATE
