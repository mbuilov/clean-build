ifndef MAKE_C_INCLUDED

# this file normally included at beginning of target makefile
# used for building C/C++ libs, dlls, executables
MAKE_C_INCLUDED := 1

# separate group of defines for each build target type (EXE,LIB,DLL,...)
# - to allow to build many targets (for example LIB,EXE and DLL) specified in one makefile

# use target-specific variables
# NOTE: all targets defined at the same time share the same values of common vars LIBS,DLLS,CFLAGS,...
# but also may have target-specific variable value, for example EXE_INCLUDE,LIB_CFLAGS,...

# build targets:
# NOTE: all variants have the same C-preprocessor defines, but are compiled with different C-compiler flags
# EXE  - executable, variants:      R,P,S
# LIB  - static library, variants:  R,P,D,S (P-version - library only for EXE, D-version - library only for DLL)
# DLL  - dynamic library, variants: R,S
# if variant is not specified, default variant R will be built, else - only specified variants (add R to build also default variant)

# what we may build by including $(MTOP)/make_c.mk (for ex. LIB := my_lib)
BLD_TARGETS := EXE LIB DLL KLIB DRV

# NOTE: after target name may be specified one or more build target variants (for ex. EXE := my_exe R S):
# R - default build variant:
#  EXE  - position-dependent code   (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
#  LIB  - position-dependent code   (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
#  DLL  - position-independent code (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
# P - position-independent code in executables      (for EXE and LIB) (only UNIX)
# D - position-independent code in shared libraries (only for LIB)    (only UNIX)
# S - statically linked multithreaded libc          (for all targets) (only WINDOWS)

# list of variables that may be target-dependent - each target may have own value of next variables (EXE_PCH, LIB_SRC and so on)
TRG_VARS := PCH WITH_PCH SRC SDEPS DEFINES INCLUDE CFLAGS CXXFLAGS \
  ASMFLAGS LDFLAGS SYSLIBS SYSLIBPATH SYSINCLUDE DLLS LIBS RES RPATH MAP DEF

# list of all variables for the target, add variables that may not be target-dependent
BLD_VARS := KLIBS CMNINCLUDE CLEAN $(TRG_VARS)

# determine prefix for static LIB and for implementation-library of DLL
# $1 - target variant R,P,D,S,<empty>
VARIANT_LIB_SUFFIX = $(if $(filter-out R,$1),_$1)
# NOTE: for UNIX    IMP-lib and DLL-lib is the same one file, so only one default variant R of DLL is allowed for UNIX
# NOTE: for WINDOWS IMP-lib may have different name over than DLL, so it's allowed only one (non-)default variant of DLL
VARIANT_IMP_SUFFIX = $(if $(filter-out R,$1),_$1)

# $(TOP)/make/make_features.mk included by $(MTOP)/make_defs.mk, if exists, should define something like:
#
# 1) common include path for all targets, added at end of compiler's include paths list, for example:
#  DEFINCLUDE = $(TOP)/include
#  note: $(DEFINCLUDE) may be recursive, it's value may be calculated based on $(TOP)-related path to $(CURRENT_MAKEFILE)
#  note: target makefile may avoid using include paths from $(DEFINCLUDE) by resetting $(CMNINCLUDE) value
#
# 2) predefined macros for all targets, for example:
#  PREDEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) \
#               $(if $(filter sparc% mips% ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
#               $(if $(filter arm% sparc% mips% ppc%,$(CPU)),ADDRESS_NEEDALIGN)
#  note: $(PREDEFINES) may be recursive, it's value may be calculated based on $(TOP)-related path to $(CURRENT_MAKEFILE)
#  note: target makefile may avoid using macros from $(PREDEFINES) by resetting $(DEFINES) value
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

# set MAKE_DEFS_INCLUDED_BY value - to avoid execution of $(DEF_HEAD_CODE) by included make_defs.mk,
# - $(DEF_HEAD_CODE) will be evaluated at end of this file
MAKE_DEFS_INCLUDED_BY := make_c.mk
include $(MTOP)/make_defs.mk
include $(MTOP)/$(OS)/make_c.mk

