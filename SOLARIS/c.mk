#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# INST_RPATH - location where external dependency libraries are installed: /opt/lib or $ORIGIN/../lib
ifeq (undefined,$(origin INST_RPATH))
INST_RPATH:=
endif

# reset additional variables
# RPATH - runtime path of external dependencies
# MAP   - linker map file (used mostly to list exported symbols)
define RESET_OS_CVARS
RPATH := $(INST_RPATH)
MAP:=
endef

# make RESET_OS_CVARS variable non-recursive (simple)
ifeq (simple,$(flavor INST_RPATH))
RESET_OS_CVARS := $(RESET_OS_CVARS)
endif

ifneq ($(filter default undefined,$(origin CC)),)
# 64-bit arch: CC="cc -m64"
# 32-bit arch: CC="cc -m32"
CC := cc -m$(if $(UCPU:%64=),32,64 -xport64)
endif

ifneq ($(filter default undefined,$(origin CXX)),)
# 64-bit arch: CXX="CC -m64"
# 32-bit arch: CXX="CC -m32"
CXX := CC -m$(if $(UCPU:%64=),32,64 -xport64)
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

# exe file suffix
ifeq (undefined,$(origin EXE_SUFFIX))
EXE_SUFFIX:=
endif

# object file suffix
ifeq (undefined,$(origin OBJ_SUFFIX))
OBJ_SUFFIX := .o
endif

# static library (archive) prefix/suffix
ifeq (undefined,$(origin LIB_PREFIX))
LIB_PREFIX := lib
endif

ifeq (undefined,$(origin LIB_SUFFIX))
LIB_SUFFIX := .a
endif

# dynamically loaded library (shared object) prefix/suffix
ifeq (undefined,$(origin DLL_PREFIX))
DLL_PREFIX := lib
endif

ifeq (undefined,$(origin DLL_SUFFIX))
DLL_SUFFIX := .so
endif

# import library for dll prefix/suffix
ifeq (undefined,$(origin IMP_PREFIX))
IMP_PREFIX := $(DLL_PREFIX)
endif

ifeq (undefined,$(origin IMP_SUFFIX))
IMP_SUFFIX := $(DLL_SUFFIX)
endif

# kernel-mode static library prefix/suffix
ifeq (undefined,$(origin KLIB_NAME_PREFIX))
KLIB_NAME_PREFIX := k_
endif

ifeq (undefined,$(origin KLIB_PREFIX))
KLIB_PREFIX := lib$(KLIB_NAME_PREFIX)
endif

ifeq (undefined,$(origin KLIB_SUFFIX))
KLIB_SUFFIX := .a
endif

# kernel module (driver) prefix/suffix
ifeq (undefined,$(origin DRV_PREFIX))
DRV_PREFIX:=
endif

ifeq (undefined,$(origin DRV_SUFFIX))
DRV_SUFFIX:=
endif

# import library and dll - the same file
# NOTE: DLL_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)

# solaris OS variant, such as SOLARIS9,SOLARIS10,SOLARIS11 and so on
# note: empty (generic variant) by default
ifndef OSVARIANT
OSVARIANT:=
endif

# standard defines
ifeq (undefined,$(origin OS_PREDEFINES))
ifeq (simple,$(flavor OSVARIANT))
OS_PREDEFINES := $(OSVARIANT) SOLARIS UNIX
else
OS_PREDEFINES = $(OSVARIANT) SOLARIS UNIX
endif
endif

# application-level and kernel-level defines
# note: OS_APPDEFS and OS_KRNDEFS are may be defined as empty
ifeq (undefined,$(origin OS_APPDEFS))
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LP64) _REENTRANT
endif
ifeq (undefined,$(origin OS_KRNDEFS))
OS_KRNDEFS := $(if $(KCPU:%64=),ILP32,LP64) _KERNEL
endif

# variants filter function - get possible variants for the target
# $1 - LIB,EXE,DLL
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER ?= $(if $(filter LIB,$1),D)

