#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules for building C/C++ targets: libs, dlls, executables, kernel modules, etc.

ifeq (,$(filter-out undefined environment,$(origin DEF_HEAD_CODE_EVAL)))
include $(dir $(lastword $(MAKEFILE_LIST)))../core/_defs.mk
endif

# built targets and variants:
# note: all variants have the same C-preprocessor defines, but are compiled with different C-compiler flags
# EXE - executable, variants:      R,P,S
# LIB - static library, variants:  R,P,D,S (P-version - library only for EXE, D-version - library only for DLL)
# DLL - dynamic library, variants: R,S
# if variant is not specified, default variant R will be built, else - only specified variants (add R to build also default variant)

# after target name may be specified one or more build target variants (for ex. EXE := my_exe R S):
# R - default build variant:
#  EXE - position-dependent code   (UNIX), dynamically linked multi-threaded libc (WINDOWS)
#  LIB - position-dependent code   (UNIX), dynamically linked multi-threaded libc (WINDOWS)
#  DLL - position-independent code (UNIX), dynamically linked multi-threaded libc (WINDOWS)
# P - position-independent code in executables      (for EXE and LIB) (only UNIX)
# D - position-independent code in shared libraries (only for LIB)    (only UNIX)
# S - statically linked multithreaded libc          (for all targets) (only WINDOWS)

# add source-dependencies for an object file
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
# note: postpone expansion of ORDER_DEPS to optimize parsing
define OBJ_RULES_BODY
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
OBJ_RULES1 = $(call OBJ_RULES_BODY,$1,$2,$3,$4,$(addsuffix $(OBJ_SUFFIX),$5),$t_$v_$1)
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
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides OBJ_RULES
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$1,$2,$3,$4,$(addprefix $4/,$(basename $(notdir $2)))))

# variants filter function - get possible variants for the target over than default variant R
# $1 - LIB,EXE,DLL
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
# note: $(CLEAN_BUILD_DIR)/compilers/gcc.mk defines own VARIANTS_FILTER
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk defines own VARIANTS_FILTER
VARIANTS_FILTER = $(if $(filter LIB,$1),D)

# get target name suffix for EXE,DRV... in case of multiple target variants
# $1 - EXE,DRV...
# $2 - target variant S,P,... but not R or <empty>
# $3 - list of variants of target $1 to build (filtered by target platform specific $(VARIANTS_FILTER))
# note: $(CLEAN_BUILD_DIR)/compilers/gcc.mk defines own EXE_SUFFIX_GEN
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk defines own EXE_SUFFIX_GEN
EXE_SUFFIX_GEN = $(if $(word 2,$3),$(call tolower,$2))

# determine target name suffix for EXE,DRV...
# $1 - EXE,DRV...
# $2 - target variant R,S,P,<empty>
# $3 - list of variants of target $1 to build, by default $(wordlist 2,999999,$($1))
# note: no suffix if building R-variant
# note: variants list $3 may be not filtered by target platform specific $(VARIANTS_FILTER), so filter it here
EXE_VAR_SUFFIX = $(if $(filter-out R,$2),$(call \
  EXE_SUFFIX_GEN,$1,$2,$(filter R $(VARIANTS_FILTER),$(if $3,$3,$(wordlist 2,999999,$($1))))))

# determine suffix for static LIB or for import library of DLL
# $1 - target variant R,P,D,S,<empty>
# note: $(CLEAN_BUILD_DIR)/compilers/gcc.mk defines own LIB_VAR_SUFFIX
# note: $(CLEAN_BUILD_DIR)/compilers/suncc.mk defines own LIB_VAR_SUFFIX
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk defines own LIB_VAR_SUFFIX
LIB_VAR_SUFFIX = $(if $(filter-out R,$1),_$1)

# get absolute path to target file
# $1 - EXE,LIB,...
# $2 - target variant R,P,D,S,<empty>
# $3 - variants list, by default $(wordlist 2,999999,$($1))
# note: use $(addprefix...) to return empty if $($1) is empty
FORM_TRG = $(if $(filter \
  EXE,$1),$(addprefix $(BIN_DIR)/,$(GET_TARGET_NAME:=$(EXE_VAR_SUFFIX)$(EXE_SUFFIX))),$(if $(filter \
  DLL,$1),$(addprefix $(DLL_DIR)/$(DLL_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(DLL_SUFFIX))),$(if $(filter \
  LIB,$1),$(addprefix $(LIB_DIR)/$(LIB_PREFIX),$(GET_TARGET_NAME:=$(call LIB_VAR_SUFFIX,$2)$(LIB_SUFFIX))),$(error \
  unknown target type: $1))))

# get filenames of all variants of the target
# $1 - EXE,LIB,DLL,...
ALL_TRG = $(foreach v,$(call GET_VARIANTS,$1),$(call FORM_TRG,$1,$v))

