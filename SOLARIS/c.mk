#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# INST_RPATH - location where external dependency libraries are installed: /opt/lib or $ORIGIN/../lib
INST_RPATH:=

# reset additional variables
# RPATH - runtime path of external dependencies
# MAP   - linker map file (used mostly to list exported symbols)
$(eval define PREPARE_C_VARS$(newline)$(value PREPARE_C_VARS)$(newline)RPATH:=$(if \
  $(findstring simple,$(flavor INST_RPATH)),$(INST_RPATH),$$(INST_RPATH))$(newline)MAP:=$(newline)endef)

# compilers
CC   := cc -m$(if $(CPU:%64=),32,64)
CXX  := CC -m$(if $(CPU:%64=),32,64 -xport64)
TCC  := cc -m$(if $(TCPU:%64=),32,64)
TCXX := CC -m$(if $(TCPU:%64=),32,64 -xport64)

# static library archiver
# target-specific: COMPILER
AR  = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(CPU:x86_64=),,/amd64)/ar,$(CXX))
TAR = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar,$(TCXX))

# sparc64: KCC="cc -xregs=no%appl -m64 -xmodel=kernel
# sparc32: KCC="cc -xregs=no%appl -m32
# intel64: KCC="cc -m64 -xmodel=kernel
# intel32: KCC="cc -m32
KCC := cc -m$(if $(KCPU:%64=),32,64 -xmodel=kernel)$(if $(KCPU:sparc%=),, -xregs=no%appl)

# 64-bit arch: KLD="ld -64"
KLD := /usr/ccs/bin$(if $(KCPU:x86_64=),,/amd64)/ld$(if $(KCPU:%64=),, -64)

# yasm/flex/bison compilers
YASMC  := yasm
FLEXC  := flex
BISONC := bison

# note: assume yasm used only for drivers
YASM_FLAGS := -f $(if $(KCPU:%64=),elf32,elf64)$(if $(KCPU:x86%=),, -m $(if $(KCPU:%64=),x86,amd64))

# exe file suffix
EXE_SUFFIX:=

# object file suffix
OBJ_SUFFIX := .o

# static library (archive) prefix/suffix
LIB_PREFIX := lib
LIB_SUFFIX := .a

# dynamically loaded library (shared object) prefix/suffix
DLL_PREFIX := lib
DLL_SUFFIX := .so

# import library for dll prefix/suffix
IMP_PREFIX := $(DLL_PREFIX)
IMP_SUFFIX := $(DLL_SUFFIX)

# kernel-mode static library prefix/suffix
KLIB_NAME_PREFIX := k_
KLIB_PREFIX := lib$(KLIB_NAME_PREFIX)
KLIB_SUFFIX := .a

# kernel module (driver) prefix/suffix
DRV_PREFIX:=
DRV_SUFFIX:=

# import library and dll - the same file
# NOTE: DLL_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)

# variants filter function - get possible variants for the target, needed by $(CLEAN_BUILD_DIR)/c.mk
# $1 - LIB,EXE,DLL
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if $(filter LIB,$1),D)

# determine suffix for static LIB or for import library of DLL
# $1 - target variant R,D,<empty>
# note: overrides value from $(CLEAN_BUILD_DIR)/c.mk
LIB_VAR_SUFFIX = $(if \
                 $(filter D,$1),_pic)

# for $(DEP_LIB_SUFFIX) from $(CLEAN_BUILD_DIR)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,<empty>
# $3 - dependent static library name
# use the same variant (R) of static library as target EXE (R)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP = $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(CLEAN_BUILD_DIR)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,<empty>
# $3 - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with R-EXE or R-DLL
VARIANT_IMP_MAP := R

# default flags for shared objects (executables and shared libraries)
DEF_SHARED_FLAGS := -ztext -xnolib

# default shared libs for target executables and shared libraries
DEF_SHARED_LIBS:=

# default flags for EXE-target linker
DEF_EXE_FLAGS:=

# default flags for SO-target linker
DEF_SO_FLAGS := -zdefs -G

# default flags for kernel library linker
DEF_KLD_FLAGS := -r