# determine suffix for static LIB or for import library of DLL
# $1 - target variant R,D,<empty>
LIB_VAR_SUFFIX ?= $(if \
                  $(filter D,$1),_pic)

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,<empty>
# $3 - dependent static library name
# use the same variant (R) of static library as target EXE (R)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP ?= $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,<empty>
# $3 - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with R-EXE or R-DLL
ifeq (undefined,$(origin VARIANT_IMP_MAP))
VARIANT_IMP_MAP := R
endif

# default flags for shared objects (executables and shared libraries)
ifeq (undefined,$(origin DEF_SHARED_FLAGS))
DEF_SHARED_FLAGS := -ztext -xnolib
endif

# default shared libs for target executables and shared libraries
ifeq (undefined,$(origin DEF_SHARED_LIBS))
DEF_SHARED_LIBS:=
endif

# default flags for EXE-target linker
ifeq (undefined,$(origin DEF_EXE_FLAGS))
DEF_EXE_FLAGS:=
endif

# default flags for SO-target linker
ifeq (undefined,$(origin DEF_SO_FLAGS))
DEF_SO_FLAGS := -zdefs -G
endif

# default flags for kernel library linker
ifeq (undefined,$(origin DEF_KLD_FLAGS))
DEF_KLD_FLAGS := -r
endif

# default flags for objects archiver
ifeq (undefined,$(origin DEF_AR_FLAGS))
# target-specific: COMPILER
DEF_AR_FLAGS := $(if $(filter CXX,$(COMPILER)),-xar -o,-c -r)
endif

# how to mark exported symbols from a DLL
ifeq (undefined,$(origin DLL_EXPORTS_DEFINE))
DLL_EXPORTS_DEFINE:=
endif

# how to mark imported symbols from a DLL
ifeq (undefined,$(origin DLL_IMPORTS_DEFINE))
DLL_IMPORTS_DEFINE:=
endif

# runtime-path option for EXE or DLL
# target-specific: RPATH
RPATH_OPTION ?= $(addprefix -R,$(strip $(RPATH)))

# standard C libraries
ifeq (undefined,$(origin DEF_C_LIBS))
DEF_C_LIBS := -lc
endif

# standard C++ libraries
ifeq (undefined,$(origin DEF_CXX_LIBS))
DEF_CXX_LIBS := -lCstd -lCrun
endif

# common linker options for EXE or DLL
# $1 - target
# $2 - objects
# $3 - variant
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, COMPILER, LDFLAGS
CMN_LIBS ?= -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),-Bstatic $(addprefix -l,$(addsuffix \
  $(call LIB_VAR_SUFFIX,$3),$(LIBS))) -Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(if \
  $(filter CXX,$(COMPILER)),$(DEF_CXX_LIBS)) $(DEF_C_LIBS) $(DEF_SHARED_LIBS) $(LDFLAGS)

# what to export from a dll
# target-specific: MAP
VERSION_SCRIPT_OPTION ?= $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION ?= $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# different linkers
# $1 - target
# $2 - objects
# target-specific: TMD, COMPILER
EXE_R_LD ?= $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
DLL_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(SONAME_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD ?= $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_D_LD ?= $(LIB_R_LD)
KLIB_R_LD ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)
DRV_R_LD ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(if \
  $(KLIBS),-L$(LIB_DIR) $(addprefix -l$(KLIB_NAME_PREFIX),$(KLIBS))) $(LDFLAGS)

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin UDEPS_INCLUDE_FILTER))
UDEPS_INCLUDE_FILTER := /usr/include/
endif

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes to filter out

# /^$(tab)*\//!{p;d;}           - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                - strip-off leading tabs
# $(foreach x,$5,\@^$x.*@d;)    - delete lines started with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $4 - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT ?= \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$5,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $4'

# WRAP_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER ?= (($1 -H 2>&1 && echo COMPILATION_OK 1>&2) | \
sed -n $(SED_DEPS_SCRIPT) 2>&1) 3>&2 2>&1 1>&3 3>&- | grep COMPILATION_OK > /dev/null
endif

# flags for application level C/C++-compiler
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
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg
endif

# default flags for C compiler
ifeq (undefined,$(origin DEF_CFLAGS))
DEF_CFLAGS:=
endif

