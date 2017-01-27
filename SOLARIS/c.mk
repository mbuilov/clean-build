#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

OSTYPE := UNIX

# additional variables that may have target-dependent variants (EXE_RPATH, DLL_RPATH and so on)
# NOTE: these variables may also have $OS-dependent variants (RPATH_SOLARIS, DLL_RPATH_UNIX and so on)
# RPATH - runtime path of external dependencies
TRG_VARS += RPATH

# additional variables without target-dependent variants
# NOTE: these variables may also have $OS-dependent variants (MAP_SOLARIS, MAP_UNIX and so on)
# MAP - linker map file (used mostly to list exported symbols)
BLD_VARS += MAP

# reset additional variables
# $(INST_RPATH) - location where external dependency libraries are installed
# $(SOVER) - shared object library version string in form major.minor.patch (for example 1.2.3)
define RESET_OS_VARS
RPATH := $(INST_RPATH)
MAP   :=
SOVER :=
endef

ifneq ($(filter default undefined,$(origin CC)),)
# 64-bit arch: CC="cc -m64"
# 32-bit arch: CC="cc -m32"
CC := cc -m$(if $(UCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin CXX)),)
# 64-bit arch: CXX="CC -m64"
# 32-bit arch: CXX="CC -m32"
CXX := CC -m$(if $(UCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin AR)),)
# target-specific: COMPILER
AR := $(if $(filter CXX,$(COMPILER)),CC,ar)
endif

ifneq ($(filter default undefined,$(origin TCC)),)
# 64-bit arch: TCC="cc -m64"
# 32-bit arch: TCC="cc -m32"
TCC := cc -m$(if $(TCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin TCXX)),)
# 64-bit arch: TCXX="CC -m64"
# 32-bit arch: TCXX="CC -m32"
TCXX := CC -m$(if $(TCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin TAR)),)
# target-specific: COMPILER
TAR := $(if $(filter CXX,$(COMPILER)),CC,ar)
endif

ifneq ($(filter default undefined,$(origin KCC)),)
# sparc64: KCC="cc -xregs=no%appl -m64 -xmodel=kernel
# sparc32: KCC="cc -xregs=no%appl -m32
# intel64: KCC="cc -m64 -xmodel=kernel
# intel32: KCC="cc -m32
KCC := cc -m$(if $(KCPU:%64=),32,64 -xmodel=kernel)$(if $(filter sparc%,$(KCPU)), -xregs=no%appl)
endif

ifneq ($(filter default undefined,$(origin KLD)),)
# 64-bit arch: KLD="ld -64"
KLD := ld$(if $(filter %64,$(KCPU)), -64)
endif

ifndef YASMC
# intel64: YASM="yasm -f elf64 -m amd64"
# imtel32: YASM="yasm -f elf32 -m x86"
YASM := yasm -f $(if $(KCPU:%64=),elf32,elf64)$(if $(filter x86%,$(KCPU)), -m $(if $(KCPU:%64=),x86,amd64))
endif

ifndef FLEXC
FLEXC := flex
endif

ifndef BISONC
BISONC := bison
endif

# prefixes/suffixes of build targets, may be already defined in $(TOP)/make/project.mk
# note: if OBJ_SUFFIX is defined, then all prefixes/suffixes must be also defined
ifndef OBJ_SUFFIX
# exe file suffix
EXE_SUFFIX :=
# object file suffix
OBJ_SUFFIX := .o
# static library (archive) prefix/suffix
LIB_PREFIX := lib
LIB_SUFFIX := .a
# implementation library for dll prefix/suffix
IMP_PREFIX := lib
IMP_SUFFIX := .so
# dynamically loaded library (shared object) prefix/suffix
DLL_PREFIX := lib
DLL_SUFFIX := .so
# kernel-mode static library prefix/suffix
KLIB_NAME_PREFIX := k_
KLIB_PREFIX := lib$(KLIB_NAME_PREFIX)
KLIB_SUFFIX := .a
# kernel module (driver) prefix/suffix
DRV_PREFIX :=
DRV_SUFFIX :=
endif

# import library and dll - the same file
# NOTE: DLL_DIR and IMP_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)
IMP_DIR = $(LIB_DIR)

