#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building C/C++ libs, dlls, executables, kernel-mode libraries

ifeq (,$(filter-out undefined environment,$(origin DEF_HEAD_CODE)))
include $(dir $(lastword $(MAKEFILE_LIST)))_defs.mk
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

# what we may build by including $(CLEAN_BUILD_DIR)/c.mk (for ex. LIB := my_lib)
# note: DRV is $(OS)-specific, $(OSDIR)/$(OS)/c.mk should define DRV_TEMPLATE
# note: $(OSDIR)/$(OS)/c.mk may append more target types to BLD_TARGETS
BLD_TARGETS := EXE LIB DLL

ifdef DRIVERS_SUPPORT
BLD_TARGETS += KLIB KDLL DRV
else
# reset by default
KLIB:=
KDLL:=
DRV:=
endif

# do not process generated dependencies when cleaning up
NO_DEPS := $(filter clean,$(MAKECMDGOALS))

# $1 - objdir
# $2 - source deps list
# $x - source
ADD_OBJ_SDEPS = $(if $2,$(newline)$1/$(basename $(notdir $x))$(OBJ_SUFFIX): $2)

# $1 - CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps
# $4 - objdir
# $5 - $(addsuffix $(OBJ_SUFFIX),$(addprefix $4/,$(basename $(notdir $2))))
# $6 - $t_$v_$1
# $v - non-empty variant: R,P,S,...
# $t - EXE,LIB,...
# note: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) from $(STD_TARGET_VARS) changes $(ORDER_DEPS) value
define OBJ_RULES2
$5
$(subst $(space),$(newline),$(join $(addsuffix :,$5),$2))$(if \
  $3,$(foreach x,$2,$(call ADD_OBJ_SDEPS,$4,$(call EXTRACT_SDEPS,$x,$3))))
$5:| $4 $$(ORDER_DEPS)
	$$(call $6,$$@,$$<)
endef

# $1 - CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps
# $4 - objdir
# $5 - $(addprefix $4/,$(basename $(notdir $2)))
# $v - non-empty variant: R,P,S,...
# $t - EXE,LIB,...
ifdef TOCLEAN
OBJ_RULES1 = $(call TOCLEAN,$(addsuffix .d,$5) $(addsuffix $(OBJ_SUFFIX),$5))
else
OBJ_RULES1 = $(call OBJ_RULES2,$1,$2,$3,$4,$(addsuffix $(OBJ_SUFFIX),$5),$t_$v_$1)
ifndef NO_DEPS
OBJ_RULES1 += $(newline)-include $(addsuffix .d,$5)
endif
endif

# rule that defines how to build objects from sources
# $1 - CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps
# $4 - objdir
# $v - non-empty variant: R,P,S,...
# $t - EXE,LIB,...
# note: $(CLEAN_BUILD_DIR)/WINXX/c.mk overrides OBJ_RULES
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$1,$2,$3,$4,$(addprefix $4/,$(basename $(notdir $2)))))

# get target name suffix for EXE,DRV... in case of multiple target variants
# $1 - EXE,DRV...
# $2 - target variant S,P,... but not R or <empty>
# $3 - list of variants of target $1 to build (filtered by target platform specific $(VARIANTS_FILTER))
# note: WINXX/c.mk defines own EXE_SUFFIX_GEN
# note: LINUX/c.mk defines own EXE_SUFFIX_GEN
EXE_SUFFIX_GEN = $(if $(word 2,$3),$(call tolower,$2))

# determine target name suffix for EXE,DRV...
# $1 - EXE,DRV...
# $2 - target variant R,S,P,<empty>
# $3 - list of variants of target $1 to build, by default $(wordlist 2,999999,$($1))
# Note: no suffix if building R-variant
# Note: variants list $3 may be not filtered by target platform specific $(VARIANTS_FILTER)
EXE_VAR_SUFFIX = $(if $(filter-out R,$2),$(call \
  EXE_SUFFIX_GEN,$1,$2,$(filter R $(VARIANTS_FILTER),$(if $3,$3,$(wordlist 2,999999,$($1))))))

# determine suffix for static LIB or for implementation-library of DLL
# $1 - target variant R,P,D,S,<empty>
# note: WINXX/c.mk defines own LIB_VAR_SUFFIX
LIB_VAR_SUFFIX = $(if $(filter-out R,$1),_$1)

# $(OSDIR)/$(OS)/c.mk may define more targets, for example, to define DDD:
# OS_FORM_TRG = $(if $(filter DDD,$1),$(addprefix $(BIN_DIR)/$(DDD_PREFIX),$(GET_TARGET_NAME:=$(EXE_VAR_SUFFIX)$(DDD_SUFFIX))))
OS_FORM_TRG:=

