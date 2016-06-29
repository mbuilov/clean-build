# rules for building WIX (Windows Installer Xml) installer

ifndef WIX
$(error WIX is not defined, example: C:\Program Files (x86)\WiX Toolset v3.10\)
endif

ifndef DEF_HEAD_CODE
include $(MTOP)/_defs.mk
endif

# what we may build by including $(MTOP)/wix.mk (for ex. INSTALLER := my_installer)
BLD_WIX_TARGETS := MSI INSTALLER

# remove unneeded quotes
WIX := $(call unspaces,$(subst ",,$(WIX)))

# add quotes, if needed
ifndef WIX_CANDLE
WIX_CANDLE := $(call qpath,$(WIX)bin\candle.exe)
endif
ifndef WIX_LIGHT
WIX_LIGHT := $(call qpath,$(WIX)bin\light.exe)
endif

# replace spaces with ?
ifeq (undefined,$(origin WIX_EXTS_DIR))
WIX_EXTS_DIR := $(call unspaces,$(WIX)bin)
endif

# compile .wxs file
# $1 - .wixobj, $2 - .wxs
# target-specific: WINCLUDE
WIXOBJ_CL = $(call SUP,CANDLE,$2)$(WIX_CANDLE) -nologo$(if $(VERBOSE), -v) $(call \
  ospath,$2) $(call qpath,$(call ospath,$(WINCLUDE)),-I) -out $(ospath)

# build installer .msi file
# $1 - target .msi, $2 - objects .wxsobj
# target-specific: WEXTS
MSI_LD = $(call SUP,LIGHT,$1)$(WIX_LIGHT) -nologo$(if $(VERBOSE), -v) $(call \
  qpath,$(WEXTS),-ext ) $(call ospath,$2) -out $(ospath)

# build installer .exe file
INSTALLER_LD = $(MSI_LD)

# define code to print debug info about built targets
# note: GET_DEBUG_TARGETS - defined in $(MTOP)/defs.mk
DEBUG_WIX_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_WIX_TARGETS),FORM_WIX_TRG)

# make target filename, $1 - MSI,INSTALLER
FORM_WIX_TRG = $(if \
               $(filter MSI,$1),$(BIN_DIR)/$($1).msi,$(if \
               $(filter INSTALLER,$1),$(BIN_DIR)/$($1).exe))

# objects to build for the target
# $1 - .wxs sources to compile
WIX_OBJS = $(addsuffix .wixobj,$(basename $(notdir $1)))

# rule that defines how to build wix object from .wxs source
# $1 - source to compile, $2 - deps, $3 - objdir, $4 - $(basename $(notdir $1))
define WIX_OBJ_RULE
$(empty)
$3/$4.wixobj: $1 $(call EXTRACT_DEPS,$1,$2) | $3 $$(ORDER_DEPS)
	$$(call WIXOBJ_CL,$$@,$$<)
endef

# rule that defines how to build wix objects from sources
# $1 - .wxs sources to compile, $2 - deps, $3 - $(call FORM_OBJ_DIR,INSTALLER)
WIX_OBJ_RULES = $(foreach x,$1,$(call WIX_OBJ_RULE,$x,$2,$3,$(basename $(notdir $x))))

# $1 - what to build: MSI, INSTALLER
# $2 - target file: $(call FORM_WIX_TRG,$1)
# $3 - sources:     $(call FIXPATH,$(WXS))
# $4 - deps:        $(call FIX_DEPS,$(WDEPS))
# $5 - objdir:      $(call FORM_OBJ_DIR,$1)
# $6 - objects:     $(addprefix $5/,$(call WIX_OBJS,$3))
# note: calls either MSI_LD or INSTALLER_LD
define WIX_TEMPLATE
$(call STD_TARGET_VARS,$2)
NEEDED_DIRS += $5
$(call WIX_OBJ_RULES,$3,$4,$5)
$2: WEXTS := $(WEXTS)
$2: WINCLUDE := $(WINCLUDE)
$2: $6
	$$(call $1_LD,$$@,$$(filter %.wixobj,$$^))
$(call TOCLEAN,$6 $(basename $2).wixpdb)
endef

# how to build installer msi or exe
WIX_RULES1 = $(call WIX_TEMPLATE,$1,$2,$3,$4,$5,$(addprefix $5/,$(call WIX_OBJS,$3)))
WIX_RULES = $(call WIX_RULES1,$1,$(call FORM_WIX_TRG,$1),$(call FIXPATH,$(WXS)),$(call FIX_DEPS,$(WDEPS)),$(call FORM_OBJ_DIR,$1))

MSI_RULES = $(if $(MSI),$(call WIX_RULES,MSI))
INSTALLER_RULES = $(if $(INSTALLER),$(call WIX_RULES,INSTALLER))

# this code is normally evaluated at end of target makefile
define DEFINE_WIX_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_WIX_TARGETS)))
$(eval $(MSI_RULES)$(INSTALLER_RULES))
$(DEF_TAIL_CODE_EVAL)
endef

# code to be called at beginning of target makefile
define PREPARE_WIX_VARS
$(foreach x,$(BLD_WIX_TARGETS),$(newline)$x:=)
WXS      :=
WEXTS    :=
WDEPS    :=
WINCLUDE :=
DEFINE_TARGETS_EVAL_NAME := DEFINE_WIX_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_WIX_EVAL
endef
PREPARE_WIX_VARS := $(PREPARE_WIX_VARS)

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
MAKE_WIX_EVAL = $(eval $(PREPARE_WIX_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,WIX_MK_INCLUDED WIX BLD_WIX_TARGETS WIX_CANDLE WIX_LIGHT WIX_EXTS_DIR \
  WIXOBJ_CL MSI_LD INSTALLER_LD DEBUG_WIX_TARGETS FORM_WIX_TRG WIX_OBJS WIX_OBJ_RULE WIX_OBJ_RULES WIX_TEMPLATE \
  WIX_RULES1 WIX_RULES MSI_RULES INSTALLER_RULES DEFINE_WIX_TARGETS_EVAL PREPARE_WIX_VARS MAKE_WIX_EVAL)