# solaris OS variant, such as SOLARIS9,SOLARIS10,SOLARIS11 and so on
# note: empty (generic variant) by default
ifndef OSVARIANT
OSVARIANT:=
endif

# standard defines
OS_PREDEFINES ?= $(OSVARIANT) SOLARIS UNIX

# application-level and kernel-level defines
# note: OS_APPDEFS and OS_KRNDEFS are may be defined as empty
ifeq (undefined,$(origin OS_APPDEFS))
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LP64) _REENTRANT
endif
ifeq (undefined,$(origin OS_KRNDEFS))
OS_KRNDEFS := $(if $(KCPU:%64=),ILP32,LP64) _KERNEL
endif

# supported target variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if $(filter LIB,$1),D)

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l - dependent static library name
# use the same variant (R) of static library as target EXE (R)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP ?= $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $d - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with R-EXE or R-DLL
ifeq (undefined,$(origin VARIANT_IMP_MAP))
VARIANT_IMP_MAP := R
endif

# default flags for shared objects
ifeq (undefined,$(origin DEF_SHARED_FLAGS))
DEF_SHARED_FLAGS := -ztext -xnolib
endif

# default shared libs for target executables and shared libraries
ifeq (undefined,$(origin DEF_SHARED_LIBS))
DEF_SHARED_LIBS :=
endif

# default flags for EXE-linker
ifeq (undefined,$(origin DEF_EXE_FLAGS))
DEF_EXE_FLAGS:=
endif

# default flags for shared objects linker
ifeq (undefined,$(origin DEF_SO_FLAGS))
DEF_SO_FLAGS := -zdefs -G
endif

# default flags for kernel library linker
ifeq (undefined,$(origin DEF_KLD_FLAGS))
DEF_KLD_FLAGS := -r
endif

# default flags for static library archiver
ifeq (undefined,$(origin DEF_AR_FLAGS))
# target-specific: COMPILER
DEF_AR_FLAGS := $(if $(filter CXX,$(COMPILER)),-xar -o,-c -r)
endif

# how to mark exported symbols from a DLL
ifeq (undefined,$(origin DLL_EXPORTS_DEFINE))
DLL_EXPORTS_DEFINE :=
endif

# how to mark imported symbols from a DLL
ifeq (undefined,$(origin DLL_IMPORTS_DEFINE))
DLL_IMPORTS_DEFINE :=
endif

# runtime-path option for EXE or DLL
# target-specific: RPATH
RPATH_OPTION ?= $(addprefix -R,$(strip $(RPATH)))

# standard C libraries
ifeq (undefined,$(origin DEF_C_LIBS))
DEF_C_LIBS := c
endif

# standard C++ libraries
ifeq (undefined,$(origin DEF_CXX_LIBS))
DEF_CXX_LIBS := Cstd Crun
endif

# common linker options for EXE or DLL
# $1 - target, $2 - objects, $3 - variant
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, COMPILER, LDFLAGS
CMN_LIBS ?= -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),-Bstatic $(addprefix -l,$(addsuffix \
  $(call VARIANT_LIB_SUFFIX,$3),$(LIBS))) -Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(addprefix \
  -l,$(SYSLIBS) $(if $(filter CXX,$(COMPILER)),$(DEF_CXX_LIBS)) $(DEF_C_LIBS)) $(DEF_SHARED_LIBS) $(LDFLAGS)

# what to export from a dll
# target-specific: MAP
VERSION_SCRIPT_OPTION ?= $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so.1.2.3, soname will be libmy_lib.so.1
SONAME_OPTION ?= $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(SOVER))))

# different linkers
# $1 - target, $2 - objects
# target-specific: TMD, COMPILER, MAP
EXE_R_LD ?= $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
DLL_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(SONAME_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD ?= $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_D_LD ?= $(LIB_R_LD)
KLIB_LD  ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)
DRV_LD   ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(if \
  $(KLIBS),-L$(LIB_DIR) $(addprefix -l$(KLIB_NAME_PREFIX),$(KLIBS))) $(LDFLAGS)

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin UDEPS_INCLUDE_FILTER))
UDEPS_INCLUDE_FILTER := /usr/include/
endif

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes to filter out