# make target filename
# $1 - EXE,LIB,...
# $2 - target variant R,P,D,S,<empty>
# $3 - variants list, by default $(wordlist 2,999999,$($1))
# note: gives empty result if $($1) is empty
FORM_TRG = $(if \
  $(filter EXE,$1),$(addprefix $(BIN_DIR)/,$(GET_TARGET_NAME:=$(EXE_VAR_SUFFIX)$(EXE_SUFFIX))),$(if \
  $(filter KDLL,$1),$(addprefix $(DLL_DIR)/$(KDLL_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(KDLL_SUFFIX))),$(if \
  $(filter DLL,$1),$(addprefix $(DLL_DIR)/$(DLL_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(DLL_SUFFIX))),$(if \
  $(filter KLIB,$1),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(KLIB_SUFFIX))),$(if \
  $(filter LIB,$1),$(addprefix $(LIB_DIR)/$(LIB_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(LIB_SUFFIX))),$(if \
  $(filter DRV,$1),$(addprefix $(BIN_DIR)/$(DRV_PREFIX),$(GET_TARGET_NAME:=$(EXE_VAR_SUFFIX)$(DRV_SUFFIX))),$(OS_FORM_TRG)))))))

# example how to make target filenames for all variants specified for the target
# $1 - EXE,LIB,DLL,...
# $(foreach v,$(call GET_VARIANTS,$1),$(call FORM_TRG,$1,$v))

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# note: do not touch paths in $(SYSINCLUDE) - assume they are absolute,
# note: $(SYSINCLUDE) paths are generally filtered-out while .d dependency file generation
TRG_INCLUDE = $(call fixpath,$(INCLUDE)) $(SYSINCLUDE)

# target flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
# note: these macros may be overridden in project configuration makefile, for example:
# TRG_DEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) $(foreach \
#   c,$($(if $(filter DRV KLIB KDLL,$t),K,$(TMD))CPU),$(if \
#   $(filter sparc% mips% ppc%,$c),B_ENDIAN,L_ENDIAN) $(if \
#   $(filter arm% sparc% mips% ppc%,$c),ADDRESS_NEEDALIGN)) $(DEFINES)
TRG_DEFINES  = $(DEFINES)
TRG_CFLAGS   = $(CFLAGS)
TRG_CXXFLAGS = $(CXXFLAGS)
TRG_ASMFLAGS = $(ASMFLAGS)
TRG_LDFLAGS  = $(LDFLAGS)

# make list of sources for the target
# NOTE: this list does not include generated sources
GET_SOURCES = $(SRC) $(WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC = $(call fixpath,$(GET_SOURCES))

# make absolute paths for $(TRG_SDEPS)
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS))

# objects to build for the target
# $1 - sources to compile
GET_OBJS = $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# VARIANT_LIB_MAP/VARIANT_IMP_MAP - functions that define which variant of
#  static/dynamic library to link with EXE or DLL, defined in $(OSDIR)/$(OS)/c.mk
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent static/dynamic library name

# get suffix of dependent LIB
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent static library name
DEP_LIB_SUFFIX = $(call LIB_VAR_SUFFIX,$(VARIANT_LIB_MAP))

# get suffix of dependent DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - dependent dynamic library name
DEP_IMP_SUFFIX = $(call LIB_VAR_SUFFIX,$(VARIANT_IMP_MAP))

# make file names of dependent libs
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# $3 - names of dependent libs
MAKE_DEP_LIBS = $(foreach l,$3,$(LIB_PREFIX)$l$(call DEP_LIB_SUFFIX,$1,$2,$l)$(LIB_SUFFIX))
MAKE_DEP_IMPS = $(foreach d,$3,$(IMP_PREFIX)$d$(call DEP_IMP_SUFFIX,$1,$2,$d)$(IMP_SUFFIX))

# static libraries target depends on
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_LIBS = $(call MAKE_DEP_LIBS,$1,$2,$(LIBS))

# dynamic libraries target depends on
# assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(LIB_DIR) and DLL itself in $(DLL_DIR)
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_IMPS = $(call MAKE_DEP_IMPS,$1,$2,$(DLLS))

# process result of STRING_DEFINE to make values of defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES = $(eval SUBST_DEFINES_:=$(subst $(comment),$$(comment),$1))$(SUBST_DEFINES_)

# helper macro for target makefiles to pass string define value to C-compiler
# result of this macro will be processed by SUBST_DEFINES
# note: WINXX/c.mk defines own STRING_DEFINE macro
STRING_DEFINE = "$(subst ",\",$(subst $(tab),$$(tab),$(subst $(space),$$(space),$(subst $$,$$$$,$1))))"

# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(TRG_SRC)
# $3 - $(TRG_SDEPS)
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,...
# $v - non-empty variant: R,P,S,...
ifdef MCHECK
# check that target template is defined
C_RULES2 = $(if $(value $t_TEMPLATE),$($t_TEMPLATE),$(error $t_TEMPLATE not defined! (define it in $(OSDIR)/$(OS)/c.mk)))
else
C_RULES2 = $($t_TEMPLATE)
endif

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $t - EXE,DLL,...
C_RULES1 = $(foreach v,$(call GET_VARIANTS,$t),$(newline)$(call C_RULES2,$(call FORM_TRG,$t,$v),$1,$2,$(call FORM_OBJ_DIR,$t,$v)))

# expand target rules template $t_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - $(BLD_TARGETS)
C_RULES = $(foreach t,$1,$(if $($t),$(call C_RULES1,$(TRG_SRC),$(TRG_SDEPS))))

# how to build executable, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE or DLL
# $v - non-empty variant: R,P,S,...
define EXE_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS+=$4
$1:$(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1:$(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1:COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1:LIB_DIR    := $(LIB_DIR)
$1:LIBS       := $(LIBS)
$1:DLLS       := $(DLLS)
$1:INCLUDE    := $(TRG_INCLUDE)
$1:DEFINES    := $(TRG_DEFINES)
$1:CFLAGS     := $(TRG_CFLAGS)
$1:CXXFLAGS   := $(TRG_CXXFLAGS)
$1:ASMFLAGS   := $(TRG_ASMFLAGS)
$1:LDFLAGS    := $(TRG_LDFLAGS)
$1:SYSLIBS    := $(SYSLIBS)
$1:SYSLIBPATH := $(SYSLIBPATH)
$1:$(addprefix $(LIB_DIR)/,$(call DEP_LIBS,$t,$v) $(call DEP_IMPS,$t,$v))
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# how to build dynamic (shared) library, used by $(C_RULES)
DLL_TEMPLATE = $(EXE_TEMPLATE)

# how to build static library for EXE/DLL or static library for DLL only, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - LIB
# $v - non-empty variant: R,P,D,S
define LIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS+=$4
$1:$(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1:$(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1:COMPILER := $(if $(filter %.cpp,$2),CXX,CC)
$1:INCLUDE  := $(TRG_INCLUDE)
$1:DEFINES  := $(TRG_DEFINES)
$1:CFLAGS   := $(TRG_CFLAGS)
$1:CXXFLAGS := $(TRG_CXXFLAGS)
$1:ASMFLAGS := $(TRG_ASMFLAGS)
$1:LDFLAGS  := $(TRG_LDFLAGS)
$1:
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# how to build kernel-mode static library for driver, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - KLIB
# $v - non-empty variant: R
define KLIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS+=$4
$1:$(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1:$(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1:COMPILER := $(if $(filter %.cpp,$2),CXX,CC)
$1:INCLUDE  := $(TRG_INCLUDE)
$1:DEFINES  := $(TRG_DEFINES)
$1:CFLAGS   := $(TRG_CFLAGS)
$1:CXXFLAGS := $(TRG_CXXFLAGS)
$1:ASMFLAGS := $(TRG_ASMFLAGS)
$1:LDFLAGS  := $(TRG_LDFLAGS)
$1:
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# tools colors
CC_COLOR   := [1;31m
CXX_COLOR  := [1;36m
AR_COLOR   := [1;32m
LD_COLOR   := [1;33m
XLD_COLOR  := [1;37m
ASM_COLOR  := [0;37m
KCC_COLOR  := [0;31m
KCXX_COLOR := [0;36m
KLD_COLOR  := [0;33m
TCC_COLOR  := [0;32m
TCXX_COLOR := [0;32m
TLD_COLOR  := [0;33m
TXLD_COLOR := [1;37m
TAR_COLOR  := [1;32m

# check that LIBS specified only when building EXE or DLL,
# check that KLIBS specified only when building DRV
ifdef MCHECK
CHECK_C_RULES = $(if \
  $(TMD),$(if $(KDLL)$(KLIB)$(DRV),$(error cannot build drivers in tool mode)))$(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL))$(if \
  $(if $(EXE)$(DLL),,$(DLLS)),$(warning DLLS = $(DLLS) is used only when building EXE or DLL))$(if \
  $(if $(DRV)$(KDLL),,$(KLIBS)),$(warning KLIBS = $(KLIBS) is used only when building DRV or KDLL))$(if \
  $(if $(DRV)$(KDLL),,$(KDLLS)),$(warning KDLLS = $(KDLLS) is used only when building DRV or KDLL))
else
CHECK_C_RULES:=
endif

# auxiliary definitions possibly defined in $(OSDIR)/$(OS)/c.mk
OS_DEFINE_TARGETS:=

# this code is normally evaluated at end of target makefile
# 1) print what we will build
# 2) if there are rules to generate sources - eval them before defining objects for the target
# 3) evaluate $(OS)-specific default targets before defining common default targets
#   to allow additional $(OS)-specific dependencies on targets
# 4) check and evaluate rules
# 5) evaluate $(DEF_TAIL_CODE)
define DEFINE_C_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(call DEBUG_TARGETS,$(BLD_TARGETS),FORM_TRG,VARIANTS_FILTER)))
$(eval $(OS_DEFINE_TARGETS))
$(eval $(CHECK_C_RULES)$(call C_RULES,$(BLD_TARGETS)))
$(DEF_TAIL_CODE_EVAL)
endef

# product version in form major.minor or major.minor.patch
# note: this is also default version for any built module (exe, dll or driver)
PRODUCT_VER := 0.0.1

# reset variables in from $(BLD_TARGETS) list
BLD_TARGETS_RESET := $(subst $(space),:=$(newline),$(BLD_TARGETS)):=

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define PREPARE_C_VARS
$(BLD_TARGETS_RESET)
MODVER:=$(PRODUCT_VER)
PCH:=
WITH_PCH:=
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
KDLLS:=
DEFINE_TARGETS_EVAL_NAME:=DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME:=CLEAN_BUILD_C_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# NOTE: expanded by $(CLEAN_BUILD_DIR)/c.mk
CLEAN_BUILD_C_EVAL = $(eval $(DEF_HEAD_CODE)$(PREPARE_C_VARS))

# note: $(OSDIR)/$(OS)/c.mk must define VARIANTS_FILTER
include $(OSDIR)/$(OS)/c.mk

# check if no new variables introduced in PREPARE_C_VARS
ifeq (,$(findstring $$,$(subst \
  $$(BLD_TARGETS_RESET),,$(subst \
  $$(PRODUCT_VER),,$(value PREPARE_C_VARS)))))

# check if BLD_TARGETS_RESET and PRODUCT_VER are simple
ifeq (2,$(words $(filter simple,$(flavor \
  BLD_TARGETS_RESET) $(flavor \
  PRODUCT_VER))))

# then make PREPARE_C_VARS non-recursive (simple)
override PREPARE_C_VARS := $(PREPARE_C_VARS)

endif # words
endif # findstring

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,BLD_TARGETS NO_DEPS ADD_OBJ_SDEPS=x OBJ_RULES2=t;v OBJ_RULES1=t;v OBJ_RULES=t;v \
  VARIANTS_FILTER EXE_SUFFIX_GEN EXE_VAR_SUFFIX LIB_VAR_SUFFIX DLL_DIR OS_FORM_TRG FORM_TRG \
  TRG_INCLUDE=t;v;SYSINCLUDE TRG_DEFINES=t;v;DEFINES TRG_CFLAGS=t;v;CFLAGS \
  TRG_CXXFLAGS=t;v;CXXFLAGS TRG_ASMFLAGS=t;v;ASMFLAGS TRG_LDFLAGS=t;v;LDFLAGS \
  GET_SOURCES=SRC;WITH_PCH TRG_SRC TRG_SDEPS=SDEPS GET_OBJS VARIANT_LIB_MAP VARIANT_IMP_MAP \
  DEP_LIB_SUFFIX DEP_IMP_SUFFIX MAKE_DEP_LIBS MAKE_DEP_IMPS DEP_LIBS=LIBS DEP_IMPS=DLLS \
  SUBST_DEFINES STRING_DEFINE C_RULES2=t;v C_RULES1=t C_RULES \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX DLL_PREFIX DLL_SUFFIX \
  KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX KDLL_PREFIX KDLL_SUFFIX \
  EXE_TEMPLATE=t;v;EXE;LIB_DIR;LIBS;DLLS;SYSLIBS;SYSLIBPATH LIB_TEMPLATE=t;v;LIB DLL_TEMPLATE=t;v;DLL KLIB_TEMPLATE=t;v;KLIB \
  CC_COLOR CXX_COLOR AR_COLOR LD_COLOR XLD_COLOR ASM_COLOR \
  KCC_COLOR KCXX_COLOR KLD_COLOR TCC_COLOR TCXX_COLOR TLD_COLOR TXLD_COLOR TAR_COLOR CHECK_C_RULES \
  OS_DEFINE_TARGETS DEFINE_C_TARGETS_EVAL PRODUCT_VER BLD_TARGETS_RESET PREPARE_C_VARS CLEAN_BUILD_C_EVAL)
