#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for generating resources (.res) for the targets, included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $5/$(basename $(notdir $2)).res
# NOTE: EXE,DLL,...-target dependency on generated resource file is added in $(STD_RES_TEMPLATE) (see ADD_RES_TEMPLATE macro)
# NOTE: generated .res is added to CLEAN list in $(OS_DEFINE_TARGETS) via $(RES)
# note: postpone expansion of ORDER_DEPS to optimize parsing
define ADD_RES_RULE1
NEEDED_DIRS += $5
$6: $(call fixpath,$2 $4) | $5 $$(ORDER_DEPS)
	$$(call RC,$$@,$$<,$3)
RES += $6
endef

# add rule to make auxiliary resource for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional dependencies for generated .res
ADD_RES_RULE = $(foreach v,$(GET_VARIANTS),$(call ADD_RES_RULE1,$(call FORM_TRG,$1,$v),$2,$3,$4,$(call FORM_OBJ_DIR,$1,$v)))

,  $1,$2,$3,$4,$5,$5/$(basename $(notdir $2)).res)

STD_RES_TEMPLATE1 = $(foreach v,$(GET_VARIANTS),$(call \
  STD_RES_TEMPLATE2,$1,$2,$(call FORM_TRG,$1,$v),$(call FORM_OBJ_DIR,$1,$v),$(WIN_RC_STDRES_NAME)))








# reset additional variables at beginning of target makefile
# RES - resources to link to EXE,DLL,DRV,...
C_PREPARE_MSVC_RES_VARS := RES:=

# link resource to the target
# $1 - $(call FORM_TRG,$t,$v)
# note: C_BASE_TEMPLATE also changes CB_NEEDED_DIRS, so do not remember its new value here
# note: target-specific RES variable may be inherited by targets depending on current one,
#  so _must_ define their own target-specific RES variable, even with empty values, to override inherited one
ifndef TOCLEAN
define ADD_RES_TEMPLATE
$1: RES := $2
$1: DEF := $3
$1: $3 | $(LIB_DIR)
CB_NEEDED_DIRS += $(LIB_DIR)
$2: $1
endef
else
# return import library and generated .exp file to cleanup
EXPORTS_TEMPLATE = $2 $(2:$(IMP_SUFFIX)=.exp)
endif

# support for targets (e.g. DLLs) that may export symbols
# define target-specific variables: DEF and IMP
# $1 - $(call FORM_TRG,$t,$v)
# $2 - non-<empty> if target exports symbols, <empty> - otherwise
# $t - EXE,DLL,DRV,KDLL,...
# $v - variant: R,S,...
RES_TEMPLATEv = $(if $2,$(call EXPORTS_TEMPLATE,$1,$(MAKE_IMPORT_LIB_PATH),$(call fixpath,$(DEF))),$(NO_EXPORTS_TEMPLATE))

# rules to build auxiliary resources
CB_WINXX_RES_RULES:=

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1)
# $6 - $5/$(basename $(notdir $2)).res
# NOTE: EXE,DLL,...-target dependency on generated resource file is added in $(STD_RES_TEMPLATE) (see ADD_RES_TEMPLATE macro)
# NOTE: generated .res is added to CLEAN list in $(OS_DEFINE_TARGETS) via $(RES)
# NOTE: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) changes $(ORDER_DEPS) value
define ADD_RES_RULE2
$(FIX_ORDER_DEPS)
NEEDED_DIRS += $5
$6: $(call fixpath,$2 $4) | $5 $$(ORDER_DEPS)
	$$(call RC,$$@,$$<,$3)
RES += $6
endef

# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
# $5 - $(call FORM_OBJ_DIR,$1)
ADD_RES_RULE1 = $(call ADD_RES_RULE2,$1,$2,$3,$4,$5,$5/$(basename $(notdir $2)).res)

# add rule to make auxiliary res for the target
# $1 - EXE,DLL,...
# $2 - rc pathname (either absolute or makefile-related)
# $3 - options for RC
# $4 - optional deps for .res
ADD_RES_RULE = $(eval define CB_WINXX_RES_RULES$(newline)$(if $(value CB_WINXX_RES_RULES),,CB_WINXX_RES_RULES:=$(newline))$(value \
  CB_WINXX_RES_RULES)$(newline)$(call ADD_RES_RULE1,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1))$(newline)endef)