# which compiler type to use for the target? CXX or CC?
# note: CXX compiler may compile C sources, but also links standard C++ library (libstdc++.so)
# $1     - target file: $(call FORM_TRG,$t,$v)
# $2     - sources:     $(TRG_SRC)
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_COMPILER = $(if $(filter %.cpp,$2),CXX,CC)

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# note: do not touch paths in $(SYSINCLUDE) - assume they are absolute,
# note: $(SYSINCLUDE) paths are normally filtered-out while .d dependency file generation
TRG_INCLUDE = $(call fixpath,$(INCLUDE)) $(SYSINCLUDE)

# target flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
# note: these macros may be overridden in project configuration makefile, for example:
# TRG_DEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) $(foreach \
#   cpu,$($(if $(filter DRV KLIB KDLL,$t),K,$(TMD))CPU),$(if \
#   $(filter sparc% mips% ppc%,$(cpu)),B_ENDIAN,L_ENDIAN) $(if \
#   $(filter arm% sparc% mips% ppc%,$(cpu)),ADDRESS_NEEDALIGN)) $(DEFINES)
TRG_DEFINES  = $(DEFINES)
TRG_CFLAGS   = $(CFLAGS)
TRG_CXXFLAGS = $(CXXFLAGS)
TRG_LDFLAGS  = $(LDFLAGS)

# make list of sources for the target, used by TRG_SRC
# note: overridden in $(CLEAN_BUILD_DIR)/compilers/gcc.mk
GET_SOURCES = $(SRC)

# function to add (generated?) sources to list of sources compiled with precompiled header (pch)
# $1 - EXE,LIB,DLL,...
# $2 - sources
# note: PCH header must be specified before expanding this macro
# note: overridden in $(CLEAN_BUILD_DIR)/compilers/gcc.mk
ADD_WITH_PCH = $(eval SRC+=$2)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC = $(call fixpath,$(GET_SOURCES))

# make absolute paths of source dependencies
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS))

# objects to build for the target
# $1 - sources to compile
GET_OBJS = $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# for DEP_LIB_SUFFIX, determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependent static library name
# use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
# always use D-variant of static library for DLL
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides VARIANT_LIB_MAP
VARIANT_LIB_MAP = $(if $(filter DLL,$1),D,$2)

# for DEP_IMP_SUFFIX, determine which variant of dynamic library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with any P- or R-EXE or R-DLL
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides VARIANT_IMP_MAP
VARIANT_IMP_MAP := R

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

# helper macro for target makefiles to pass string define value to C-compiler
# result of this macro will be processed by SUBST_DEFINES
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk defines own STRING_DEFINE macro
STRING_DEFINE = "$(subst ",$(backslash)",$(subst $(tab),$$(tab),$(subst $(space),$$(space),$(subst $$,$$$$,$1))))"

# process result of STRING_DEFINE to make values of defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES = $(eval SUBST_DEFINES_:=$(subst $(comment),$$(comment),$1))$(SUBST_DEFINES_)

# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(TRG_SRC)
# $3 - $(TRG_SDEPS)
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,...
# $v - non-empty variant: R,P,S,...
C_RULESv = $($t_TEMPLATE)

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $t - EXE,DLL,...
C_RULESt = $(foreach v,$(call GET_VARIANTS,$t),$(call C_RULESv,$(call FORM_TRG,$t,$v),$1,$2,$(call FORM_OBJ_DIR,$t,$v))$(newline))

# expand target rules template $t_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
C_RULES = $(foreach t,EXE DLL LIB,$(if $($t),$(C_RULESt)))

