ifndef MAKE_WIX_INCLUDED

# this file normally included at beginning of target Makefile
# used for building WIX (Windows Installer Xml) installer
MAKE_WIX_INCLUDED := 1

ifndef WIX
$(error WIX is not defined, example: C:\Program Files (x86)\WiX Toolset v3.10\)
endif

# avoid execution of $(DEF_HEAD_CODE) by make_defs.mk - $(DEF_HEAD_CODE) will be evaluated at end of this file
MAKE_DEFS_INCLUDED_BY := make_wix.mk
include $(MTOP)/make_defs.mk

# what we may build by including make_wix.mk (for ex. INSTALLER := my_installer)
BLD_WIX_TARGETS := MSI INSTALLER

# remove unneeded quotes
WIX := $(call unspaces,$(subst ",,$(WIX)))

# add quotes, if needed
WIX_CANDLE   ?= $(call qpath,$(WIX)bin\candle.exe)
WIX_LIGHT    ?= $(call qpath,$(WIX)bin\light.exe)
WIX_EXTS_DIR ?= $(call unspaces,$(WIX)bin)

# compile .wxs file
# $1 - .wixobj, $2 - .wxs
WIXOBJ_CL = $(call SUPRESS,CANDLE,$2)$(WIX_CANDLE) -nologo $(if $(VERBOSE:0=),-v) $(call ospath,$2) $(call \
             pqpath,-I,$(call ospath,$(WINCLUDE))) -out $(call ospath,$1)

# build installer .exe file
# $1 - target .msi, $2 - objects .wxsobj
MSI_LD = $(call SUPRESS,LIGHT,$1)$(WIX_LIGHT) -nologo $(if $(VERBOSE:0=),-v) $(call pqpath,-ext ,$(WEXTS)) $(call ospath,$2) -out $(call ospath,$1)

# build installer .msi file
INSTALLER_LD = $(MSI_LD)

# define code to print debug info about built targets
DEBUG_WIX_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_WIX_TARGETS),FORM_WIX_TRG)

# make target filename, $1 - MSI,INSTALLER
FORM_WIX_TRG = $(if \
            $(filter MSI,$1),$(BIN_DIR)/$($1).msi,$(if \
            $(filter INSTALLER,$1),$(BIN_DIR)/$($1).exe))

# objects to build for the target
# $1 - .wxs sources to compile
WIX_OBJS = $(addsuffix .wixobj,$(basename $(notdir $1)))

# rule that defines how to build wix object from .wxs source
# $1 - source to compile, $2 - objdir, $3 - $(basename $(notdir $1))
define WIX_OBJ_RULE
$(empty)
$2/$3.wixobj: $1 | $2 $(ORDER_DEPS)
	$$(call WIXOBJ_CL,$$@,$$<)
endef

# rule that defines how to build wix objects from sources
# $1 - .wxs sources to compile, $2 - $(call FORM_OBJ_DIR,INSTALLER)
WIX_OBJ_RULES = $(foreach x,$1,$(call WIX_OBJ_RULE,$x,$2,$(basename $(notdir $x))))

# $1 - what to build: MSI, INSTALLER
# $2 - target file: $(call FORM_WIX_TRG,$1)
# $3 - sources:     $(call FIXPATH,$(WXS))
# $4 - objdir:      $(call FORM_OBJ_DIR,$1)
# $5 - objects:     $(addprefix $4/,$(call WIX_OBJS,$3))
# note: calls either MSI_LD or INSTALLER_LD
define WIX_TEMPLATE
NEEDED_DIRS += $4
$(call WIX_OBJ_RULES,$3,$4)
$(call STD_TARGET_VARS,$1)
$2: WEXTS := $(WEXTS)
$2: WINCLUDE := $(WINCLUDE)
$2: $5 $(WDEPS) | $(BIN_DIR) $(ORDER_DEPS)
	$$(call $1_LD,$$@,$$(filter %.wixobj,$$^))
$(CURRENT_MAKEFILE_TM): $2
CLEAN += $2 $5 $(basename $2).wixpdb
endef

# how to build installer msi or exe
WIX_RULES1 = $(call WIX_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call WIX_OBJS,$3)))
WIX_RULES = $(call WIX_RULES1,$1,$(call FORM_WIX_TRG,$1),$(call FIXPATH,$(WXS)),$(call FORM_OBJ_DIR,$1))

MSI_RULES = $(if $(MSI),$(call WIX_RULES,MSI))
INSTALLER_RULES = $(if $(INSTALLER),$(call WIX_RULES,INSTALLER))

# this file normally included at end of target Makefile
define DEFINE_WIX_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_WIX_TARGETS)))
$(eval $(MSI_RULES))
$(eval $(INSTALLER_RULES))
$(DEF_TAIL_CODE)
endef
DEFINE_WIX_TARGETS = $(if $(DEFINE_WIX_TARGETS_EVAL),)

# code to be called at beginning of target makefile
define PREPARE_WIX_VARS
$(foreach x,$(BLD_WIX_TARGETS),$(newline)$x:=)
WXS      :=
WEXTS    :=
WDEPS    :=
WINCLUDE :=
endef

# increment MAKE_CONT, eval tail code with $(DEFINE_WIX_TARGETS)
# and start next circle - simulate including of "make_wix.mk"
define MAKE_WIX_CONTINUE_EVAL
$(eval MAKE_CONT := $(MAKE_CONT) 2)
$(DEFINE_WIX_TARGETS_EVAL)
$(eval $(PREPARE_WIX_VARS))
$(eval $(DEF_HEAD_CODE))
$(eval MAKE_CONT += 1)
endef
MAKE_WIX_CONTINUE = $(if $(if $1,$(SAVE_VARS))$(MAKE_WIX_CONTINUE_EVAL)$(if $1,$(RESTORE_VARS)),)

endif # MAKE_WIX_INCLUDED

# reset build targets, target-specific variables and variables modifiable in target makefiles
$(eval $(PREPARE_WIX_VARS))

# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))
