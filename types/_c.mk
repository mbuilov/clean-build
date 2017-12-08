#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# rules for building application-level C/C++ libs, dlls and executables

# source base definitions
ifeq (,$(filter-out undefined environment,$(origin C_BASE_TEMPLATE)))
include $(dir $(lastword $(MAKEFILE_LIST)))c/c_base.mk
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
# note: used by SUPPORTED_VARIANTS macro from $(CLEAN_BUILD_DIR)/core/variants.mk
# note: $(C_COMPILER_MK) included below may override ..._SUPPORTED_VARIANTS definitions
EXE_SUPPORTED_VARIANTS:=
LIB_SUPPORTED_VARIANTS:=
DLL_SUPPORTED_VARIANTS:=

# determine target name suffix (in case if building multiple variants of the target, each variant must have unique file name)
# $1 - non-empty target variant: P,D,S... (cannot be R - regular - it was filtered out)
# note: used by VARIANT_SUFFIX macro from $(CLEAN_BUILD_DIR)/core/variants.mk
EXE_VARIANT_SUFFIX = _$1
LIB_VARIANT_SUFFIX = _$1
DLL_VARIANT_SUFFIX = _$1

# C/C++ compiler and linker flags for the target
# $1 - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: TMD - target-specific variable, T in tool mode, empty otherwise, defined by EXE_TEMPLATE/DLL_TEMPLATE/LIB_TEMPLATE
# note: these flags should contain values of standard user-defined C/C++ compilers and linker flags, such as
#  CFLAGS, CXXFLAGS, LDFLAGS and so on, that are normally taken from the environment (in project configuration makefile),
#  their default values should be set in compiler-specific makefile, e.g.: $(CLEAN_BUILD_DIR)/compilers/gcc.mk.
# note: called by TRG_CFLAGS, TRG_CXXFLAGS and TRG_LDFLAGS from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
EXE_CFLAGS   = $($(TMD)CFLAGS)
EXE_CXXFLAGS = $($(TMD)CXXFLAGS)
EXE_LDFLAGS  = $($(TMD)LDFLAGS)
LIB_CFLAGS   = $($(TMD)CFLAGS)
LIB_CXXFLAGS = $($(TMD)CXXFLAGS)
LIB_LDFLAGS  = $($(TMD)LDFLAGS)
DLL_CFLAGS   = $($(TMD)CFLAGS)
DLL_CXXFLAGS = $($(TMD)CXXFLAGS)
DLL_LDFLAGS  = $($(TMD)LDFLAGS)

# how to mark symbols exported from a DLL
# note: overridden in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
DLL_EXPORTS_DEFINE := $(call DEFINE_SPECIAL,__attribute__((visibility("default"))))

# how to mark symbols imported from a DLL
# note: overridden in $(CLEAN_BUILD_DIR)/compilers/msvc.mk
DLL_IMPORTS_DEFINE:=

# executable file suffix
EXE_SUFFIX:=

# form target file name for EXE
# $1 - target name, e.g. my_exe, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $1 is empty
# note: used by FORM_TRG macro from $(CLEAN_BUILD_DIR)/core/variants.mk
EXE_FORM_TRG = $(1:%=$(BIN_DIR)/%$(call VARIANT_SUFFIX,EXE,$2)$(EXE_SUFFIX))

# static library (archive) prefix/suffix
LIB_PREFIX := lib
LIB_SUFFIX := .a

# form target file name for LIB
# $1 - target name, e.g. my_lib, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $1 is empty
# note: used by FORM_TRG macro from $(CLEAN_BUILD_DIR)/core/variants.mk
LIB_FORM_TRG = $(1:%=$(LIB_DIR)/$(LIB_PREFIX)%$(call VARIANT_SUFFIX,LIB,$2)$(LIB_SUFFIX))

# dynamically loaded library (shared object) prefix/suffix
DLL_PREFIX := lib
DLL_SUFFIX := .so

# assume import library and dll - the one same file
# note: DLL_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)

# form target file name for DLL
# $1 - target name, e.g. my_dll, may be empty
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain, may be empty)
# note: use $(patsubst...) to return empty value if $($1) is empty
# note: used by FORM_TRG macro from $(CLEAN_BUILD_DIR)/core/variants.mk
DLL_FORM_TRG = $(1:%=$(DLL_DIR)/$(DLL_PREFIX)%$(call VARIANT_SUFFIX,DLL,$2)$(DLL_SUFFIX))

# determine which variant of static library to link with EXE or DLL
# $1 - target type: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
# always use D-variant of static library for regular DLL
# note: if returns empty value - then assume it's default variant R
# note: used by DEP_LIBRARY macro from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
LIB_DEP_MAP = $(if $(findstring DLL,$1),D,$2)

# determine which variant of dynamic library to link with EXE or DLL
# $1 - target type: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# the same one default variant (R) of DLL may be linked with any P- or R-EXE or R-DLL
# note: if returns empty value - then assume it's default variant R
# note: used by DEP_LIBRARY macro from $(CLEAN_BUILD_DIR)/types/c/c_base.mk
DLL_DEP_MAP:=

# prefix/suffix of import library of a dll
# by default, assume dll and import library of it is the same one file
IMP_PREFIX := $(DLL_PREFIX)
IMP_SUFFIX := $(DLL_SUFFIX)

# make file names of static libraries target depends on
# $1 - target type: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
DEP_LIBS = $(foreach l,$(LIBS),$(LIB_PREFIX)$(call DEP_LIBRARY,$1,$2,$l,LIB)$(LIB_SUFFIX))

