#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building kernel-level modules

# include generic rules for building C/C++ targets
ifeq (,$(filter-out undefined environment,$(origin CLEAN_BUILD_C_EVAL)))
include $(dir $(lastword $(MAKEFILE_LIST)))c_defs.mk
endif

FORM_KTRG = $(if $(filter \
  KDLL,$1),$(addprefix $(DLL_DIR)/$(KDLL_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(KDLL_SUFFIX))),$(if \
  KLIB,$1),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(KLIB_SUFFIX))),$(if \
  DRV,$1),$(addprefix $(BIN_DIR)/$(DRV_PREFIX),$(GET_TARGET_NAME:=$(EXE_VAR_SUFFIX)$(DRV_SUFFIX))))
  
  $(comma)$$$(open_brace)error,$(value FORM_TRG)$(close_brace)))

$(eval FORM_TRG = $(subst error,if $$(filter \
  KDLL,$$1),$$(addprefix $$(DLL_DIR)/$$(KDLL_PREFIX),$$(GET_TARGET_NAME:=$$(call \
  LIB_VAR_SUFFIX,$$2)$$(KDLL_SUFFIX)))$(comma)$$$(open_brace)error,$(value FORM_TRG)$(close_brace)))

$(eval FORM_TRG = $(subst error,if $$(filter \
  KLIB,$$1),$$(addprefix $$(LIB_DIR)/$$(KLIB_PREFIX),$$(GET_TARGET_NAME:=$$(call \
  LIB_VAR_SUFFIX,$$2)$$(KLIB_SUFFIX)))$(comma)$$$(open_brace)error,$(value FORM_TRG)$(close_brace)))

$(eval FORM_TRG = $(subst error,if $$(filter \
  DRV,$$1),$$(addprefix $$(BIN_DIR)/$$(DRV_PREFIX),$$(GET_TARGET_NAME:=$$(call \
  EXE_VAR_SUFFIX,$$1,$$2,$$3)$$(DRV_SUFFIX)))$(comma)$$$(open_brace)error,$(value FORM_TRG)$(close_brace)))

# KC_COMPILER - kernel-level compiler to use for the build (gcc, msvc, etc.)
# note: KC_COMPILER may be overridden by specifying either in in command line or in project configuration makefile
ifeq (LINUX,$(OS))
KC_COMPILER := $(CLEAN_BUILD_DIR)/compilers/gcc.mk
else ifeq (WINDOWS,$(OS))
KC_COMPILER := $(CLEAN_BUILD_DIR)/compilers/msvc.mk
else
KC_COMPILER:=
endif

# ensure KC_COMPILER variable is non-recursive (simple)
override KC_COMPILER := $(KC_COMPILER)

ifndef KC_COMPILER
$(error KC_COMPILER - kernel-level C compiler is not defined)
endif

ifeq (,$(wildcard $(KC_COMPILER)))
$(error file $(KC_COMPILER) was not found, check value of KC_COMPILER variable)
endif

# add compiler-specific definitions
include $(KC_COMPILER)

$(eval CLEAN_BUILD_KRN_C_EVAL = $(value CLEAN_BUILD_C_EVAL))

# protect variables from modifications in target makefiles
# note: do not trace calls to KC_COMPILER variable because it is used in ifdefs
$(call SET_GLOBAL,KC_COMPILER,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CLEAN_BUILD_KRN_C_EVAL)
