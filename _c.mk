#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building C/C++ libs, dlls, executables

ifndef DEF_HEAD_CODE
include $(MTOP)/_defs.mk
endif

# build targets and variants:
# NOTE: all variants have the same C-preprocessor defines, but are compiled with different C-compiler flags
# EXE  - executable, variants:      R,P,S
# LIB  - static library, variants:  R,P,D,S (P-version - library only for EXE, D-version - library only for DLL)
# DLL  - dynamic library, variants: R,S
# if variant is not specified, default variant R will be built, else - only specified variants (add R to build also default variant)

# after target name may be specified one or more build target variants (for ex. EXE := my_exe R S):
# R - default build variant:
#  EXE  - position-dependent code   (UNIX), dynamically linked multi-threaded libc (WINDOWS)
#  LIB  - position-dependent code   (UNIX), dynamically linked multi-threaded libc (WINDOWS)
#  DLL  - position-independent code (UNIX), dynamically linked multi-threaded libc (WINDOWS)
# P - position-independent code in executables      (for EXE and LIB) (only UNIX)
# D - position-independent code in shared libraries (only for LIB)    (only UNIX)
# S - statically linked multithreaded libc          (for all targets) (only WINDOWS)

# what we may build by including $(MTOP)/c.mk (for ex. LIB := my_lib)
# note: DRV is $(OS)-specific, $(MTOP)/$(OS)/c.mk should define DRV_TEMPLATE
# note: $(MTOP)/$(OS)/c.mk may append more target types to BLD_TARGETS, for example DDD
BLD_TARGETS := EXE LIB DLL KLIB DRV

# $(TOP)/make/project.mk included by $(MTOP)/defs.mk, if exists, should define something like:
#
# 1) common include path for all targets, added at end of compiler's include paths list, for example:
#  DEFINCLUDE = $(TOP)/include
#  note: DEFINCLUDE may be recursive, it's value may be calculated based on $(TOP)-related path to $(CURRENT_MAKEFILE)
#  note: target makefile may avoid using include paths from $(DEFINCLUDE) by resetting $(CMNINCLUDE) value
#
# 2) predefined macros for all targets, for example:
#  PREDEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) \
#               $(if $(filter sparc% mips% ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
#               $(if $(filter arm% sparc% mips% ppc%,$(CPU)),ADDRESS_NEEDALIGN)
#  note: $(PREDEFINES) may be recursive, it's value may be calculated based on $(TOP)-related path to $(CURRENT_MAKEFILE)
#  note: target makefile may avoid using macros from $(PREDEFINES) by resetting $(CMNDEFINES) value
#
# 3) common defines for all application-level targets, for example:
#  APPDEFS =
#  note: it's not possible to reset value of $(APPDEFS) in target makefile,
#   but APPDEFS may be recursive and so may produce dynamic results
#
# 4) common defines for all kernel-level targets, for example:
#  KRNDEFS = _KERNEL
#  note: it's not possible to reset value of $(KRNDEFS) in target makefile,
#   but KRNDEFS may be recursive and so may produce dynamic results
#
# 5) product version in form major.minor or major.minor.patch
#  this is also default version for any built module (exe, dll or driver)
#  PRODUCT_VER := 1.0.0

include $(MTOP)/$(OS)/c.mk

# for simple 'ifdef OSTYPE_WINDOWS' or 'ifdef OSTYPE_UNIX'
OSTYPE_$(OSTYPE) := 1

# for simple 'ifdef OSVARIANT_WIN7' or 'ifdef OSVARIANT_DEBIAN8'
OSVARIANT_$(OSVARIANT) := 1

# determine suffix for static LIB or for implementation-library of DLL
# $1 - target variant R,P,D,S,<empty>
LIB_VAR_SUFFIX ?= $(if $(filter-out R,$1),_$1)

# add defines from $(MTOP)/$(OS)/c.mk
PREDEFINES += $(OS_PREDEFINES)
APPDEFS    += $(OS_APPDEFS)
KRNDEFS    += $(OS_KRNDEFS)

# define code to print debug info about built targets
# note: GET_DEBUG_TARGETS - defined in $(MTOP)/defs.mk
# note: FORM_TRG will be defined below, VARIANTS_FILTER - defined in $(MTOP)/$(OS)/c.mk
DEBUG_C_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_TARGETS),FORM_TRG,VARIANTS_FILTER)

# rule that defines how to build object from source
# $1 - EXE,LIB,...
# $2 - CXX,CC,ASM,...
# $3 - source
# $4 - sdeps
# $5 - objdir
# $6 - variant (non-empty!)
# $7 - $5/$(basename $(notdir $3))
# if $(NO_DEPS) is empty, then try to include dependency file .d (ignore if file does not exist)
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
# NOTE: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) from $(STD_TARGET_VARS) changes $(ORDER_DEPS) value
define OBJ_RULE
$(empty)
$7$(OBJ_SUFFIX): $3 $(call EXTRACT_SDEPS,$3,$4) | $5 $$(ORDER_DEPS)
	$$(call $1_$6_$2,$$@,$$<)
