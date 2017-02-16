#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# must be included after $(MTOP)/c.mk

ifndef DO_TEST_EXE_TEMPLATE

# rule for running test executable for 'check' target

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - auxiliary parameters to pass to executable
# $2 - executable name
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$(BIN_DIR)/$2.out)
$(BIN_DIR)/$2.out: $(call FORM_TRG,EXE)
	$$(call SUP,TEST,$$@)$$< $1 2> $$@
endef

# for 'check' target, run executable
# $1 - auxiliary parameters to pass to executable
ifneq ($(filter check,$(MAKECMDGOALS)),)
DO_TEST_EXE ?= $(eval $(call DO_TEST_EXE_TEMPLATE,$1,$(call GET_TARGET_NAME,EXE)))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_EXE_TEMPLATE DO_TEST_EXE)

endif # DO_TEST_EXE_TEMPLATE
