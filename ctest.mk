#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# must be included after $(MTOP)/c.mk

ifndef DO_TEST_EXE_TEMPLATE

# rule for running test executable for 'check' target

# run $(EXE) and dump its stderr to $(EXE).out
# $1 - $(call GET_TARGET_NAME,EXE)
# $2 - $(call FORM_TRG,EXE)
# $3 - list of built shared libraries in form: <library_name>.<major_number>
# $4 - auxiliary parameters to pass to executable
define DO_TEST_EXE_TEMPLATE
$(call ADD_GENERATED,$(BIN_DIR)/$1.out)
$(BIN_DIR)/$1.out: $2
	$$(call SUP,TEST,$$@)$$< $4 2> $$@
$(SO_SOFTLINK_TEMPLATE)
endef

# $d - built shared library simlink in form $(LIB_DIR)/$(DLL_PREFIX)<library_name>$(DLL_SUFFIX).<major_number>
define SO_SOFTLINK_TEMPLATE1
$(empty)
$d: | $(dir $d)$(firstword $(subst $(DLL_SUFFIX)., ,$(notdir $d)))$(DLL_SUFFIX)
	$$(call SUP,LN,$$@)$$(call LN,$$(firstword $$(subst $(DLL_SUFFIX)., ,$$(notdir $$@)))$(DLL_SUFFIX),$$@)
endef

# $1 - $(call FORM_TRG,EXE)
# $2 - $(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$(dlls)))
# where $(dlls) is list of built shared libraries in form: <library_name>.<major_number>
define SO_SOFTLINK_TEMPLATE2
$(call ADD_GENERATED,$2)
$1: | $2
$(foreach d,$2,$(SO_SOFTLINK_TEMPLATE1))
endef

# $2 - $(call FORM_TRG,EXE)
# $3 - list of built shared libraries in form: <library_name>.<major_number>
ifeq (UNIX,$(OSTYPE))
SO_SOFTLINK_TEMPLATE ?= $(if $3,RPATH ?= $(LIB_DIR)$(call \
  SO_SOFTLINK_TEMPLATE2,$2,$(addprefix $(LIB_DIR)/$(DLL_PREFIX),$(subst .,$(DLL_SUFFIX).,$3))))
endif

# for 'check' target, run executable
# $1 - built shared libraries for the executable, in form <library_name>.<major_number>: lib1.maj1 lib2.maj2 ...
# $2 - auxiliary parameters to pass to executable
ifneq ($(filter check,$(MAKECMDGOALS)),)
DO_TEST_EXE ?= $(eval $(call DO_TEST_EXE_TEMPLATE,$(call GET_TARGET_NAME,EXE),$(call FORM_TRG,EXE),$1,$2))
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DO_TEST_EXE_TEMPLATE SO_SOFTLINK_TEMPLATE1 SO_SOFTLINK_TEMPLATE2 SO_SOFTLINK_TEMPLATE DO_TEST_EXE)

endif # DO_TEST_EXE_TEMPLATE
