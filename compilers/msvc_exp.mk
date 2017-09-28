#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for exporting symbols from a target (e.g. dll), included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# reset additional variables at beginning of target makefile
# DEF - linker definitions file (used mostly to list exported symbols)
C_PREPARE_MSVC_EXP_VARS := DEF:=

# for the target exporting symbols
# $1 - $(call FORM_TRG,$t,$v)
# $2 - path to import library, e.g. $(LIB_DIR)/$(IMP_PREFIX)$(basename $(notdir $1))$(IMP_SUFFIX)
# $3 - $(call fixpath,$(DEF))
# note: C_BASE_TEMPLATE also changes CB_NEEDED_DIRS, so do not remember its new value here
# note: target-specific IMP and DEF variables are inherited by the targets this target depends on,
#  so dependencies _must_ define their own target-specific IMP and DEF variables to override inherited ones
ifndef TOCLEAN
define EXPORTS_TEMPLATE
$1: IMP := $2
$1: DEF := $3
$1: $3 | $(LIB_DIR)
CB_NEEDED_DIRS += $(patsubst %/,%,$(dir $2))
$2: $1
endef
else
# just delete import library and possibly generated .exp file
EXPORTS_TEMPLATE = $(call TOCLEAN,$2 $(basename $2).exp)
endif

# if target may export symbols, but it's specified that target do not exports
# $1 - $(call FORM_TRG,$t,$v)
# note: define target's own target-specific IMP and DEF variables to override inherited
#  target-specific IMP and DEF variables of the target which depends on this one
ifndef TOCLEAN
define NO_EXPORTS_TEMPLATE
$1:IMP:=
$1:DEF:=
endef
else
NO_EXPORTS_TEMPLATE:=
endif

# support for targets (e.g. DLLs) that may export symbols
# define target-specific variables: DEF and IMP
# $1 - $(call FORM_TRG,$t,$v)
# $2 - path to import library if target exports symbols, <empty> - otherwise
# $t - EXE,DLL,DRV,KDLL,...
# $v - variant: R,S,...
EXPORTS_TEMPLATEv = $(if $2,$(call EXPORTS_TEMPLATE,$1,$2,$(call fixpath,$(DEF))),$(NO_EXPORTS_TEMPLATE))

# DEF variable is used only if it's specified that target exports symbols
ifdef MCHECK
# $1 - $(call FORM_TRG,$t,$v)
# $2 - path to import library if target exports symbols, <empty> - otherwise
DEF_VARIABLE_CHECK = $(if $2,,$(if $(DEF),$(warning DEF variable is ignored for target exporting no symbols: $1)))
$(call define_prepend,EXPORTS_TEMPLATEv,$$(DEF_VARIABLE_CHECK))
endif

# check that target exports symbols - linker has created .exp file
# $1 - path to the target (e.g. EXE or DLL)
# target-specific: IMP
CHECK_EXP_CREATED = $(if $(IMP),$(newline)$(QUIET)if not exist $(call ospath,$(basename \
  $(IMP)).exp) (echo $(notdir $1) does not exports any symbols!) && cmd /c exit 1)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,C_PREPARE_MSVC_EXP_VARS EXPORTS_TEMPLATE NO_EXPORTS_TEMPLATE EXPORTS_TEMPLATEv DEF_VARIABLE_CHECK CHECK_EXP_CREATED)