# add defines from $(MTOP)/$(OS)/make_c.mk
PREDEFINES += $(OS_PREDEFINES)
APPDEFS    += $(OS_APPDEFS)
KRNDEFS    += $(OS_KRNDEFS)

# define code to print debug info about built targets
# note: GET_DEBUG_TARGETS - defined in $(MTOP)/make_defs.mk
# note: FORM_TRG will be defined below, VARIANTS_FILTER - was defined in $(MTOP)/$(OS)/make_c.mk
DEBUG_C_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_TARGETS),FORM_TRG,VARIANTS_FILTER)

# template to prepend value of $(OS)-dependent variables to variable $1, then clear $(OS)-dependent variables
# NOTE: preferred values must be first: $1_$(OSVARIANT) is preferred over $1_$(OS) and so on
# - in some cases we get just the first value (for TRG_MAP or TRG_DEF for example)
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
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - source, $4 - deps, $5 - objdir, $6 - variant (non-empty!), $7 - $(basename $(notdir $3))
# if $(NO_DEPS) is empty, then try to include dependency file .d (ignore if file does not exist)
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
define OBJ_RULE
$(empty)
$5/$7$(OBJ_SUFFIX): $3 $(call EXTRACT_DEPS,$3,$4) | $5 $$(ORDER_DEPS)
	$$(call $1_$6_$2,$$@,$$<)
ifeq ($(NO_DEPS),)
-include $5/$7.d
endif
CLEAN += $5/$7.d
endef

# rule that defines how to build objects from sources
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - sources to compile, $4 - deps, $5 - objdir, $6 - variant (if empty, then R)
OBJ_RULES1 = $(foreach x,$3,$(call OBJ_RULE,$1,$2,$x,$4,$5,$6,$(basename $(notdir $x))))
OBJ_RULES = $(call OBJ_RULES1,$1,$2,$3,$4,$5,$(patsubst ,R,$6))

# code for resetting build targets like EXE,LIB,... and target-specific variables like EXE_SRC,LIB_INCLUDE,...
# KLIBS:=
# EXE_DEFINES:=
RESET_TRG_VARS := $(subst $(space),,$(foreach x,$(BLD_TARGETS) $(foreach t,$(BLD_TARGETS),$(addprefix $t_,$(TRG_VARS))),$(newline)$x:=))

# make target filename, $1 - EXE,LIB,... $2 - target variant R,P,D,S,<empty>
# NOTE: only one variant of EXE may be built (EXE-name is invariant)
# NOTE: only one variant of DLL may be built (DLL-name is invariant)
# NOTE: there is no variants supported for KLIB and DRV, so don't call $(GET_TARGET_NAME)
FORM_TRG = $(if \
           $(filter EXE,$1),$(BIN_DIR)/$(GET_TARGET_NAME)$(EXE_SUFFIX),$(if \
           $(filter LIB,$1),$(LIB_DIR)/$(LIB_PREFIX)$(GET_TARGET_NAME)$(call VARIANT_LIB_SUFFIX,$2)$(LIB_SUFFIX),$(if \
           $(filter DLL,$1),$(DLL_DIR)/$(DLL_PREFIX)$(GET_TARGET_NAME)$(DLL_SUFFIX),$(if \
           $(filter KLIB,$1),$(LIB_DIR)/$(KLIB_PREFIX)$($1)$(KLIB_SUFFIX),$(if \
           $(filter DRV,$1),$(BIN_DIR)/$(DRV_PREFIX)$($1)$(DRV_SUFFIX))))))

# example how to make target filenames for all variants specified for the target
# $1 - EXE,LIB,DLL,...
# $(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call FORM_TRG,$1,$v))

# subst $(space) with space character in defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES = $(subst $$(space),$(space),$1)

# helper macro for target makefiles to pass string define value to C-compiler
# may be already defined by $(MTOP)/$(OS)/make_c.mk
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

