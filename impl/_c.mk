#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building application-level C/C++ libs, dlls and executables

ifeq (,$(filter-out undefined environment,$(origin C_BASE_TEMPLATE)))
include $(dir $(lastword $(MAKEFILE_LIST)))c_base.mk
endif

# register application-level target types
C_APP_TARGETS := EXE LIB DLL
C_TARGETS += $(C_APP_TARGETS)

# after a target name, may be specified one or more variants of the target to build (for example, EXE := my_exe R S)
# if variant is not specified, default variant R will be built, else - only specified variants (may add R to build also default variant)
#
# interpretation of variants depends on target type and destination platform, example:
# R (default, regular variant)
#  for UNIX:
#   EXE,LIB     - position-dependent code
#   DLL         - position-independent code
#  for WINDOWS:
#   EXE,LIB,DLL - dynamically linked multi-threaded libc (compiled with /MD cl.exe option)
# P (position-independent code in executables)
#  for UNIX:
#   EXE,LIB     - position-independent code in executables (compiled with -fpie gcc option)
# D (position-independent code in shared libraries)
#  for UNIX:
#   LIB         - position-independent code in shared libraries (compiled with -fpic gcc option)
# S (statically linked multi-threaded libc)
#  for WINDOWS:
#   EXE,LIB,DLL - statically linked multi-threaded libc (compiled with /MT cl.exe option)
#
# so, available variants for targets types:
# EXE:
#  R,P,S
# DLL:
#  R,S
# LIB:
#  R (for linking with R-variant of EXE)
#  P (for linking with P-variant of EXE)
#  D (for linking with DLL)
#  S (for linking with S-variant of EXE or DLL)

# no non-regular target variants are supported by default
# note: $(C_COMPILER) included below may override ..._NON_REGULAR_VARIANTS definitions
EXE_NON_REGULAR_VARIANTS:=
LIB_NON_REGULAR_VARIANTS:=
DLL_NON_REGULAR_VARIANTS:=

# determine target name suffix (in case if building multiple variants of the target, each variant must have unique file name)
# $1 - target: EXE,LIB,DLL,...
# $2 - non-empty target variant: P,D,S... (cannot be R - regular - it was filtered out)
EXE_VARIANT_SUFFIX = _$2
LIB_VARIANT_SUFFIX = _$2
DLL_VARIANT_SUFFIX = _$2

# executable file suffix
EXE_SUFFIX:=

# form target file name for EXE
# $1 - EXE
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $($1) is empty
EXE_FORM_TRG = $(GET_TARGET_NAME:%=$(BIN_DIR)/%$(VARIANT_SUFFIX)$(EXE_SUFFIX))

# static library (archive) prefix/suffix
LIB_PREFIX := lib
LIB_SUFFIX := .a

# form target file name for LIB
# $1 - LIB
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $($1) is empty
LIB_FORM_TRG = $(GET_TARGET_NAME:%=$(LIB_DIR)/$(LIB_PREFIX)%$(VARIANT_SUFFIX)$(LIB_SUFFIX))

# dynamically loaded library (shared object) prefix/suffix
DLL_PREFIX := lib
DLL_SUFFIX := .so

# assume import library and dll - the one same file
# note: DLL_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)

# form target file name for DLL
# $1 - DLL
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $($1) is empty
DLL_FORM_TRG = $(GET_TARGET_NAME:%=$(DLL_DIR)/$(DLL_PREFIX)%$(VARIANT_SUFFIX)$(DLL_SUFFIX))

# for DEPENDENCY_SUFFIX, determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependency type: LIB
# use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
# always use D-variant of static library for DLL
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides LIB_DEPENDENCY_MAP
LIB_DEPENDENCY_MAP = $(if $(filter DLL,$1),D,$2)

# for DEPENDENCY_SUFFIX, determine which variant of dynamic library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependency type: DLL
# the same one default variant (R) of DLL may be linked with any P- or R-EXE or R-DLL
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides DLL_DEPENDENCY_MAP
DLL_DEPENDENCY_MAP := R

# prefix/suffix of import library of a dll
# by default, assume dll and import library of it is the same one file
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk overrides IMP_PREFIX/IMP_SUFFIX
IMP_PREFIX := $(DLL_PREFIX)
IMP_SUFFIX := $(DLL_SUFFIX)

# make file names of static libraries target depends on
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_LIBS = $(foreach l,$(LIBS),$(LIB_PREFIX)$l$(call DEPENDENCY_SUFFIX,$1,$2,LIB,$l)$(LIB_SUFFIX))

# make file names of implementation libraries of dynamic libraries target depends on
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# note: assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(LIB_DIR) and DLL itself in $(DLL_DIR)
DEP_IMPS = $(foreach d,$(DLLS),$(IMP_PREFIX)$d$(call DEPENDENCY_SUFFIX,$1,$2,DLL,$l)$(IMP_SUFFIX))