# make file names of implementation libraries of dynamic libraries target depends on
# $1 - target type: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,S,<empty>
# note: assume when building DLL, $(DLL_LD) generates implementation library for DLL in $(LIB_DIR) and DLL itself in $(DLL_DIR)
DEP_IMPS = $(foreach d,$(DLLS),$(IMP_PREFIX)$(call DEP_LIBRARY,$1,$2,$d,DLL)$(IMP_SUFFIX))

# template for building executables, used by C_RULES_TEMPL macro
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - target type: EXE or DLL
# $v - non-empty variant: R,P,S,...
# note: define target-specific variable TMD
# note: target-specific variables are passed to dependencies, so templates for dependent libs/dlls
#  must set own values of COMPILER, VINCLUDE, VDEFINES, VCFLAGS and other sensible variables
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk redefines EXE_TEMPLATE
define EXE_TEMPLATE
$(C_BASE_TEMPLATE)
$1:TMD     := $(TMD)
$1:LIBS    := $(LIBS)
$1:DLLS    := $(DLLS)
$1:LIB_DIR := $(LIB_DIR)
$1:$(addprefix $(LIB_DIR)/,$(call DEP_LIBS,$t,$v) $(call DEP_IMPS,$t,$v))
	$$(call $t_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^),$t,$v)
endef

# template for building dynamic (shared) libraries, used by C_RULES_TEMPL
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk redefines DLL_TEMPLATE
$(eval define DLL_TEMPLATE$(newline)$(value EXE_TEMPLATE)$(newline)endef)

# template for building static libraries, used by C_RULES_TEMPL
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - target type: LIB
# $v - non-empty variant: R,P,D,S
# note: define target-specific variable TMD
# note: $(CLEAN_BUILD_DIR)/compilers/msvc.mk redefines LIB_TEMPLATE
define LIB_TEMPLATE
$(C_BASE_TEMPLATE)
$1:TMD := $(TMD)
$1:
	$$(call $t_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^),$t,$v)
endef

# tools colors: C, C++ compilers, executable, shared and static library linkers
CC_COLOR  := [1;31m
CXX_COLOR := [1;36m
EXE_COLOR := [1;37m
DLL_COLOR := [1;33m
LIB_COLOR := [1;32m

# for the tool mode
TCC_COLOR  := [31m
TCXX_COLOR := [36m
TEXE_COLOR := [37m
TDLL_COLOR := [33m
TLIB_COLOR := [32m

# code to be called at beginning of target makefile
define C_PREPARE_APP_VARS
$(C_PREPARE_BASE_VARS)
EXE:=
LIB:=
DLL:=
endef

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_BASE_VARS)

# rules for building application-level targets from C/C++ sources
C_DEFINE_APP_RULES = $(C_DEFINE_RULES)

ifdef MCHECK
# check that LIBS or DLLS are specified only when building EXE or DLL
CHECK_C_APP_RULES = $(if \
  $(if $(EXE)$(DLL),,$(LIBS)),$(warning LIBS = $(LIBS) is used only when building EXE or DLL))$(if \
  $(if $(EXE)$(DLL),,$(DLLS)),$(warning DLLS = $(DLLS) is used only when building EXE or DLL))
$(call define_prepend,C_DEFINE_APP_RULES,$$(CHECK_C_APP_RULES))
endif

# optimization
ifndef TRACE
$(call expand_partially,C_DEFINE_APP_RULES,C_DEFINE_RULES)
endif

# C_COMPILER - application-level compiler to use for the build (gcc, clang, msvc, etc.)
# note: $(C_COMPILER) value is used only to form name of standard makefile with definitions of C/C++ compiler
# note: C_COMPILER may be overridden by specifying it either in the command line or in project configuration makefile
C_COMPILER := $(if \
  $(filter WIN%,$(OS)),msvc,$(if \
  $(filter SUN%,$(OS)),suncc,gcc))

# C_COMPILER_MK - makefile with definition of C/C++ compiler
C_COMPILER_MK := $(CLEAN_BUILD_DIR)/compilers/$(C_COMPILER).mk

ifeq (,$(wildcard $(C_COMPILER_MK)))
$(error file $(C_COMPILER_MK) was not found, check value of C_COMPILER_MK variable)
endif

# add compiler-specific definitions
include $(C_COMPILER_MK)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,C_APP_TARGETS C_TARGETS \
  EXE_SUPPORTED_VARIANTS LIB_SUPPORTED_VARIANTS DLL_SUPPORTED_VARIANTS \
  EXE_VARIANT_SUFFIX LIB_VARIANT_SUFFIX DLL_VARIANT_SUFFIX \
  EXE_CFLAGS EXE_CXXFLAGS EXE_LDFLAGS LIB_CFLAGS LIB_CXXFLAGS LIB_LDFLAGS DLL_CFLAGS DLL_CXXFLAGS DLL_LDFLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE EXE_SUFFIX EXE_FORM_TRG LIB_PREFIX LIB_SUFFIX LIB_FORM_TRG DLL_PREFIX DLL_SUFFIX \
  DLL_DIR DLL_FORM_TRG LIB_DEP_MAP DLL_DEP_MAP IMP_PREFIX IMP_SUFFIX DEP_LIBS=LIBS DEP_IMPS=DLLS \
  EXE_TEMPLATE=t;v;EXE;LIB_DIR;LIBS;DLLS;SYSLIBS;SYSLIBPATH DLL_TEMPLATE=t;v;DLL LIB_TEMPLATE=t;v;LIB \
  CC_COLOR CXX_COLOR EXE_COLOR DLL_COLOR LIB_COLOR TCC_COLOR TCXX_COLOR TEXE_COLOR TDLL_COLOR TLIB_COLOR \
  C_PREPARE_APP_VARS C_DEFINE_APP_RULES CHECK_C_APP_RULES C_COMPILER C_COMPILER_MK)