# default flags for static library archiver
# target-specific: COMPILER
DEF_AR_FLAGS = $(if $(COMPILER:CXX=),-c -r,-xar -o)

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE:=

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE:=

# runtime-path option for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix -R,$(strip $(RPATH)))

# standard C libraries
DEF_C_LIBS := -lc

# standard C++ libraries
DEF_CXX_LIBS := -lCstd -lCrun

# common linker options for EXE or DLL
# $1 - target
# $2 - objects
# $3 - variant
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, COMPILER, LDFLAGS
CMN_LIBS = -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),-Bstatic $(addprefix -l,$(addsuffix \
  $(call LIB_VAR_SUFFIX,$3),$(LIBS))) -Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(if \
  $(COMPILER:CXX=),,$(DEF_CXX_LIBS)) $(DEF_C_LIBS) $(DEF_SHARED_LIBS) $(LDFLAGS)

# what to export from a dll
# target-specific: MAP
VERSION_SCRIPT_OPTION = $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# different linkers
# $1 - target
# $2 - objects
# target-specific: TMD, COMPILER
EXE_R_LD = $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
DLL_R_LD = $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(SONAME_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD = $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_D_LD = $(LIB_R_LD)
KLIB_R_LD = $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)
DRV_R_LD = $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(if \
  $(KLIBS),-L$(LIB_DIR) $(addprefix -l$(KLIB_NAME_PREFIX),$(KLIBS))) $(LDFLAGS)

# $(SED) expression to filter-out system files while dependencies generation
UDEPS_INCLUDE_FILTER := /usr/include/

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes to filter out

# /^$(tab)*\//!{p;d;}           - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                - strip-off leading tabs
# $(foreach x,$5,\@^$x.*@d;)    - delete lines started with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $4 - make dependencies, then write to generated dep-file

SED_DEPS_SCRIPT = \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$5,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $4'

# WRAP_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER = (($1 -H 2>&1 && echo COMPILATION_OK 1>&2) |\
  sed -n $(SED_DEPS_SCRIPT) 2>&1) 3>&2 2>&1 1>&3 3>&- | grep COMPILATION_OK > /dev/null
endif

# default flags for C++ compiler
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg

# default flags for C compiler
DEF_CFLAGS:=

# flags for applications- level C/C++-compiler
ifdef DEBUG
OS_APP_CFLAGS := -g
else
OS_APP_CFLAGS := -O
endif

# APP_CFLAGS may be overridden in project makefile
APP_CFLAGS := $(OS_APP_CFLAGS)

# application-level defines
OS_APP_DEFINES:=

# APP_DEFINES may be overridden in project makefile
APP_DEFINES := $(OS_APP_DEFINES)

