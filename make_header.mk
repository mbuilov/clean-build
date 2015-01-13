ifndef MAKE_HEADER_INCLUDED

# this file normally included at beginning of target Makefile
# used for building C/C++ libs, dlls, executables
MAKE_HEADER_INCLUDED := 1

# separate group of defines for each build target type (EXE,LIB,DLL,...)
# - to allow to build many targets (for example LIB,EXE and DLL) specified in one makefile

# use target-specific variables
# NOTE: all targets defined at the same time share the same values of common vars LIBS,DLLS,CFLAGS,...
# but also may have target-specific variable value, for example EXE_INCLUDE,LIB_CFLAGS,...

# build targets:
# NOTE: all variants have the same C-preprocessor defines, but are compiled with different C-compiler flags
# EXE  - executable, variants:              R,P,S
# LIB  - static library, variants:          R,P,D,S (P-version - library only for EXE, D-version - library only for DLL)
# DLL  - dynamic library, variants:         R,S
# if variant is not specified, default variant R will be built, else - only specified variants (add R to build also default variant)

# build target variants:
# R - default build variant:
#  EXE  - position-dependent code   (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
#  LIB  - position-dependent code   (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
#  DLL  - position-independent code (UNIX), dynamicaly linked multi-threaded libc (WINDOWS)
# P - position-independent code in executables      (for EXE and LIB) (only UNIX)
# D - position-independent code in shared libraries (only for LIB)    (only UNIX)
# S - statically linked multithreaded libc          (for all targets) (only WINDOWS)
BLD_TARGETS := EXE LIB DLL KLIB DRV

# list of variables that may be target-dependent - each target may have own value of next variables (EXE_PCH, LIB_USE and so on)
TRG_VARS := PCH WITH_PCH USE SRC SDEPS DEFINES INCLUDE CFLAGS CXXFLAGS ASMFLAGS LDFLAGS SYSLIBS SYSLIBPATH SYSINCLUDE DLLS LIBS RES RPATH MAP DEF

# list of all variables for the target
BLD_VARS := $(TRG_VARS) KLIBS CMNINCLUDE CLEAN

# $1 - target variant R,P,D,S,<empty>
VARIANT_LIB_PREFIX = $(if $(filter-out R,$1),$1_)
# NOTE: for UNIX IMP-lib and DLL-lib are the same one file, so don't add prefix for R-variant of DEP_IMP
# NOTE: and so no variants for DLL allowed for UNIX
VARIANT_IMP_PREFIX = $(if $(filter-out R,$1),$1_)

# $(PROJECT_FEATURES) makefile included by make_defs.mk must define something like:
# DEFINCLUDE = $(TOP)/include
# PREDEFINES = $(if $(filter %D,$(TARGET)),_DEBUG) TARGET_$(patsubst %D,%,$(TARGET)) \
               $(if $(filter sparc% mips% ppc%,$(CPU)),B_ENDIAN,L_ENDIAN) \
               $(if $(filter arm% sparc% mips% ppc%,$(CPU)),ADDRESS_NEEDALIGN)
# APPDEFS =
# KRNDEFS =

# avoid execution of $(DEF_HEAD_CODE) by make_defs.mk - $(DEF_HEAD_CODE) will be evaluated at end of this file
MAKE_DEFS_INCLUDED_BY := make_header.mk
include $(MTOP)/make_defs.mk
include $(MTOP)/$(OS)/make_header.mk

# $(BLD_TARGETS) is now defined, define $(DEBUG_TARGETS) code
# FORM_TRG and VARIANTS_FILTER are defined later
DEBUG_TARGETS := $(call GET_DEBUG_TARGETS,$(BLD_TARGETS),FORM_TRG,VARIANTS_FILTER)

# template to prepend value of $(OS)-dependent variables to variable $r, then clear $(OS)-dependent variables
# NOTE: preferred values must be first: $r_$(OS) is preferred over $r_$(OSVARIANT) and so on
define OSVAR
$r:=$$(strip $$($r_$(OS)) $$($r_$(OSVARIANT)) $$($r_$(OSTYPE)) $$($r))
$r_$(OS):=
$r_$(OSVARIANT):=
$r_$(OSTYPE):=
$(empty)
endef

# code for adding OS-specific values to variables, then clearing OS-specific values
OSVARS := $(foreach r,$(BLD_VARS) $(foreach t,$(BLD_TARGETS),$(addprefix $t_,$(TRG_VARS))),$(OSVAR))

# defines target kernel sources to build
KSYSTEM ?= $(OS)

# $1 - source file, $2 - $(SDEPS) - list of pairs: <source file> <dependency1>|<dependency2>|...
EXTRACT_SRC_DEPS = $(if $2,$(if $(filter $1,$(firstword $2)),$(subst |, ,$(word 2,$2)) )$(call EXTRACT_SRC_DEPS,$1,$(wordlist 3,999999,$2)))