# template for building executables, used by C_RULES macro
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE or DLL
# $v - non-empty variant: R,P,S,...
# note: target-specific variables are passed to dependencies, so templates for
#  dependent libs/dlls must set own values of INCLUDE, DEFINES, CFLAGS and other sensible variables
define EXE_TEMPLATE
$(C_BASE_TEMPLATE)
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

# template for building static libraries, used by C_RULES
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - LIB
# $v - non-empty variant: R,P,D,S
define LIB_TEMPLATE
$(C_BASE_TEMPLATE)
$1:
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

# tools colors: C, C++ compilers, library archiver, shared library and executable linkers
CC_COLOR   := [1;31m
CXX_COLOR  := [1;36m
AR_COLOR   := [1;32m
LD_COLOR   := [1;33m
XLD_COLOR  := [1;37m
SLD_COLOR  := [1;37m
TCC_COLOR  := [32m
TCXX_COLOR := [32m
TAR_COLOR  := [1;32m
TLD_COLOR  := [33m
TXLD_COLOR := [1;37m
TSLD_COLOR := [1;37m

# code to be called at beginning of target makefile
define C_PREPARE_APP_VARS
$(C_PREPARE_BASE_VARS)
EXE:=
LIB:=
DLL:=
DEFINE_TARGETS_EVAL_NAME:=DEFINE_C_APP_EVAL
MAKE_CONTINUE_EVAL_NAME:=CLEAN_BUILD_C_APP_EVAL
endef

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_BASE_VARS)

# code to be called at beginning of target makefile
CLEAN_BUILD_C_APP_EVAL = $(DEF_HEAD_CODE_EVAL)$(eval $(C_PREPARE_APP_VARS))

# this code is normally evaluated at end of target makefile
DEFINE_C_APP_EVAL = $(C_RULES_EVAL)$(DEF_TAIL_CODE_EVAL)

ifdef MCHECK
# check that LIBS or DLLS are specified only when building EXE or DLL
CHECK_C_APP_RULES = $(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL))$(if \
  $(if $(EXE)$(DLL),,$(DLLS)),$(warning DLLS = $(DLLS) is used only when building EXE or DLL))
$(call define_prepend,DEFINE_C_APP_EVAL,$$(CHECK_C_APP_RULES))
endif

# C_COMPILER - application-level compiler to use for the build (gcc, clang, msvc, etc.)
# note: C_COMPILER may be overridden by specifying either in in command line or in project configuration makefile
ifeq (LINUX,$(OS))
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/gcc.mk
else ifneq (WINDOWS,$(OS))
C_COMPILER:=
else ifneq (,$(filter /cygdrive/%,$(CURDIR)))
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/gcc.mk
else
C_COMPILER := $(CLEAN_BUILD_DIR)/compilers/msvc.mk
endif

# ensure C_COMPILER variable is non-recursive (simple)
override C_COMPILER := $(C_COMPILER)

ifndef C_COMPILER
$(error C_COMPILER - application-level C/C++ complier is not defined)
endif

ifeq (,$(wildcard $(C_COMPILER)))
$(error file $(C_COMPILER) was not found, check value of C_COMPILER variable)
endif

# add compiler-specific definitions
include $(C_COMPILER)

# protect variables from modifications in target makefiles
# note: do not trace calls to C_COMPILER variable because it is used in ifdefs
$(call SET_GLOBAL,C_COMPILER,0)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,C_APP_TARGETS C_TARGETS \
  EXE_NON_REGULAR_VARIANTS LIB_NON_REGULAR_VARIANTS DLL_NON_REGULAR_VARIANTS \
  EXE_VARIANT_SUFFIX LIB_VARIANT_SUFFIX DLL_VARIANT_SUFFIX \
  EXE_SUFFIX EXE_FORM_TRG LIB_PREFIX LIB_SUFFIX LIB_FORM_TRG DLL_PREFIX DLL_SUFFIX DLL_DIR DLL_FORM_TRG \
  LIB_DEPENDENCY_MAP DLL_DEPENDENCY_MAP IMP_PREFIX IMP_SUFFIX DEP_LIBS=LIBS DEP_IMPS=DLLS \
  EXE_TEMPLATE=t;v;EXE;LIB_DIR;LIBS;DLLS;SYSLIBS;SYSLIBPATH DLL_TEMPLATE=t;v;DLL LIB_TEMPLATE=t;v;LIB \
  CC_COLOR CXX_COLOR AR_COLOR LD_COLOR XLD_COLOR SLD_COLOR TCC_COLOR TCXX_COLOR TAR_COLOR TLD_COLOR TXLD_COLOR TSLD_COLOR \
  C_PREPARE_APP_VARS CLEAN_BUILD_C_APP_EVAL DEFINE_C_APP_EVAL CHECK_C_APP_RULES)