$(if $(NO_DEPS),,-include $7.d)
$(call TOCLEAN,$7.d)
endef

# rule that defines how to build objects from sources
# $1 - EXE,LIB,...
# $2 - CXX,CC,ASM,...
# $3 - sources to compile
# $4 - sdeps
# $5 - objdir
# $6 - variant (if empty, then R)
OBJ_RULES ?= $(foreach v,$(patsubst ,R,$6),$(foreach x,$3,$(call OBJ_RULE,$1,$2,$x,$4,$5,$v,$5/$(basename $(notdir $x)))))

# generate target name suffix for DLL,EXE
# $1 - DLL,EXE...
# $2 - target variant S,P,... but not R or <empty>
# $3 - list of variants of target $1 to build (filtered by target platform specific $(VARIANTS_FILTER))
DLL_SUFFIX_GEN ?= $(if $(word 2,$3),$(call tolower,$2))

# determine target name suffix for DLL,EXE
# $1 - DLL,EXE...
# $2 - target variant R,S,P,<empty>
# $3 - list of variants of target $1 to build, by default $(wordlist 2,999999,$($1))
# Note: no suffix if building R-variant
# Note: variants list $3 may be not filtered by target platform specific $(VARIANTS_FILTER)
DLL_VAR_SUFFIX ?= $(if $(filter-out R,$2),$(call \
  DLL_SUFFIX_GEN,$1,$2,$(filter R $(VARIANTS_FILTER),$(if $3,$3,$(wordlist 2,999999,$($1))))))