# common options for application-level C++ and C compilers
# $1 - target
# $2 - source
# target-specific: DEFINES, INCLUDE
CC_PARAMS ?= -c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target
# $2 - source
# $3 - aux flags
# target-specific: TMD, CXXFLAGS, CFLAGS
CMN_CXX ?= $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_COMPILER,$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  ?= $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_COMPILER,$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# different compilers
# $1 - target
# $2 - source
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
# $1 - target
# $2 - source
# target-specific: DEFINES, INCLUDE, CFLAGS
KCC_PARAMS ?= -c $(KRN_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(DEF_CFLAGS) $(CFLAGS)

# kernel-level C compilers
# $1 - targets
# $2 - source
KLIB_R_CC ?= $(call SUP,KCC,$2)$(call WRAP_COMPILER,$(KCC) $(KCC_PARAMS) -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
DRV_R_CC  ?= $(KLIB_R_CC)

# kernel-level assembler
# $1 - target
# $2 - source
# target-specific: ASMFLAGS
KLIB_R_ASM ?= $(call SUP,ASM,$2)$(YASMC) -o $1 $2 $(ASMFLAGS)
DRV_R_ASM  ?= $(KLIB_R_ASM)

# $1 - target
# $2 - source
BISON ?= $(call SUP,BISON,$2)$(BISONC) -o $1 -d --fixed-output-files $(abspath $2)
FLEX  ?= $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call FIXPATH,$(MAP))
# $t - EXE
define EXE_AUX_TEMPLATE2
$1: RPATH := $(subst $$,$$$$,$(RPATH))
$1: MAP := $2
$1: $2
endef

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call FIXPATH,$(MAP))
# $t - DLL
define DLL_AUX_TEMPLATE2
$1: MODVER := $(MODVER)
$1: RPATH := $(subst $$,$$$$,$(RPATH))
$1: MAP := $2
$1: $2
endef

# auxiliary defines for EXE or DLL
# $t - EXE or DLL
MOD_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,$t),$(call $t_AUX_TEMPLATE2,$(call FORM_TRG,$t,$v),$2))
MOD_AUX_TEMPLATE = $(call MOD_AUX_TEMPLATE1,$(call FIXPATH,$(MAP)))

# this code is evaluated from $(DEFINE_TARGETS)
ifndef OS_DEFINE_TARGETS
define OS_DEFINE_TARGETS
$(foreach t,EXE DLL,$(if $($t),$(MOD_AUX_TEMPLATE)))
endef
endif

# how to build driver, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - DRV
# $v - non-empty variant: R
ifndef DRV_TEMPLATE
define DRV_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$1: $(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1: $(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1: $(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1: COMPILER   := $(if $(filter %.cpp,$2),CXX,CC)
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(TRG_INCLUDE)
$1: DEFINES    := $(CMNDEFINES) $(KRNDEFS) $(DEFINES)
$1: CFLAGS     := $(CFLAGS)
$1: CXXFLAGS   := $(CXXFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH)
$1: $(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX)))
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX AR TCC TCXX TAR KCC KLD YASM FLEXC BISONC \
  KLIB_NAME_PREFIX DEF_SHARED_FLAGS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE \
  RPATH_OPTION DEF_C_LIBS DEF_CXX_LIBS CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION1 SONAME_OPTION \
  EXE_R_LD DLL_R_LD LIB_R_LD LIB_D_LD KLIB_R_LD DRV_R_LD \
  UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT WRAP_COMPILER APP_FLAGS DEF_CXXFLAGS DEF_CFLAGS CC_PARAMS CMN_CXX CMN_CC \
  EXE_R_CXX EXE_R_CC LIB_R_CXX LIB_R_CC DLL_R_CXX DLL_R_CC LIB_D_CXX LIB_D_CC KDEPS_INCLUDE_FILTER KRN_FLAGS \
  KCC_PARAMS KLIB_R_CC DRV_R_CC KLIB_R_ASM DRV_R_ASM BISON FLEX \
  EXE_AUX_TEMPLATE2 DLL_AUX_TEMPLATE2 MOD_AUX_TEMPLATE1 MOD_AUX_TEMPLATE)
