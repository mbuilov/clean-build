#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building C/C++ libs, dlls, executables

ifndef DEF_HEAD_CODE
include $(MTOP)/_defs.mk
endif

# separate group of defines for each build target type (EXE,LIB,DLL,...)
# - to allow to build many targets (for example LIB, EXE and DLL) specified in one makefile

# use target-specific variables
# NOTE: all targets defined at the same time share the same values of common vars LIBS,DLLS,CFLAGS,...
# but also may have target-specific variable value, for example EXE_INCLUDE,LIB_CFLAGS,...

# build targets:
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
BLD_TARGETS := EXE LIB DLL KLIB DRV

# list of variables that may have target-dependent variants (EXE_PCH, LIB_SRC and so on)
# NOTE: these variables may also have $OS-dependent variants: {,EXE_,LIB_,DLL_,KLIB_,DRV_}$v{,_$(OSVARIANT),_$(OS),_$(OSTYPE)}
# for example: EXE_SRC_WINXP, CFLAGS_LINUX, LDFLAGS_WINXX and so on
TRG_VARS := PCH WITH_PCH SRC SDEPS DEFINES INCLUDE CFLAGS CXXFLAGS ASMFLAGS LDFLAGS SYSLIBS SYSLIBPATH SYSINCLUDE DLLS LIBS

# variables without target-dependent variants
# NOTE: these variables may also have $OS-dependent variants: $v{,_$(OSVARIANT),_$(OS),_$(OSTYPE)}
# for example: KLIBS_LINUX, CMNINCLUDE_WINXX, CLEAN_UNIX and so on
BLD_VARS := KLIBS CMNINCLUDE CLEAN

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

# determine suffix for static LIB or for implementation-library of DLL
# $1 - target variant R,P,D,S,<empty>
LIB_VAR_SUFFIX ?= $(if $(filter-out R,$1),_$1)

# list of all variables for the targets: SRC, DEFINES, CMNINCLUDE and so on
# NOTE: these variables may also have $OS-dependent variants
BLD_VARS += $(TRG_VARS)

# add defines from $(MTOP)/$(OS)/c.mk
PREDEFINES += $(OS_PREDEFINES)
APPDEFS    += $(OS_APPDEFS)
KRNDEFS    += $(OS_KRNDEFS)

# define code to print debug info about built targets
# note: GET_DEBUG_TARGETS - defined in $(MTOP)/defs.mk
# note: FORM_TRG will be defined below, VARIANTS_FILTER - defined in $(MTOP)/$(OS)/c.mk
DEBUG_C_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_TARGETS),FORM_TRG,VARIANTS_FILTER)

# template to prepend value of $(OS)-dependent variables to variable $1, then clear $(OS)-dependent variables
# NOTE: preferred values must be first: $1_$(OSVARIANT) is preferred over $1_$(OS) and so on
# - in some cases we want just the first value (for MAP or DEF value for example)
ifdef OSVARIANT
define OSVAR
$1:=$$(strip $$($1_$(OSVARIANT)) $$($1_$(OS)) $$($1_$(OSTYPE)) $$($1))
$1_$(OS):=
$1_$(OSVARIANT):=
$1_$(OSTYPE):=
$(empty)
endef
else
define OSVAR
$1:=$$(strip $$($1_$(OS)) $$($1_$(OSTYPE)) $$($1))
$1_$(OS):=
$1_$(OSTYPE):=
$(empty)
endef
endif

# code for adding OS-specific values to variables, then clearing OS-specific values
# KLIBS       := $(KLIBS_WINXX)       $(KLIBS_WINXP)        $(KLIBS_WINDOWS)    $(KLIBS)
# EXE_DEFINES := $(EXE_DEFINES_LINUX) $(EXE_DEFINES_DEBIAN) $(EXE_DEFINES_UNIX) $(EXE_DEFINES)
OSVARS := $(foreach r,$(BLD_VARS) $(foreach t,$(BLD_TARGETS),$(addprefix $t_,$(TRG_VARS))),$(call OSVAR,$r))

# rule that defines how to build object from source
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - source, $4 - sdeps, $5 - objdir, $6 - variant (non-empty!), $7 - $(basename $(notdir $3))
# if $(NO_DEPS) is empty, then try to include dependency file .d (ignore if file does not exist)
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
define OBJ_RULE
$(empty)
$5/$7$(OBJ_SUFFIX): $3 $(call EXTRACT_SDEPS,$3,$4) | $5 $$(ORDER_DEPS)
	$$(call $1_$6_$2,$$@,$$<)