# make target filename
# $1 - EXE,LIB,...
# $2 - target variant R,P,D,S,<empty>
# $3 - variants list, by default $(wordlist 2,999999,$($1))
# $(OS_FORM_TRG) - $(OS) may define more targets, for example, for DDD:
#  $(if $(filter DDD,$1),$(addprefix $(BIN_DIR)/$(DDD_PREFIX),$(addsuffix $(DLL_VAR_SUFFIX)$(DDD_SUFFIX),$(GET_TARGET_NAME))))
FORM_TRG ?= $(if \
  $(filter EXE,$1),$(addprefix $(BIN_DIR)/,$(addsuffix $(DLL_VAR_SUFFIX)$(EXE_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter LIB,$1),$(addprefix $(LIB_DIR)/$(LIB_PREFIX),$(addsuffix $(call LIB_VAR_SUFFIX,$2)$(LIB_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter DLL,$1),$(addprefix $(DLL_DIR)/$(DLL_PREFIX),$(addsuffix $(DLL_VAR_SUFFIX)$(DLL_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter KLIB,$1),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(addsuffix $(call LIB_VAR_SUFFIX,$2)$(KLIB_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter DRV,$1),$(addprefix $(BIN_DIR)/$(DRV_PREFIX),$(addsuffix $(DLL_VAR_SUFFIX)$(DRV_SUFFIX),$(GET_TARGET_NAME))),$(OS_FORM_TRG))))))

# example how to make target filenames for all variants specified for the target
# $1 - EXE,LIB,DLL,...
# $(foreach v,$(call GET_VARIANTS,$1),$(call FORM_TRG,$1,$v))

# subst $(space) with space character in defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES ?= $(subst $$(space),$(space),$1)

# helper macro for target makefiles to pass string define value to C-compiler
# may be already defined by $(MTOP)/$(OS)/c.mk
STRING_DEFINE ?= "$(subst $(space),$$$$(space),$(subst ",\",$1))"

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# note: do not touch $(SYSINCLUDE) - it may contain paths with spaces,
# note: $(SYSINCLUDE) paths are generally filtered-out while .d dependency file generation
TRG_INCLUDE ?= $(call FIXPATH,$(INCLUDE) $(CMNINCLUDE)) $(SYSINCLUDE)

# make list of sources for the target
# NOTE: this list does not include generated sources
GET_SOURCES ?= $(SRC) $(WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC ?= $(call FIXPATH,$(GET_SOURCES))

# make absolute paths for $(TRG_SDEPS) - add $(VPREFIX) to relative paths, then normalize paths
TRG_SDEPS ?= $(call FIX_SDEPS,$(SDEPS))

# objects to build for the target
# $1 - sources to compile
GET_OBJS ?= $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# VARIANT_LIB_MAP/VARIANT_IMP_MAP - functions that define which variant of
#  static/dynamic library to link with EXE or DLL, defined in $(MTOP)/$(OS)/c.mk
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent static/dynamic library name

# get suffix of dependent LIB
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent static library name
DEP_LIB_SUFFIX ?= $(call LIB_VAR_SUFFIX,$(VARIANT_LIB_MAP))

# get suffix of dependent DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent dynamic library name
DEP_IMP_SUFFIX ?= $(call LIB_VAR_SUFFIX,$(VARIANT_IMP_MAP))

# make file names of dependent libs
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - names of dependent libs
MAKE_DEP_LIBS ?= $(foreach l,$3,$(LIB_PREFIX)$l$(call DEP_LIB_SUFFIX,$1,$2,$l)$(LIB_SUFFIX))
MAKE_DEP_IMPS ?= $(foreach d,$3,$(IMP_PREFIX)$d$(call DEP_IMP_SUFFIX,$1,$2,$d)$(IMP_SUFFIX))

# static libraries target depends on
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_LIBS ?= $(addprefix $(LIB_DIR)/,$(call MAKE_DEP_LIBS,$1,$2,$(LIBS)))

# dynamic libraries target depends on
# assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(IMP_DIR) and DLL itself in $(DLL_DIR)
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_IMPS ?= $(addprefix $(IMP_DIR)/,$(call MAKE_DEP_IMPS,$1,$2,$(DLLS)))

# $1 - EXE,DLL,...
# $2 - $(call FORM_TRG,$1,$v)
# $3 - $(TRG_SRC)
# $4 - $(TRG_SDEPS)
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P,S,...
ifdef MCHECK
# check that target template is defined
TRG_RULES2 = $(if $(value $1_TEMPLATE),$(call $1_TEMPLATE,$2,$3,$4,$5,$(addprefix $5/,$(call GET_OBJS,$3))),$(error \
  $1_TEMPLATE not defined! (define it in $(MTOP)/$(OS)/c.mk)))
else
TRG_RULES2 = $(call $1_TEMPLATE,$2,$3,$4,$5,$(addprefix $5/,$(call GET_OBJS,$3)))
endif

# $1 - EXE,DLL,...
# $2 - $(TRG_SRC)
# $3 - $(TRG_SDEPS)
TRG_RULES1 = $(foreach v,$(GET_VARIANTS),$(newline)$(call TRG_RULES2,$1,$(call FORM_TRG,$1,$v),$2,$3,$(call FORM_OBJ_DIR,$1,$v)))

# expand target rules template $t_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - $(BLD_TARGETS)
ifdef MCHECK
# check that no other targets are defined
TRG_RULES ?= $(if $($(firstword $1)),$(foreach t,$(wordlist 2,999999,$1),$(if $($t),$(error \
  either $(firstword $1) or $t can be defined, but not both)))$(call \
  TRG_RULES1,$(firstword $1),$(TRG_SRC),$(TRG_SDEPS)),$(if $(word 2,$1),$(call TRG_RULES,$(wordlist 2,999999,$1))))
else
TRG_RULES ?= $(foreach t,$1,$(if $($t),$(call TRG_RULES1,$t,$(TRG_SRC),$(TRG_SDEPS))))
endif

# how to build executable, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,EXE,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,EXE,$v)
# $5 - objects:     $(addprefix $4/,$(call GET_OBJS,$2))
# $v - R,P,S,...
define EXE_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,EXE,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,EXE,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,EXE,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(LIBS)
$1: DLLS       := $(DLLS)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES)
$1: CFLAGS     := $(CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH)
$1: $(call DEP_LIBS,EXE,$v) $(call DEP_IMPS,EXE,$v) $5
	$$(call EXE_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build dynamic (shared) library, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,DLL,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,DLL,$v)
# $5 - objects:     $(addprefix $4/,$(call GET_OBJS,$2))
# $v - R,S
define DLL_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,DLL,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,DLL,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,DLL,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(LIBS)
$1: DLLS       := $(DLLS)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES)
$1: CFLAGS     := $(CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH)
$1: $(call DEP_LIBS,DLL,$v) $(call DEP_IMPS,DLL,$v) $5
	$$(call DLL_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build static library for EXE/DLL or static library for DLL only, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,LIB,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,LIB,$v)
# $5 - objects:     $(addprefix $4/,$(call GET_OBJS,$2))
# $v - R,P,D,S
define LIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,LIB,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,LIB,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,LIB,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES)
$1: CFLAGS     := $(CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS)
$1: $5
	$$(call LIB_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build kernel-mode static library for driver, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,KLIB,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,KLIB,$v)
# $5 - objects:     $(addprefix $4/,$(call GET_OBJS,$2))
# $v - R
define KLIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,KLIB,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,KLIB,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,KLIB,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(CMNDEFINES) $(KRNDEFS) $(DEFINES)
$1: CFLAGS     := $(CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS)
$1: $5
	$$(call KLIB_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# tools colors
CC_COLOR   := [01;31m
CXX_COLOR  := [01;36m
AR_COLOR   := [01;32m
LD_COLOR   := [01;33m
XLD_COLOR  := [01;37m
ASM_COLOR  := [00;37m
KCC_COLOR  := [00;31m
KLD_COLOR  := [00;33m
TCC_COLOR  := [00;32m
TCXX_COLOR := [00;32m
TLD_COLOR  := [00;33m
TXLD_COLOR := [01;37m
TAR_COLOR  := [01;32m

# check that LIBS specified only when building EXE or DLL,
# check that KLIBS specified only when building DRV
ifdef MCHECK
CHECK_C_RULES = $(if \
  $(CB_TOOL_MODE),$(if $(KLIB)$(DRV),$(error cannot build drivers in tool mode))) $(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL)) $(if \
  $(if $(DRV),,$(KLIBS)),$(warning KLIBS = $(KLIBS) is used only when building DRV))
endif

# project's subsystems directory, contains subsystems definitions that are evaluated while processing $(USE) list
ifndef PROJECT_USE_DIR
PROJECT_USE_DIR := $(TOP)/make/$(OS)/use
endif

# this code is normally evaluated at end of target makefile
# 1) print what we will build
# 2) include USE-references
# 3) if there are rules to generate sources - eval them before defining objects for the target
# 4) evaluate $(OS)-specific default targets before defining common default targets
#   to allow additional $(OS)-specific dependencies on targets
# 5) check and evaluate rules
# 6) evaluate $(DEF_TAIL_CODE)
define DEFINE_C_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_C_TARGETS)))
$(eval $(if $(MDEBUG),$(if $(USE),$(info using: $(USE))))$(newline)include $(addprefix $(PROJECT_USE_DIR)/,$(USE)))
$(eval $(GENERATE_SRC_RULES))
$(eval $(OS_DEFINE_TARGETS))
$(eval $(CHECK_C_RULES)$(call TRG_RULES,$(BLD_TARGETS)))
$(DEF_TAIL_CODE_EVAL)
endef

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define PREPARE_C_VARS
$(RESET_OS_CVARS)
$(foreach t,$(BLD_TARGETS),$t:=$(newline))
MODVER     := $(PRODUCT_VER)
CMNDEFINES := $(PREDEFINES)
CMNINCLUDE := $(DEFINCLUDE)
PCH:=
WITH_PCH:=
USE:=
SRC:=
SDEPS:=
DEFINES:=
INCLUDE:=
CFLAGS:=
CXXFLAGS:=
ASMFLAGS:=
LDFLAGS:=
SYSLIBS:=
SYSLIBPATH:=
SYSINCLUDE:=
DLLS:=
LIBS:=
KLIBS:=
DEFINE_TARGETS_EVAL_NAME := DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_C_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
# NOTE: expanded by $(MTOP)/c.mk
MAKE_C_EVAL = $(eval $(PREPARE_C_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,BLD_TARGETS OSTYPE_$(OSTYPE) OSVARIANT_$(OSVARIANT) LIB_VAR_SUFFIX \
  DEFINCLUDE PREDEFINES OS_PREDEFINES APPDEFS OS_APPDEFS KRNDEFS OS_KRNDEFS PRODUCT_VER DEBUG_C_TARGETS VARIANTS_FILTER \
  OSVARIANT OSTYPE OSVAR OSVARS OBJ_RULE OBJ_RULES DLL_SUFFIX_GEN DLL_VAR_SUFFIX FORM_TRG OS_FORM_TRG DLL_DIR IMP_DIR \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX DLL_PREFIX DLL_SUFFIX KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX \
  SUBST_DEFINES STRING_DEFINE TRG_INCLUDE GET_SOURCES TRG_SRC TRG_SDEPS GET_OBJS DEP_LIB_SUFFIX DEP_IMP_SUFFIX \
  VARIANT_LIB_MAP VARIANT_IMP_MAP MAKE_DEP_LIBS MAKE_DEP_IMPS DEP_LIBS DEP_IMPS \
  TRG_RULES2 TRG_RULES1 TRG_RULES EXE_TEMPLATE LIB_TEMPLATE DLL_TEMPLATE KLIB_TEMPLATE DRV_TEMPLATE \
  CC_COLOR CXX_COLOR AR_COLOR LD_COLOR XLD_COLOR ASM_COLOR \
  KCC_COLOR KLD_COLOR TCC_COLOR TCXX_COLOR TLD_COLOR TAR_COLOR CHECK_C_RULES PROJECT_USE_DIR \
  OS_DEFINE_TARGETS DEFINE_C_TARGETS_EVAL PREPARE_C_VARS RESET_OS_CVARS MAKE_C_EVAL)