# /^$(tab)*\//!{p;d;}           - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                - strip-off leading tabs
# $(foreach x,$5,\@^$x.*@d;)    - delete lines started with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $4 - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT ?= \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$5,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $4'

# WRAP_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options, $2 - target, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER ?= (($1 -H 2>&1 && echo COMPILATION_OK 1>&2) | \
sed -n $(SED_DEPS_SCRIPT) 2>&1) 3>&2 2>&1 1>&3 3>&- | grep COMPILATION_OK > /dev/null
endif

# flags for application level C-compiler
ifeq (undefined,$(origin APP_FLAGS))
ifdef DEBUG
APP_FLAGS := -g -DDEBUG
else
APP_FLAGS := -O
endif
endif

# default flags for C++ compiler
ifeq (undefined,$(origin DEF_CXXFLAGS))
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -xstrconst -erroff=badargtype2w,wbadasg
endif

# default flags for C compiler
ifeq (undefined,$(origin DEF_CFLAGS))
DEF_CFLAGS := -xstrconst
endif

# common options for application-level C++ and C compilers
# $1 - target, $2 - source
# target-specific: DEFINES, INCLUDE
CC_PARAMS ?= -c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target, $2 - source, $3 - aux flags
# target-specific: TMD, CXXFLAGS, CFLAGS
CMN_CXX ?= $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_COMPILER,$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  ?= $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_COMPILER,$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# different compilers
# $1 - target, $2 - source
EXE_R_CXX ?= $(CMN_CXX)
EXE_R_CC  ?= $(CMN_CC)
LIB_R_CXX ?= $(EXE_R_CXX)
LIB_R_CC  ?= $(EXE_R_CC)
DLL_R_CXX ?= $(call CMN_CXX,$1,$2,-KPIC)
DLL_R_CC  ?= $(call CMN_CC,$1,$2,-KPIC)
LIB_D_CXX ?= $(DLL_R_CXX)
LIB_D_CC  ?= $(DLL_R_CC)

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin KDEPS_INCLUDE_FILTER))
KDEPS_INCLUDE_FILTER := /usr/include/
endif

# flags for kernel level C-compiler
ifeq (undefined,$(origin KRN_FLAGS))
ifdef DEBUG
KRN_FLAGS := -g -DDEBUG
else
KRN_FLAGS := -O
endif
endif