# base template for C/C++ targets
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $v - non-empty variant: R,P,S,...
define C_BASE_TEMPLATE
NEEDED_DIRS+=$4
$(STD_TARGET_VARS)
$1:$(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1:COMPILER := $(TRG_COMPILER)
$1:INCLUDE  := $(TRG_INCLUDE)
$1:DEFINES  := $(TRG_DEFINES)
$1:CFLAGS   := $(TRG_CFLAGS)
$1:CXXFLAGS := $(TRG_CXXFLAGS)
endef

# template for building executables, used by C_RULES macro
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE or DLL
# $v - non-empty variant: R,P,S,...
# note: target-specific variables are passed to dependencies, so templates for
#  dependent libs/dlls must override INCLUDE, DEFINES, CFLAGS and other sensible variables
define EXE_TEMPLATE
$(C_BASE_TEMPLATE)
$1:LDFLAGS    := $(TRG_LDFLAGS)
$1:LIB_DIR    := $(LIB_DIR)
$1:LIBS       := $(LIBS)
$1:DLLS       := $(DLLS)
$1:SYSLIBS    := $(SYSLIBS)
$1:SYSLIBPATH := $(SYSLIBPATH)
$1:$(addprefix $(LIB_DIR)/,$(call DEP_LIBS,$t,$v) $(call DEP_IMPS,$t,$v))
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# template for building dynamic (shared) libraries, used by C_RULES
DLL_TEMPLATE = $(EXE_TEMPLATE)

# template for building static library for EXE/DLL or static library for DLL only, used by C_RULES
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - LIB
# $v - non-empty variant: R,P,D,S
define LIB_TEMPLATE
$(C_BASE_TEMPLATE)
$1:LDFLAGS := $(TRG_LDFLAGS)
$1:
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# tools colors: C, C++ compilers, library archiver, shared library and executable linkers
CC_COLOR   := [1;31m
CXX_COLOR  := [1;36m
AR_COLOR   := [1;32m
LD_COLOR   := [1;33m
XLD_COLOR  := [1;37m
TCC_COLOR  := [32m
TCXX_COLOR := [32m
TAR_COLOR  := [1;32m
TLD_COLOR  := [33m
TXLD_COLOR := [1;37m

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define PREPARE_C_VARS
MODVER:=$(PRODUCT_VER)
EXE:=
DLL:=
LIB:=
SRC:=
SDEPS:=
DEFINES:=
INCLUDE:=
CFLAGS:=
CXXFLAGS:=
LDFLAGS:=
SYSLIBS:=
SYSLIBPATH:=
SYSINCLUDE:=
LIBS:=
DLLS:=
DEFINE_TARGETS_EVAL_NAME:=DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME:=CLEAN_BUILD_C_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# NOTE: expanded by $(CLEAN_BUILD_DIR)/c.mk
CLEAN_BUILD_C_EVAL = $(DEF_HEAD_CODE_EVAL)$(eval $(PREPARE_C_VARS))

# this code is normally evaluated at end of target makefile
DEFINE_C_TARGETS_EVAL = $(eval $(call C_RULES,$(TRG_SRC),$(TRG_SDEPS)))$(DEF_TAIL_CODE_EVAL)

# check that LIBS or DLLS are specified only when building EXE or DLL
ifdef MCHECK
CHECK_C_RULES = $(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL))$(if \
  $(if $(EXE)$(DLL),,$(DLLS)),$(warning DLLS = $(DLLS) is used only when building EXE or DLL))
$(eval DEFINE_C_TARGETS_EVAL = $$(CHECK_C_RULES)$(value DEFINE_C_TARGETS_EVAL))
endif

# do not support assembler by default
# note: ASSEMBLER_SUPPORT may be overridden in protect configuration makefile
# note: if ASSEMBLER_SUPPORT is defined, then must also be defined different assemblers, called from $(OBJ_RULES_BODY):
#  EXE_R_ASM, LIB_R_ASM, LIB_D_ASM, etc. - for all supported target variants
ASSEMBLER_SUPPORT:=

# ensure ASSEMBLER_SUPPORT variable is non-recursive (simple)
override ASSEMBLER_SUPPORT := $(ASSEMBLER_SUPPORT)

ifdef ASSEMBLER_SUPPORT
include $(CLEAN_BUILD_DIR)/impl/asm.mk
endif

# optimization
$(call try_make_simple,PREPARE_C_VARS,PRODUCT_VER)

# protect variables from modifications in target makefiles
# note: GET_SOURCES and ADD_WITH_PCH are may be overridden in next included $(C_COMPILER)
$(call SET_GLOBAL,BLD_TARGETS ADD_OBJ_SDEPS=x OBJ_RULES_BODY=t;v OBJ_RULES1=t;v OBJ_RULES=t;v \
  VARIANTS_FILTER EXE_SUFFIX_GEN EXE_VAR_SUFFIX LIB_VAR_SUFFIX DLL_DIR FORM_TRG ALL_TRG \
  TRG_COMPILER=t;v TRG_INCLUDE=t;v;SYSINCLUDE TRG_DEFINES=t;v;DEFINES TRG_CFLAGS=t;v;CFLAGS \
  TRG_CXXFLAGS=t;v;CXXFLAGS TRG_LDFLAGS=t;v;LDFLAGS GET_SOURCES=SRC ADD_WITH_PCH=SRC=SRC \
  TRG_SRC TRG_SDEPS=SDEPS GET_OBJS VARIANT_LIB_MAP VARIANT_IMP_MAP \
  DEP_LIB_SUFFIX DEP_IMP_SUFFIX MAKE_DEP_LIBS MAKE_DEP_IMPS DEP_LIBS=LIBS DEP_IMPS=DLLS \
  STRING_DEFINE SUBST_DEFINES C_RULESv=t;v C_RULESt=t C_RULES \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX DLL_PREFIX DLL_SUFFIX \
  C_BASE_TEMPLATE=t;v EXE_TEMPLATE=t;v;EXE;LIB_DIR;LIBS;DLLS;SYSLIBS;SYSLIBPATH DLL_TEMPLATE=t;v;DLL LIB_TEMPLATE=t;v;LIB \
  CC_COLOR CXX_COLOR AR_COLOR LD_COLOR XLD_COLOR TCC_COLOR TCXX_COLOR TAR_COLOR TLD_COLOR TXLD_COLOR \
  PREPARE_C_VARS CLEAN_BUILD_C_EVAL DEFINE_C_TARGETS_EVAL CHECK_C_RULES)

# protect variables from modifications in target makefiles
# note: do not trace calls to ASSEMBLER_SUPPORT variable because it is used in ifdefs
$(call SET_GLOBAL,ASSEMBLER_SUPPORT,0)
