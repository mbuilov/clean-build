#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# must be included after $(MTOP)/c.mk

ifndef DO_TEST_EXE_TEMPLATE

# rule for running test executable for 'check' target

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - $(call FORM_TRG,EXE,$v)
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $3 - auxiliary parameters to pass to executable
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$1.out)
$1.out: $1
	$$(call SUP,TEST,$$@)$$< $3 2> $$@
$(TEST_EXE_SOFTLINKS)
endef

# $1 - $(call FORM_TRG,EXE,$v)
# $2 - built shared libraries needed by executable, in form <library_name>.<major_number>
ifeq (UNIX,$(OSTYPE))
TEST_EXE_SOFTLINKS ?= $(if $2,$1: | $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$2))$(call TEST_NEED_SIMLINKS,$2))
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
ifeq (UNIX,$(OSTYPE))
CB_GENERATED_SIMLINK_RULES:=
TEST_NEED_SIMLINKS ?= $(foreach d,$1,$(if $(filter $d,$(CB_GENERATED_SIMLINK_RULES)),,$(eval $(call \
  SO_SOFTLINK_TEMPLATE,$(LIB_DIR)/$(DLL_PREFIX)$(subst .,$(DLL_SUFFIX).,$d),$(DLL_PREFIX)$(firstword $(subst ., ,$d))$(DLL_SUFFIX)))))
endif

ifneq ($(filter check clean,$(MAKECMDGOALS)),)

# for 'check' target, run built executable(s)
# $1 - built shared libraries needed by executable, in form <library_name>.<major_number>
# $2 - auxiliary parameters to pass to executable
DO_TEST_EXE ?= $(eval $(foreach v,$(call GET_VARIANTS,EXE),$(newline)$(call DO_TEST_EXE_TEMPLATE,$(call FORM_TRG,EXE,$v),$1,$2)))

endif # check

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_EXE_TEMPLATE TEST_EXE_SOFTLINKS SO_SOFTLINK_TEMPLATE TEST_NEED_SIMLINKS DO_TEST_EXE)

endif # DO_TEST_EXE_TEMPLATE