# rule that defines how to build object from source
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - source to compile, $4 - deps, $5 - variant (non-empty!), $6 - objdir
define OBJ_RULE
$(empty)
$6/$(basename $(notdir $3))$(OBJ_SUFFIX): $3 $(call EXTRACT_SRC_DEPS,$3,$4) $(CURRENT_DEPS) | $6
	$$(call $1_$5_$2,$$@,$$<)
endef

# rule that defines how to build objects from sources
# $1 - EXE,LIB,... $2 - CXX,CC,ASM,... $3 - sources to compile, $4 - deps, $5 - variant (if empty, then R)
OBJ_RULES2 = $(foreach x,$3,$(call OBJ_RULE,$1,$2,$x,$4,$5,$6))
OBJ_RULES1 = $(call OBJ_RULES2,$1,$2,$3,$4,$5,$(call FORM_OBJ_DIR,$1,$5))
OBJ_RULES = $(call OBJ_RULES1,$1,$2,$3,$4,$(patsubst ,R,$5))

# code for resetting build targets like EXE,LIB,... and target-specific variables like EXE_SRC,LIB_INCLUDE,...
RESET_TRG_VARS := $(subst $(space),,$(foreach x,$(BLD_TARGETS) $(foreach t,$(BLD_TARGETS),$(addprefix $t_,$(TRG_VARS))),$(newline)$x:=))

# make target filename, $1 - EXE,LIB,... $2 - target variant R,P,D,S,<empty>
# NOTE: only one variant of EXE may be built
# NOTE: only one variant of DLL may be built
# NOTE: there is no variants for KLIB and DRV
FORM_TRG = $(if \
           $(filter EXE,$1),$(BIN_DIR)/$(GET_TARGET_NAME)$(EXE_SUFFIX),$(if \
           $(filter LIB,$1),$(LIB_DIR)/$(LIB_PREFIX)$(call VARIANT_LIB_PREFIX,$2)$(GET_TARGET_NAME)$(LIB_SUFFIX),$(if \
           $(filter DLL,$1),$(DLL_DIR)/$(DLL_PREFIX)$(GET_TARGET_NAME)$(DLL_SUFFIX),$(if \
           $(filter KLIB,$1),$(LIB_DIR)/$(KLIB_PREFIX)$($1)$(KLIB_SUFFIX),$(if \
           $(filter DRV,$1),$(BIN_DIR)/$(DRV_PREFIX)$($1)$(DRV_SUFFIX))))))

# example how to make target filenames for all variants specified for the target
# $1 - EXE,LIB,DLL,...
# $(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call FORM_TRG,$1,$v))

# subst $(space) with space character in defines passed to C-compiler
SUBST_DEFINES = $(subst $$(space),$(space),$1)
STRING_DEFINE = "$(subst $(space),$$(space),$(subst ",\",$1))"

# add $(VPREFIX) to relative-path includes preserving include order
# note: do not touch $(SYSINCLUDE) - it may contain paths with spaces
# $1 - EXE,DLL,LIB,...
TRG_INCLUDE = $(call FIXPATH,$($1_INCLUDE) $(INCLUDE) $(CMNINCLUDE)) $(SYSINCLUDE)

# add $(VPREFIX) to relative-path sources
# $1 - EXE,DLL,LIB,...
TRG_SRC = $(call FIXPATH,$(SRC) $($1_SRC))
TRG_DEPS = $(subst | ,|,$(call FIXPATH,$(subst |,| ,$(SDEPS) $($1_SDEPS))))

# add $(VPREFIX) to relative-path to map/def file
# $1 - DLL
# use $(firstword) - to prefer $v_$(OS) over $v_$(OSVARIANT), $v_$(OSVARIANT) over $v_$(OSTYPE), $v_$(OSTYPE) over $v
TRG_MAP = $(call FIXPATH,$(firstword $(if $($1_MAP),$($1_MAP),$(MAP))))
TRG_DEF = $(call FIXPATH,$(firstword $(if $($1_DEF),$($1_DEF),$(DEF))))

# objects to build for the target
# NOTE: not all $(OBJS) may be built from the $(SRC) - some objects may be built from generated sources
OBJS = $(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))

# get prefix of dependent LIB,
# arguments: $1 - EXE,DLL, $2 - variant of EXE or DLL
# VARIANT_LIB_MAP - function that defines which variant of static library LIB to link with EXE or DLL
#  arguments: $1 - EXE,DLL, $2 - variant of EXE or DLL
#  returns:   variant of dependent LIB
DEP_LIB_PREFIX = $(call VARIANT_LIB_PREFIX,$(VARIANT_LIB_MAP))

# get prefix of dependent DLL,
# arguments: $1 - EXE,DLL, $2 - variant of EXE or DLL
# VARIANT_IMP_MAP - function that defines which variant of dynamic library DLL to link with EXE or DLL
#  arguments: $1 - EXE,DLL, $2 - variant of EXE or DLL
#  returns:   variant of dependent DLL
DEP_IMP_PREFIX = $(call VARIANT_IMP_PREFIX,$(VARIANT_IMP_MAP))