# common options for application-level C++ and C compilers
# $1 - target object file
# $2 - source
# target-specific: DEFINES, INCLUDE
CC_PARAMS = -c $(APP_CFLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(APP_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - aux flags
# target-specific: TMD, CXXFLAGS, CFLAGS
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_COMPILER,$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXFLAGS) $3 -o $1 $2,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  = $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_COMPILER,$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(CFLAGS) $3 -o $1 $2,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# position-independent code for shared objects (dynamic libraries)
PIC_OPTION := -KPIC

# different compilers
# $1 - target object file
# $2 - source
EXE_R_CXX = $(CMN_CXX)
EXE_R_CC  = $(CMN_CC)
LIB_R_CXX = $(EXE_R_CXX)
LIB_R_CC  = $(EXE_R_CC)
DLL_R_CXX = $(call CMN_CXX,$1,$2,$(PIC_OPTION))
DLL_R_CC  = $(call CMN_CC,$1,$2,$(PIC_OPTION))
LIB_D_CXX = $(DLL_R_CXX)
LIB_D_CC  = $(DLL_R_CC)

# $(SED) expression to filter-out system files while dependencies generation
KDEPS_INCLUDE_FILTER := /usr/include/

# flags for kernel-level C-compiler
ifdef DEBUG
OS_KRN_CFLAGS := -g
else
OS_KRN_CFLAGS := -O
endif

# KRN_CFLAGS may be overridden in project makefile
KRN_CFLAGS := $(OS_KRN_CFLAGS)

# kernel-level defines
OS_KRN_DEFINES:=

# KRN_DEFINES may be overridden in project makefile
KRN_DEFINES = $(OS_KRN_DEFINES)

# common options for kernel-level C compiler
# $1 - target object file
# $2 - source
# target-specific: DEFINES, INCLUDE, CFLAGS
KCC_PARAMS = -c $(KRN_CFLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(KRN_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# kernel-level C compilers
# $1 - targets object file
# $2 - source
KLIB_R_CC = $(call SUP,KCC,$2)$(call \
  WRAP_COMPILER,$(KCC) $(DEF_CFLAGS) $(KCC_PARAMS) $(CFLAGS) -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
DRV_R_CC  = $(KLIB_R_CC)

# kernel-level assembler
# $1 - target object file
# $2 - asm-source
# target-specific: ASMFLAGS
KLIB_R_ASM = $(call SUP,ASM,$2)$(YASMC) $(YASM_FLAGS) $(ASMFLAGS) -o $1 $2
DRV_R_ASM  = $(KLIB_R_ASM)

# $1 - target
# $2 - source
BISON = $(call SUP,BISON,$2)$(BISONC) -o $1 -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - EXE
define EXE_AUX_TEMPLATE2
$1: RPATH := $(subst $$,$$$$,$(RPATH))
$1: MAP := $2
$1: $2
endef

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
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
MOD_AUX_TEMPLATE  = $(call MOD_AUX_TEMPLATE1,$(call fixpath,$(MAP)))

# this code is evaluated from $(DEFINE_TARGETS)
define OS_DEFINE_TARGETS
$(foreach t,EXE DLL,$(if $($t),$(MOD_AUX_TEMPLATE)))
endef

ifdef DRIVERS_SUPPORT

# how to build driver, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - DRV
# $v - non-empty variant: R
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
$1: DEFINES    := $(TRG_DEFINES)
$1: CFLAGS     := $(TRG_CFLAGS)
$1: CXXFLAGS   := $(TRG_CXXFLAGS)
$1: ASMFLAGS   := $(TRG_ASMFLAGS)
$1: LDFLAGS    := $(TRG_LDFLAGS)
$1: SYSLIBS    := $(SYSLIBS)
$1: SYSLIBPATH := $(SYSLIBPATH)
$1: $(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX)))
	$$(call $t_$v_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
endef

endif # DRIVERS_SUPPORT

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,INST_RPATH CC CXX TCC TCXX AR TAR KCC KLD YASMC FLEXC BISONC YASM_FLAGS \
  KLIB_NAME_PREFIX DEF_SHARED_FLAGS DEF_SHARED_LIBS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE RPATH_OPTION DEF_C_LIBS DEF_CXX_LIBS CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION \
  EXE_R_LD DLL_R_LD LIB_R_LD LIB_D_LD KLIB_R_LD DRV_R_LD \
  UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT WRAP_COMPILER \
  DEF_CXXFLAGS DEF_CFLAGS OS_APP_CFLAGS APP_CFLAGS OS_APP_DEFINES APP_DEFINES CC_PARAMS CMN_CXX CMN_CC \
  PIC_OPTION EXE_R_CXX EXE_R_CC LIB_R_CXX LIB_R_CC DLL_R_CXX DLL_R_CC LIB_D_CXX LIB_D_CC \
  KDEPS_INCLUDE_FILTER OS_KRN_CFLAGS KRN_CFLAGS OS_KRN_DEFINES KRN_DEFINES \
  KCC_PARAMS KLIB_R_CC DRV_R_CC KLIB_R_ASM DRV_R_ASM BISON FLEX \
  EXE_AUX_TEMPLATE2=t DLL_AUX_TEMPLATE2=t MOD_AUX_TEMPLATE1=t MOD_AUX_TEMPLATE=t DRV_TEMPLATE=DRV;LIB_DIR;KLIBS;SYSLIBS;SYSLIBPATH)