ifeq ($(NO_DEPS),)
-include $5/$7.d
endif
$(call TOCLEAN,$5/$7.d)
endef

# rule that defines how to build objects from sources
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - sources to compile, $4 - sdeps, $5 - objdir, $6 - variant (if empty, then R)
OBJ_RULES1 = $(foreach x,$3,$(call OBJ_RULE,$1,$2,$x,$4,$5,$6,$(basename $(notdir $x))))
OBJ_RULES = $(call OBJ_RULES1,$1,$2,$3,$4,$5,$(patsubst ,R,$6))

# code for resetting build targets like EXE,LIB,... and target-specific variables like EXE_SRC,LIB_INCLUDE,...
# KLIBS:=
# EXE_DEFINES:=
RESET_TRG_VARS := $(subst $(space),,$(foreach x,$(BLD_TARGETS) $(foreach t,$(BLD_TARGETS),$(addprefix $t_,$(TRG_VARS))),$(newline)$x:=))

# generate target name suffix for DLL,EXE,DRV
# $1 - DLL,EXE,DRV...
# $2 - target variant S,P,D,... but not R or <empty>
DLL_SUFFIX_GEN ?= $(call tolower,$2)

# determine target name suffix for DLL,EXE,DRV
# no suffix if only one variant is built or building R-variant
# $1 - DLL,EXE,DRV...
# $2 - target variant R,S,<empty>
# $3 - variants list, by default $(wordlist 2,999999,$($1))
DLL_VAR_SUFFIX ?= $(if $(filter-out R,$2),$(if $(word \
  2,$(filter R $(VARIANTS_FILTER),$(if $3,$3,$(wordlist 2,999999,$($1))))),$(DLL_SUFFIX_GEN)))