# make absolute paths for $(TRG_DEPS) - add $(VPREFIX) to relative paths, then normalize paths
TRG_DEPS = $(subst | ,|,$(call FIXPATH,$(subst |,| ,$(SDEPS) $($1_SDEPS))))

# make absolute path to map/def file - add $(VPREFIX) if path is relative, then normalize path
# $1 - DLL
# use $(firstword) - to prefer $v_$(OSVARIANT) over $v_$(OS), $v_$(OS) over $v_$(OSTYPE) and $v_$(OSTYPE) over $v
TRG_MAP = $(call FIXPATH,$(firstword $($1_MAP) $(MAP)))
TRG_DEF = $(call FIXPATH,$(firstword $($1_DEF) $(DEF)))

# objects and auto-deps to build for the target
# $1 - sources to compile
# NOTE: not all $(OBJS) may be built from the $(SRC) - some objects may be built from generated sources
OBJS = $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# get suffix of dependent LIB,
# arguments: $1 - target EXE,DLL, $2 - variant of target EXE or DLL, $l - dependent static library name
# VARIANT_LIB_MAP - function that defines which variant of static library LIB to link with EXE or DLL
#  arguments: $1 - target EXE,DLL, $2 - variant of target EXE or DLL, $l - dependent static library name
#  returns:   variant of dependent LIB
DEP_LIB_SUFFIX = $(call VARIANT_LIB_SUFFIX,$(VARIANT_LIB_MAP))

# get suffix of dependent DLL,
# arguments: $1 - target EXE,DLL, $2 - variant of target EXE or DLL, $d - dependent dynamic library name
# VARIANT_IMP_MAP - function that defines which variant of dynamic library DLL to link with EXE or DLL
#  arguments: $1 - target EXE,DLL, $2 - variant of target EXE or DLL, $d - dependent dynamic library name
#  returns:   variant of dependent DLL
DEP_IMP_SUFFIX = $(call VARIANT_IMP_SUFFIX,$(VARIANT_IMP_MAP))

# make file names of dependent libs
# $1 - EXE,DLL $2 - R,P,S,<empty> $3 - names of dependent libs
MAKE_DEP_LIBS = $(foreach l,$3,$(LIB_PREFIX)$l$(DEP_LIB_SUFFIX)$(LIB_SUFFIX))
MAKE_DEP_IMPS = $(foreach d,$3,$(IMP_PREFIX)$d$(DEP_IMP_SUFFIX)$(IMP_SUFFIX))

# static libraries target depends on
# $1 - EXE,DLL $2 - R,P,S,<empty>
TRG_LIBS = $(LIBS) $($1_LIBS)
DEP_LIBS = $(addprefix $(LIB_DIR)/,$(call MAKE_DEP_LIBS,$1,$2,$(TRG_LIBS)))

# dynamic libraries target depends on
# assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(IMP_DIR) and DLL itself in $(DLL_DIR)
# $1 - EXE,DLL $2 - P,R,S,<empty>
TRG_DLLS = $(DLLS) $($1_DLLS)
DEP_IMPS = $(addprefix $(IMP_DIR)/,$(call MAKE_DEP_IMPS,$1,$2,$(TRG_DLLS)))