# common options for kernel-level C compiler
# $1 - target, $2 - source
# target-specific: DEFINES, INCLUDE, CFLAGS
KCC_PARAMS ?= -c $(KRN_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(DEF_CFLAGS) $(CFLAGS)

# kernel-level C compilers
# $1 - target, $2 - source
KLIB_R_CC ?= $(call SUP,KCC,$2)$(call WRAP_COMPILER,$(KCC) $(KCC_PARAMS) -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
DRV_R_CC  ?= $(KLIB_R_CC)

# kernel-level assembler
# $1 - target, $2 - source
# target-specific: ASMFLAGS
KLIB_R_ASM ?= $(call SUP,ASM,$2)$(YASMC) -o $1 $2 $(ASMFLAGS)
DRV_R_ASM  ?= $(KLIB_R_ASM)

# $1 - target, $2 - source
BISON = $(call SUP,BISON,$2)cd $1; $(BISONC) -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,EXE)
define EXE_AUX_TEMPLATE1
$1: RPATH := $(RPATH) $(EXE_RPATH)
endef
EXE_AUX_TEMPLATE = $(call EXE_AUX_TEMPLATE1,$(call FORM_TRG,EXE))

# create soft simlink $(LIB_DIR)/libmy_lib.so.1 -> libmy_lib.so.1.2.3
# $1 - full path to soft link: $(LIB_DIR)/libmy_lib.so.1
# $2 - simlinked target name:  libmy_lib.so.1.2.3
define SOFTLINK_TEMPLATE
$(STD_TARGET_VARS)
$1: $(dir $1)$2
	$$(call SUP,LN,$$@)ln -sf $$(notdir $$<) $$@
endef

# create necessary simlinks:
# $(LIB_DIR)/libmy_lib.so   -> libmy_lib.so.1
# $(LIB_DIR)/libmy_lib.so.1 -> libmy_lib.so.1.2.3
# $1 - target file: $(LIB_DIR)/libmy_lib.so.1.2.3
SOLINK_TEMPLATE1 = $(if \
  $(word 3,$1),$(newline)$(call SOFTLINK_TEMPLATE,$(dir $2)$(word 1,$1).$(word 2,$1),$(word 1,$1).$(word 2,$1).$(word 3,$1)))$(if \
  $(word 4,$1),$(newline)$(call SOFTLINK_TEMPLATE,$(dir $2)$(word 1,$1).$(word 2,$1).$(word 3,$1),$(notdir $2)))
SOLINK_TEMPLATE = $(call SOLINK_TEMPLATE1,$(subst ., ,$(notdir $1)),$1)

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,DLL)
# $2 - $(call FIXPATH,$(firstword $(DLL_MAP) $(MAP)))
define DLL_AUX_TEMPLATE1
$1: SOVER := $(SOVER)
$1: RPATH := $(RPATH) $(DLL_RPATH)
$1: MAP := $2
$1: $2
$(SOLINK_TEMPLATE)
endef
DLL_AUX_TEMPLATE = $(call DLL_AUX_TEMPLATE1,$(call FORM_TRG,DLL),$(call FIXPATH,$(firstword $(DLL_MAP) $(MAP))))

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - sdeps:       $(call TRG_SDEPS,DRV)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# note: there are SYSLIBS and SYSLIBPATH for the driver
define DRV_TEMPLATE
NEEDED_DIRS += $4
$(call OBJ_RULES,DRV,CC,$(filter %.c,$2),$3,$4)
$(call OBJ_RULES,DRV,ASM,$(filter %.asm,$2),$3,$4)
$(STD_TARGET_VARS)
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(call TRG_INCLUDE,DRV)
$1: DEFINES    := $(CMNDEFINES) $(KRNDEFS) $(DEFINES) $(DRV_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DRV_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(DRV_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DRV_LDFLAGS)
$1: $(addsuffix $(KLIB_SUFFIX),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS))) $5
	$$(call DRV_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(call TOCLEAN,$5)
endef

# how to build driver
DRV_RULES1 = $(call DRV_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DRV_RULES = $(if $(DRV),$(call DRV_RULES1,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call TRG_SDEPS,DRV),$(call FORM_OBJ_DIR,DRV)))

# this code is evaluated from $(DEFINE_TARGETS)
define OS_DEFINE_TARGETS
$(if $(EXE),$(EXE_AUX_TEMPLATE))
$(if $(DLL),$(DLL_AUX_TEMPLATE))
$(DRV_RULES)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX AR TCC TCXX TAR KCC KLD YASM FLEXC BISONC \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX \
  DLL_PREFIX DLL_SUFFIX KLIB_NAME_PREFIX KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX \
  DLL_DIR IMP_DIR OS_PREDEFINES OS_APPDEFS OS_KRNDEFS VARIANTS_FILTER \
  VARIANT_LIB_MAP VARIANT_IMP_MAP DEF_SHARED_FLAGS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE \
  RPATH_OPTION DEF_C_LIBS DEF_CXX_LIBS CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION1 SONAME_OPTION \
  EXE_R_LD DLL_R_LD LIB_R_LD LIB_D_LD KLIB_LD DRV_LD \
  UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT WRAP_COMPILER APP_FLAGS DEF_CXXFLAGS DEF_CFLAGS CC_PARAMS CMN_CXX CMN_CC \
  EXE_R_CXX EXE_R_CC LIB_R_CXX LIB_R_CC DLL_R_CXX DLL_R_CC LIB_D_CXX LIB_D_CC KDEPS_INCLUDE_FILTER KRN_FLAGS \
  KCC_PARAMS KLIB_R_CC DRV_R_CC KLIB_R_ASM DRV_R_ASM BISON FLEX \
  EXE_AUX_TEMPLATE1 EXE_AUX_TEMPLATE SOFTLINK_TEMPLATE SOLINK_TEMPLATE1 SOLINK_TEMPLATE DLL_AUX_TEMPLATE1 DLL_AUX_TEMPLATE \
  DRV_TEMPLATE DRV_RULES1 DRV_RULES)