# make target filename
# $1 - EXE,LIB,...
# $2 - target variant R,P,D,S,<empty>
# $3 - variants list, by default $(wordlist 2,999999,$($1))
FORM_TRG = $(if \
  $(filter EXE,$1),$(addprefix $(BIN_DIR)/,$(addsuffix $(DLL_VAR_SUFFIX)$(EXE_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter LIB,$1),$(addprefix $(LIB_DIR)/$(LIB_PREFIX),$(addsuffix $(call LIB_VAR_SUFFIX,$2)$(LIB_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter DLL,$1),$(addprefix $(DLL_DIR)/$(DLL_PREFIX),$(addsuffix $(DLL_VAR_SUFFIX)$(DLL_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter KLIB,$1),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(addsuffix $(call LIB_VAR_SUFFIX,$2)$(KLIB_SUFFIX),$(GET_TARGET_NAME))),$(if \
  $(filter DRV,$1),$(addprefix $(BIN_DIR)/$(DRV_PREFIX),$(addsuffix $(DLL_VAR_SUFFIX)$(DRV_SUFFIX),$(GET_TARGET_NAME))))))))

# example how to make target filenames for all variants specified for the target
# $1 - EXE,LIB,DLL,...
# $(foreach v,$(call GET_VARIANTS,$1),$(call FORM_TRG,$1,$v))

# subst $(space) with space character in defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES = $(subst $$(space),$(space),$1)

# helper macro for target makefiles to pass string define value to C-compiler
# may be already defined by $(MTOP)/$(OS)/c.mk
STRING_DEFINE ?= "$(subst $(space),$$$$(space),$(subst ",\",$1))"

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# note: do not touch $(SYSINCLUDE) - it may contain paths with spaces,
# note: $(SYSINCLUDE) paths are generally filtered-out while .d dependency file generation
# $1 - EXE,DLL,LIB,...
TRG_INCLUDE = $(call FIXPATH,$($1_INCLUDE) $(INCLUDE) $(CMNINCLUDE)) $(SYSINCLUDE)

# make list of sources for the target $1 - EXE,DLL,LIB,...
SOURCES = $(SRC) $($1_SRC) $(WITH_PCH) $($1_WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
# $1 - EXE,DLL,LIB,...
TRG_SRC = $(call FIXPATH,$(SOURCES))

# make absolute paths for $(TRG_SDEPS) - add $(VPREFIX) to relative paths, then normalize paths
# $1 - EXE,DLL,LIB,...
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS) $($1_SDEPS))

# objects and auto-deps to build for the target
# $1 - sources to compile
# NOTE: not all $(OBJS) may be built from the $(SRC) - some objects may be built from generated sources
OBJS = $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# VARIANT_LIB_MAP/VARIANT_IMP_MAP - functions that defines which variant of
#  static/dynamic library to link with EXE or DLL, defined in $(MTOP)/$(OS)/c.mk
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l/$d - dependent static/dynamic library name

# get suffix of dependent LIB
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l - dependent static library name
DEP_LIB_SUFFIX = $(call LIB_VAR_SUFFIX,$(VARIANT_LIB_MAP))

# get suffix of dependent DLL
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $d - dependent dynamic library name
DEP_IMP_SUFFIX = $(call LIB_VAR_SUFFIX,$(VARIANT_IMP_MAP))

# make file names of dependent libs
# $1 - EXE,DLL
# $2 - R,P,S,<empty>
# $3 - names of dependent libs
MAKE_DEP_LIBS = $(foreach l,$3,$(LIB_PREFIX)$l$(DEP_LIB_SUFFIX)$(LIB_SUFFIX))
MAKE_DEP_IMPS = $(foreach d,$3,$(IMP_PREFIX)$d$(DEP_IMP_SUFFIX)$(IMP_SUFFIX))

# static libraries target depends on
# $1 - EXE,DLL
# $2 - R,P,S,<empty>
TRG_LIBS = $(LIBS) $($1_LIBS)
DEP_LIBS = $(addprefix $(LIB_DIR)/,$(call MAKE_DEP_LIBS,$1,$2,$(TRG_LIBS)))

# dynamic libraries target depends on
# assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(IMP_DIR) and DLL itself in $(DLL_DIR)
# $1 - EXE,DLL
# $2 - P,R,S,<empty>
TRG_DLLS = $(DLLS) $($1_DLLS)
DEP_IMPS = $(addprefix $(IMP_DIR)/,$(call MAKE_DEP_IMPS,$1,$2,$(TRG_DLLS)))

# $1 - EXE,DLL,...
# $2 - $(call FORM_TRG,$1,$v)
# $3 - $(call TRG_SRC,$1)
# $4 - $(call TRG_SDEPS,$1)
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P,S,...
TRG_RULES2 = $(call $1_TEMPLATE,$2,$3,$4,$5,$(addprefix $5/,$(call OBJS,$3)))

# $1 - EXE,DLL,...
# $2 - $(call GET_VARIANTS,$1)
# $3 - $(call TRG_SRC,$1)
# $4 - $(call TRG_SDEPS,$1)
TRG_RULES1 = $(foreach v,$2,$(newline)$(call TRG_RULES2,$1,$(call FORM_TRG,$1,$v),$3,$4,$(call FORM_OBJ_DIR,$1,$v)))

# expand target rules template $1_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - EXE,DLL,...
TRG_RULES = $(if $($1),$(call TRG_RULES1,$1,$(call GET_VARIANTS,$1),$(TRG_SRC),$(TRG_SDEPS)))

# how to build executable, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,EXE,$v)
# $2 - sources:     $(call TRG_SRC,EXE)
# $3 - sdeps:       $(call TRG_SDEPS,EXE)
# $4 - objdir:      $(call FORM_OBJ_DIR,EXE,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,P,S,...
define EXE_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,EXE,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,EXE,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,EXE,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(call TRG_LIBS,EXE)
$1: DLLS       := $(call TRG_DLLS,EXE)
$1: INCLUDE    := $(call TRG_INCLUDE,EXE)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES) $(EXE_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(EXE_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(EXE_CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(EXE_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(EXE_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(EXE_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(EXE_SYSLIBPATH)
$1: $(call DEP_LIBS,EXE,$v) $(call DEP_IMPS,EXE,$v) $5
	$$(call EXE_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build dynamic (shared) library, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,DLL,$v)
# $2 - sources:     $(call TRG_SRC,DLL)
# $3 - sdeps:       $(call TRG_SDEPS,DLL)
# $4 - objdir:      $(call FORM_OBJ_DIR,DLL,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,S
define DLL_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,DLL,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,DLL,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,DLL,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(call TRG_LIBS,DLL)
$1: DLLS       := $(call TRG_DLLS,DLL)
$1: INCLUDE    := $(call TRG_INCLUDE,DLL)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES) $(DLL_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DLL_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(DLL_CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(DLL_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DLL_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(DLL_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(DLL_SYSLIBPATH)
$1: $(call DEP_LIBS,DLL,$v) $(call DEP_IMPS,DLL,$v) $5
	$$(call DLL_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build static library for EXE/DLL or static library for DLL only, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,LIB,$v)
# $2 - sources:     $(call TRG_SRC,LIB)
# $3 - sdeps:       $(call TRG_SDEPS,LIB)
# $4 - objdir:      $(call FORM_OBJ_DIR,LIB,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,P,D,S
define LIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,LIB,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,LIB,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,LIB,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(call TRG_INCLUDE,LIB)
$1: DEFINES    := $(CMNDEFINES) $(APPDEFS) $(DEFINES) $(LIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(LIB_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(LIB_CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(LIB_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(LIB_LDFLAGS)
$1: $5
	$$(call LIB_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build kernel-mode static library for driver, used by $(TRG_RULES)
# $1 - target file: $(call FORM_TRG,KLIB,$v)
# $2 - sources:     $(call TRG_SRC,KLIB)
# $3 - sdeps:       $(call TRG_SDEPS,KLIB)
# $4 - objdir:      $(call FORM_OBJ_DIR,KLIB,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R
define KLIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,KLIB,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,KLIB,CXX,$(filter %.cpp,$2),$3,$4,$v)
$(call OBJ_RULES,KLIB,ASM,$(filter %.asm,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(call TRG_INCLUDE,KLIB)
$1: DEFINES    := $(CMNDEFINES) $(KRNDEFS) $(DEFINES) $(KLIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(KLIB_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(KLIB_CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(KLIB_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(KLIB_LDFLAGS)
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
# 3) prepend values of $(OS)-dependent variables, then clear them
#   note: eval _before_ using any of $(BLD_VARS)
# 4) if there are rules to generate sources - eval them before defining objects for the target
# 5) evaluate $(OS)-specific default targets before defining common default targets
#   to allow additional $(OS)-specific dependencies on targets
# 6) check and evaluate rules
# 7) evaluate $(DEF_TAIL_CODE)
define DEFINE_C_TARGETS_EVAL
$(if $(MDEBUG),$(eval $(DEBUG_C_TARGETS)))
$(eval $(call OSVAR,USE)$(if $(MDEBUG),$$(if $$(USE),$$(info \
  using: $$(USE))))$(newline)include $$(addprefix $(PROJECT_USE_DIR)/,$$(USE:=.mk)))
$(eval $(OSVARS))
$(eval $(GENERATE_SRC_RULES))
$(eval $(OS_DEFINE_TARGETS))
$(eval $(CHECK_C_RULES)$(foreach t,EXE DLL LIB KLIB,$(call TRG_RULES,$t)))
$(DEF_TAIL_CODE_EVAL)
endef

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define PREPARE_C_VARS
$(RESET_TRG_VARS)
$(RESET_OS_VARS)
MODVER      := $(PRODUCT_VER)
PCH         :=
WITH_PCH    :=
USE         :=
SRC         :=
SDEPS       :=
CMNDEFINES  := $(PREDEFINES)
DEFINES     :=
CMNINCLUDE  := $(DEFINCLUDE)
INCLUDE     :=
CFLAGS      :=
CXXFLAGS    :=
ASMFLAGS    :=
LDFLAGS     :=
SYSLIBS     :=
SYSLIBPATH  :=
SYSINCLUDE  :=
DLLS        :=
LIBS        :=
KLIBS       :=
DEFINE_TARGETS_EVAL_NAME := DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_C_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
# NOTE: expanded by $(MTOP)/c.mk
MAKE_C_EVAL = $(eval $(PREPARE_C_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,BLD_TARGETS TRG_VARS BLD_VARS LIB_VAR_SUFFIX \
  DEFINCLUDE PREDEFINES APPDEFS KRNDEFS PRODUCT_VER DEBUG_C_TARGETS \
  OSVARIANT OSTYPE OSVAR OSVARS OBJ_RULE OBJ_RULES1 OBJ_RULES \
  RESET_TRG_VARS DLL_SUFFIX_GEN DLL_VAR_SUFFIX FORM_TRG SUBST_DEFINES STRING_DEFINE \
  TRG_INCLUDE SOURCES TRG_SRC TRG_SDEPS OBJS DEP_LIB_SUFFIX DEP_IMP_SUFFIX \
  MAKE_DEP_LIBS MAKE_DEP_IMPS TRG_LIBS DEP_LIBS TRG_DLLS DEP_IMPS \
  TRG_RULES2 TRG_RULES1 TRG_RULES EXE_TEMPLATE LIB_TEMPLATE DLL_TEMPLATE KLIB_TEMPLATE \
  CC_COLOR CXX_COLOR AR_COLOR LD_COLOR XLD_COLOR ASM_COLOR \
  KCC_COLOR KLD_COLOR TCC_COLOR TCXX_COLOR TLD_COLOR TAR_COLOR CHECK_C_RULES PROJECT_USE_DIR \
  OS_DEFINE_TARGETS DEFINE_C_TARGETS_EVAL PREPARE_C_VARS RESET_OS_VARS MAKE_C_EVAL)