# $1 - target file: $(call FORM_TRG,EXE,$v)
# $2 - sources:     $(call TRG_SRC,EXE)
# $3 - deps:        $(call TRG_DEPS,EXE)
# $4 - objdir:      $(call FORM_OBJ_DIR,EXE,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,P,S,...
define EXE_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,EXE,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,EXE,CXX,$(filter %.cpp,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(call TRG_LIBS,EXE)
$1: DLLS       := $(call TRG_DLLS,EXE)
$1: INCLUDE    := $(call TRG_INCLUDE,EXE)
$1: DEFINES    := $(APPDEFS) $(DEFINES) $(EXE_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(EXE_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(EXE_CXXFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(EXE_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(EXE_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(EXE_SYSLIBPATH)
$1: RPATH      := $(RPATH) $(EXE_RPATH)
$1: $(call DEP_LIBS,EXE,$v) $(call DEP_IMPS,EXE,$v) $5
	$$(call EXE_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
endef

# how to build executable
EXE_RULES1 = $(call EXE_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
EXE_RULES = $(if $(EXE),$(foreach v,$(call GET_VARIANTS,EXE,VARIANTS_FILTER),$(newline)$(call \
  EXE_RULES1,$(call FORM_TRG,EXE,$v),$(call TRG_SRC,EXE),$(call TRG_DEPS,EXE),$(call FORM_OBJ_DIR,EXE,$v))))

# $1 - target file: $(call FORM_TRG,LIB,$v)
# $2 - sources:     $(call TRG_SRC,LIB)
# $3 - deps:        $(call TRG_DEPS,LIB)
# $4 - objdir:      $(call FORM_OBJ_DIR,LIB,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,P,D,S,<empty>
define LIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,LIB,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,LIB,CXX,$(filter %.cpp,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(call TRG_INCLUDE,LIB)
$1: DEFINES    := $(APPDEFS) $(DEFINES) $(LIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(LIB_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(LIB_CXXFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(LIB_LDFLAGS)
$1: $5
	$$(call LIB_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
endef

# how to build static library for EXE/DLL or static library for DLL only
LIB_RULES1 = $(call LIB_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
LIB_RULES = $(if $(LIB),$(foreach v,$(call GET_VARIANTS,LIB,VARIANTS_FILTER),$(newline)$(call \
  LIB_RULES1,$(call FORM_TRG,LIB,$v),$(call TRG_SRC,LIB),$(call TRG_DEPS,LIB),$(call FORM_OBJ_DIR,LIB,$v))))

# $1 - target file: $(call FORM_TRG,DLL,$v)
# $2 - sources:     $(call TRG_SRC,DLL)
# $3 - deps:        $(call TRG_DEPS,DLL)
# $4 - objdir:      $(call FORM_OBJ_DIR,DLL,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,S,<empty>
define DLL_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,DLL,CC,$(filter %.c,$2),$3,$4,$v)
$(call OBJ_RULES,DLL,CXX,$(filter %.cpp,$2),$3,$4,$v)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: LIBS       := $(call TRG_LIBS,DLL)
$1: DLLS       := $(call TRG_DLLS,DLL)
$1: INCLUDE    := $(call TRG_INCLUDE,DLL)
$1: DEFINES    := $(APPDEFS) $(DEFINES) $(DLL_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DLL_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(DLL_CXXFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DLL_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS) $(DLL_SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH) $(DLL_SYSLIBPATH)
$1: RPATH      := $(RPATH) $(DLL_RPATH)
$1: MAP        := $(call TRG_MAP,DLL)
$1: DEF        := $(call TRG_DEF,DLL)
$1: $(call DEP_LIBS,DLL,$v) $(call DEP_IMPS,DLL,$v) $5
	$$(call DLL_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
endef

# how to build dynamic (shared) library
DLL_RULES1 = $(call DLL_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DLL_RULES = $(if $(DLL),$(foreach v,$(call GET_VARIANTS,DLL,VARIANTS_FILTER),$(newline)$(call \
  DLL_RULES1,$(call FORM_TRG,DLL,$v),$(call TRG_SRC,DLL),$(call TRG_DEPS,DLL),$(call FORM_OBJ_DIR,DLL,$v))))

# $1 - target file: $(call FORM_TRG,KLIB)
# $2 - sources:     $(call TRG_SRC,KLIB)
# $3 - deps:        $(call TRG_DEPS,KLIB)
# $4 - objdir:      $(call FORM_OBJ_DIR,KLIB)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
define KLIB_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call OBJ_RULES,KLIB,CC,$(filter %.c,$2),$3,$4)
$(call OBJ_RULES,KLIB,ASM,$(filter %.asm,$2),$3,$4)
$1: INCLUDE    := $(call TRG_INCLUDE,KLIB)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(KLIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(KLIB_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(KLIB_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(KLIB_LDFLAGS)
$1: $5
	$$(call KLIB_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
endef

# how to build kernel-mode static library for driver
KLIB_RULES1 = $(call KLIB_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
KLIB_RULES = $(if $(KLIB),$(call KLIB_RULES1,$(call FORM_TRG,KLIB),$(call \
  TRG_SRC,KLIB),$(call TRG_DEPS,KLIB),$(call FORM_OBJ_DIR,KLIB)))

# helper macro: convert list of sources $2 to list of objects for the target $1
# $1 - EXE,LIB,DLL,...
# $2 - objects names
FORM_TRG_OBJS = $(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(addprefix $(call FORM_OBJ_DIR,$1,$v)/,$2))

# helper macro: convert list of sources $1 to list of objects for defined targets (EXE,LIB,DLL,...)
FORM_OBJS = $(foreach t,$(BLD_TARGETS),$(if $($t),$(call FORM_TRG_OBJS,$t,$(OBJS))))

# check that LIBS specified only when building EXE or DLL,
# check that KLIBS specified only when building DRV
ifdef MCHECK
CHECK_C_RULES = $(if \
  $(CB_TOOL_MODE),$(if $(KLIB)$(DRV),$(error cannot build drivers in tool mode))) $(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL)) $(if \
  $(if $(DRV),,$(KLIBS)),$(warning KLIBS = $(KLIBS) is used only when building DRV))
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
  using: $$(USE))))$(newline)include $$(addsuffix .mk,$$(addprefix $(TOP)/make/$(OS)/use/,$$(USE))))
$(eval $(OSVARS))
$(eval $(GENERATE_SRC_RULES))
$(eval $(OS_DEFINE_TARGETS))
$(eval $(CHECK_C_RULES)$(EXE_RULES)$(LIB_RULES)$(DLL_RULES)$(KLIB_RULES))
$(DEF_TAIL_CODE_EVAL)
endef

# code to be called at beginning of target makefile
define PREPARE_C_VARS
$(RESET_TRG_VARS)
PCH         :=
WITH_PCH    :=
USE         :=
SRC         :=
SDEPS       :=
DEFINES     := $(PREDEFINES)
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
RES         :=
RPATH       := $(INST_RPATH)
MAP         :=
DEF         :=
KLIBS       :=
DEFINE_TARGETS_EVAL_NAME := DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME  := MAKE_CONTINUE_C_EVAL
endef

# reset build targets, target-specific variables and variables modifiable in target makefiles
# then define bin/lib/obj/... dirs
MAKE_CONTINUE_C_EVAL = $(eval $(PREPARE_C_VARS)$(DEF_HEAD_CODE))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,MAKE_C_INCLUDED BLD_TARGETS \
  TRG_VARS BLD_VARS VARIANT_LIB_SUFFIX VARIANT_IMP_SUFFIX DEBUG_C_TARGETS \
  OSVARIANT OSTYPE OSVAR OSVARS OBJ_RULE OBJ_RULES1 OBJ_RULES \
  RESET_TRG_VARS FORM_TRG SUBST_DEFINES STRING_DEFINE \
  TRG_INCLUDE SOURCES TRG_SRC TRG_DEPS TRG_MAP TRG_DEF OBJS DEP_LIB_SUFFIX DEP_IMP_SUFFIX \
  MAKE_DEP_LIBS MAKE_DEP_IMPS TRG_LIBS DEP_LIBS TRG_DLLS DEP_IMPS \
  EXE_TEMPLATE EXE_RULES1 EXE_RULES LIB_TEMPLATE LIB_RULES1 LIB_RULES \
  DLL_TEMPLATE DLL_RULES1 DLL_RULES KLIB_TEMPLATE KLIB_RULES1 KLIB_RULES \
  FORM_TRG_OBJS FORM_OBJS CHECK_C_RULES \
  OS_DEFINE_TARGETS DEFINE_C_TARGETS_EVAL PREPARE_C_VARS MAKE_CONTINUE_C_EVAL)

endif # MAKE_C_INCLUDED

# evaluate head code like in $(MAKE_CONTINUE)
$(MAKE_CONTINUE_C_EVAL)