# static libraries target depends on
# $1 - EXE,DLL $2 - R,P,S,<empty>
TRG_LIBS = $(LIBS) $($1_LIBS)
DEP_LIBS = $(addsuffix $(LIB_SUFFIX),$(addprefix $(LIB_DIR)/$(LIB_PREFIX)$(DEP_LIB_PREFIX),$(TRG_LIBS)))

# dynamic libraries target depends on
# assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(IMP_DIR) and DLL itself in $(DLL_DIR)
# $1 - EXE,DLL $2 - P,R,S,<empty>
TRG_DLLS = $(DLLS) $($1_DLLS)
DEP_IMPS = $(addsuffix $(IMP_SUFFIX),$(addprefix $(IMP_DIR)/$(IMP_PREFIX)$(DEP_IMP_PREFIX),$(TRG_DLLS)))

# $1 - target file: $(call FORM_TRG,EXE,$v)
# $2 - sources:     $(call TRG_SRC,EXE)
# $3 - deps:        $(call TRG_DEPS,EXE)
# $4 - objdir:      $(call FORM_OBJ_DIR,EXE,$v)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# $v - R,P,S,<empty>
define EXE_TEMPLATE
$(call ADD_DIR_RULES,$4)
$(call OBJ_RULES,EXE,CC,$(filter %.c,$2),$3,$v)
$(call OBJ_RULES,EXE,CXX,$(filter %.cpp,$2),$3,$v)
$(call STD_TARGET_VARS,$1)
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
$1: $(call DEP_LIBS,EXE,$v) $(call DEP_IMPS,EXE,$v) $5 $(CURRENT_DEPS) | $(BIN_DIR)
	$$(call EXE_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
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
$(call ADD_DIR_RULES,$4)
$(call OBJ_RULES,LIB,CC,$(filter %.c,$2),$3,$v)
$(call OBJ_RULES,LIB,CXX,$(filter %.cpp,$2),$3,$v)
$(call STD_TARGET_VARS,$1)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: INCLUDE    := $(call TRG_INCLUDE,LIB)
$1: DEFINES    := $(APPDEFS) $(DEFINES) $(LIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(LIB_CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS) $(LIB_CXXFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(LIB_LDFLAGS)
$1: $5 $(CURRENT_DEPS) | $(LIB_DIR)
	$$(call LIB_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
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
$(call ADD_DIR_RULES,$4)
$(call OBJ_RULES,DLL,CC,$(filter %.c,$2),$3,$v)
$(call OBJ_RULES,DLL,CXX,$(filter %.cpp,$2),$3,$v)
$(call STD_TARGET_VARS,$1)
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
$1: $(call DEP_LIBS,DLL,$v) $(call DEP_IMPS,DLL,$v) $5 $(CURRENT_DEPS) | $(sort $(DLL_DIR) $(IMP_DIR))
	$$(call DLL_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
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
$(call ADD_DIR_RULES,$4)
$(call OBJ_RULES,KLIB,CC,$(filter %.c,$2),$3)
$(call OBJ_RULES,KLIB,ASM,$(filter %.asm,$2),$3)
$(call STD_TARGET_VARS,$1)
$1: INCLUDE    := $(call TRG_INCLUDE,KLIB)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(KLIB_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(KLIB_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(KLIB_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(KLIB_LDFLAGS)
$1: $5 $(CURRENT_DEPS) | $(LIB_DIR)
	$$(call KLIB_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
endef

# how to build static library for driver
KLIB_RULES1 = $(call KLIB_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
KLIB_RULES = $(if $(KLIB),$(call KLIB_RULES1,$(call FORM_TRG,KLIB),$(call TRG_SRC,KLIB),$(call TRG_DEPS,KLIB),$(call FORM_OBJ_DIR,KLIB)))

# this code is normally evaluated at end of target Makefile
define DEFINE_TARGETS_EVAL
# print what we will build
$(if $(DEBUG),$(eval $(DEBUG_TARGETS)))
# prepend values of $(OS)-dependent variables, then clear them
# eval _before_ using any of $(BLD_VARS)
$(eval $(OSVARS))
$(eval include $(addsuffix .mk,$(addprefix $(TOP)/make/$(OS)/use/,$(USE))))
# if there are rules to generate sources - eval them before defining objects for the target
$(eval $(GENERATE_SRC_RULES))
# evaluate $(OS)-specific default targets before defining common default targets to allow additional $(OS)-specific dependencies on targets
$(eval $(OS_DEFINE_TARGETS))
$(eval $(EXE_RULES)$(LIB_RULES)$(DLL_RULES)$(KLIB_RULES))
$(if $(TOOL_MODE),$(if $(KLIB)$(DRV),$(error cannot build drivers in tool mode)))
$(DEF_TAIL_CODE)
endef
DEFINE_TARGETS = $(if $(DEFINE_TARGETS_EVAL),)

endif # MAKE_HEADER_INCLUDED

# reset variables modifiable in target makefiles
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

# reset build targets and target-specific variables
$(eval $(RESET_TRG_VARS))

# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))

# used by make_continue.mk
MAKE_CONTINUE_HEADER = $(eval include $(MTOP)/make_header.mk)
MAKE_CONTINUE_FOOTER = $(DEFINE_TARGETS)
