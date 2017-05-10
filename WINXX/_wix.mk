#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building WIX (Windows Installer Xml) installer

# WIX - path to Windows Installer Xml - must be defined either in command line
# or in project configuration file before including this file, via:
# override WIX:=C:\Program Files (x86)\WiX Toolset v3.10\
WIX:=

ifeq (,$(WIX))
$(error WIX is not defined, example: C:\Program Files (x86)\WiX Toolset v3.10\)
endif

ifndef DEF_HEAD_CODE
include $(MTOP)/_defs.mk
endif

# what we may build by including $(MTOP)/wix.mk (for ex. INSTALLER := my_installer)
BLD_WIX_TARGETS := MSI INSTALLER

# remove unneeded quotes, replace spaces with ?, add trailing slash
WIXN := $(call unspaces,$(subst \\,\,$(subst /,\,$(patsubst "%,%,$(WIX:"=))\)))

# add quotes, if needed
WIX_CANDLE := $(call qpath,$(WIXN)bin\candle.exe)
WIX_LIGHT := $(call qpath,$(WIXN)bin\light.exe)

# path to Wix extensions directroy
WIX_EXTS_DIR := $(WIXN)bin

# compile .wxs file
# $1 - .wixobj
# $2 - .wxs
# target-specific: WINCLUDE
WIXOBJ_CL = $(call SUP,CANDLE,$2)$(WIX_CANDLE) -nologo$(if $(VERBOSE), -v) $(call \
  qpath,$(WEXTS),-ext ) $(call ospath,$2) $(call qpath,$(call ospath,$(WINCLUDE)),-I) -out $(ospath) >&2

# build installer .msi file
# $1 - target .msi
# $2 - objects .wxsobj
# target-specific: WEXTS
MSI_LD = $(call SUP,LIGHT,$1)$(WIX_LIGHT) -nologo$(if $(VERBOSE), -v) $(call \
  qpath,$(WEXTS),-ext ) $(call ospath,$2) -out $(ospath) >&2

# build installer .exe file
INSTALLER_LD = $(MSI_LD)

# make target filename, $1 - MSI,INSTALLER
FORM_WIX_TRG = $(if \
  $(filter MSI,$1),$(BIN_DIR)/$($1).msi,$(if \
  $(filter INSTALLER,$1),$(BIN_DIR)/$($1).exe))

# $1 - objdir
# $2 - source deps list
# $x - source
WIX_ADD_OBJ_SDEPS = $(if $2,$(newline)$1/$(basename $(notdir $x)).wixobj: $2)

# rule that defines how to build wix object from .wxs source
# $1 - sources to compile
# $2 - sdeps
# $3 - objdir
# $4 - $(addsuffix .wixobj,$(addprefix $3/,$(basename $(notdir $1))))
define WIX_OBJ_RULES1
$4
$(subst $(space),$(newline),$(join $(addsuffix :,$4),$1))$(if \
  $2,$(foreach x,$1,$(call WIX_ADD_OBJ_SDEPS,$3,$(call EXTRACT_SDEPS,$1,$2))))
$4:| $3 $$(ORDER_DEPS)
	$$(call WIXOBJ_CL,$$@,$$<)
endef

# rules that defines how to build wix objects from sources
# $1 - .wxs sources to compile
# $2 - sdeps
# $3 - $(call FORM_OBJ_DIR,INSTALLER)
ifdef TOCLEAN
WIX_OBJ_RULES = $(call TOCLEAN,$(addsuffix .wixobj,$(addprefix $3/,$(basename $(notdir $1)))))
else
WIX_OBJ_RULES = $(call WIX_OBJ_RULES1,$1,$2,$3,$(addsuffix .wixobj,$(addprefix $3/,$(basename $(notdir $1)))))
endif

# $1 - what to build: MSI, INSTALLER
# $2 - target file: $(call FORM_WIX_TRG,$1)
# $3 - sources:     $(call FIXPATH,$(WXS))
# $4 - sdeps:       $(call FIX_SDEPS,$(WDEPS))
# $5 - objdir:      $(call FORM_OBJ_DIR,$1)
# note: calls either MSI_LD or INSTALLER_LD
define WIX_TEMPLATE
$(call STD_TARGET_VARS,$2)
NEEDED_DIRS+=$5
$2:$(call WIX_OBJ_RULES,$3,$4,$5)
$2:WEXTS := $(WEXTS)
$2:WINCLUDE := $(WINCLUDE)
$2:
	$$(call $1_LD,$$@,$$(filter %.wixobj,$$^))
$(call TOCLEAN,$(basename $2).wixpdb)
endef

# how to build installer msi or exe
# $1 - MSI, INSTALLER
WIX_RULES = $(call WIX_TEMPLATE,$1,$(call FORM_WIX_TRG,$1),$(call FIXPATH,$(WXS)),$(call FIX_SDEPS,$(WDEPS)),$(call FORM_OBJ_DIR,$1))

MSI_RULES = $(if $(MSI),$(call WIX_RULES,MSI))
INSTALLER_RULES = $(if $(INSTALLER),$(call WIX_RULES,INSTALLER))

# this code is normally evaluated at end of target makefile
define DEFINE_WIX_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(call DEBUG_TARGETS,$(BLD_WIX_TARGETS),FORM_WIX_TRG)))
$(eval $(MSI_RULES)$(INSTALLER_RULES))
$(eval $(DEF_TAIL_CODE))
endef

# code to be called at beginning of target makefile
define PREPARE_WIX_VARS
$(foreach x,$(BLD_WIX_TARGETS),$(newline)$x:=)
WXS:=
WEXTS:=
WDEPS:=
WINCLUDE:=
DEFINE_TARGETS_EVAL_NAME := DEFINE_WIX_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_WIX_EVAL
endef
PREPARE_WIX_VARS := $(PREPARE_WIX_VARS)

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
MAKE_WIX_EVAL = $(eval $(DEF_HEAD_CODE)$(PREPARE_WIX_VARS))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,WIX_MK_INCLUDED WIX WIXN BLD_WIX_TARGETS WIX_CANDLE WIX_LIGHT WIX_EXTS_DIR \
  WIXOBJ_CL MSI_LD INSTALLER_LD FORM_WIX_TRG WIX_ADD_OBJ_SDEPS WIX_OBJ_RULES1 WIX_OBJ_RULES WIX_TEMPLATE \
  WIX_RULES MSI_RULES INSTALLER_RULES DEFINE_WIX_TARGETS_EVAL PREPARE_WIX_VARS MAKE_WIX_EVAL)
