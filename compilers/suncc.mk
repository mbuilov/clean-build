#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

-xc99=%all
-xlang=c99
-xldscope=hidden
–xsafe=mem (sparc only)
–fast (both compile and link phases)
-i Tells the linker, ld, to ignore any LD_LIBRARY_PATH setting.
–norunpath Does not build a runtime search path for shared libraries into the executable.
–O The -O macro now expands to -xO3 instead of -xO2.
–xO5


# define INST_RPATH, RPATH and MAP variables
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# compilers
# note: for -xport64 option see https://docs.oracle.com/cd/E19205-01/819-5267/bkbgj/index.html
CC   := cc -m$(if $(CPU:%64=),32,64 -xarch=sse2)
CXX  := CC -m$(if $(CPU:%64=),32,64 -xarch=sse2 -xport64)
TCC  := cc -m$(if $(TCPU:%64=),32,64 -xarch=sse2)
TCXX := CC -m$(if $(TCPU:%64=),32,64 -xarch=sse2 -xport64)

# static library archiver
# target-specific: COMPILER
# note: use CXX compiler instead of ar for creating C++ static library archives
#  - for adding necessary C++ templates to the archives,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamp/index.html
AR  = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar,$(CXX))
TAR = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar,$(TCXX))

# position-independent code for executables/shared objects (dynamic libraries)
PIC_CC_OPTION := -Kpic
PIE_LD_OPTION := –ztype=pie

# supported variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - position-independent code in executables (for EXE)
# D - position-independent code in executables or shared libraries (for LIB)
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_SUPPORTED_VARIANTS := P
LIB_SUPPORTED_VARIANTS := D

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - target: EXE
# $2 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX := _pie

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - target: LIB
# $2 - D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_SUFFIX := _pic

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - target: EXE
# $2 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_CCOPTS  := $(PIC_CC_OPTION)
EXE_VARIANT_CXXOPTS := $(PIC_CC_OPTION)
EXE_VARIANT_LDOPTS  := $(PIE_LD_OPTION)

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - target: LIB
# $2 - D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_CCOPTS  := $(PIC_CC_OPTION)
LIB_VARIANT_CXXOPTS := $(PIC_CC_OPTION)

# determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency type: LIB
# note: if returns empty value - then assume it's default variant R
# use D-variant of static library for pie-EXE or DLL
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_DEP_MAP = $(if $(filter DLL,$1)$(filter P,$2),D)

# ld flags that may be modified by user
# note: '–xs' - allows debugging by dbx without object (.o) files
LDFLAGS := $(if $(DEBUG),-g -xs,-fast)

# common cc flags for linking executables and shared libraries
# note: may use -filt=%none to not demangle C++ names
# note: use '-xlang=c99' to link appropriate c99 system libraries for sources compiled with '-xc99=%all'
CMN_LDFLAGS := -ztext -xlang=c99

# cc flags for linking an EXE
EXE_LDFLAGS:=

# cc flags for linking a DLL
SO_LDFLAGS := -zdefs -G

# flags for objects archiver
# target-specific: COMPILER
# note: to handle C++ templates, CC compiler is used to create C++ static libraries
ARFLAGS = $(if $(COMPILER:CXX=),-c -r,-xar -o)

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE := "__attribute__((visibility(\"default\")))"

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE:=

# runtime-path option for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix -R,$(strip $(RPATH)))

# for '-xnolib':
# standard C libraries: -lc
# standard C++ libraries: -lCstd -lCrun

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - non-empty variant: R,P,D
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, COMPILER, LDOPTS
CMN_LIBS = -o $1 $2 $(RPATH_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),-Bstatic $(addprefix -l,$(addsuffix \
  $(call DEP_SUFFIX,$1,$3,LIB),$(LIBS))) -Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(CMN_LDFLAGS)

# specify what symbols to export from a dll
# target-specific: MAP
VERSION_SCRIPT = $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE, DLL, LIB
# $1 - path to target EXE,DLL,LIB
# $2 - objects
# $3 - non-empty variant: R,P,D
# target-specific: TMD, COMPILER
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: use CXX compiler instead of ld for creating shared libraries
#  - for calling C++ constructors of static objects when loading the libraries,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamq/index.html
.........................
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

# WRAP_CC_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_CC_COMPILER = $1
else
WRAP_CC_COMPILER = { { $1 -H 2>&1 && echo OK >&2; } | sed -n $(SED_DEPS_SCRIPT) 2>&1; } 3>&2 2>&1 1>&3 3>&- | grep OK > /dev/null
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
OS_APP_FLAGS := -g
else
OS_APP_FLAGS := -O
endif

# APP_FLAGS may be overridden in project makefile
APP_FLAGS := $(OS_APP_FLAGS)

# application-level defines
OS_APP_DEFINES:=

# APP_DEFINES may be overridden in project makefile
APP_DEFINES := $(OS_APP_DEFINES)

# common options for application-level C++ and C compilers
# $1 - target object file
# $2 - source
# target-specific: DEFINES, INCLUDE, COMPILER
CC_PARAMS = -c $(APP_FLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(APP_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - aux flags
# target-specific: TMD, CXXFLAGS, CFLAGS
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_CC_COMPILER,$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXFLAGS) $3 -o $1 $2,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  = $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_CC_COMPILER,$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(CFLAGS) $3 -o $1 $2,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

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
OS_KRN_FLAGS := -g
else
OS_KRN_FLAGS := -O
endif

# KRN_FLAGS may be overridden in project makefile
KRN_FLAGS := $(OS_KRN_FLAGS)

# kernel-level defines
OS_KRN_DEFINES:=

# KRN_DEFINES may be overridden in project makefile
KRN_DEFINES = $(OS_KRN_DEFINES)

# common options for kernel-level C compiler
# $1 - target object file
# $2 - source
# target-specific: DEFINES, INCLUDE, COMPILER
KCC_PARAMS = -c $(KRN_FLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(KRN_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# kernel-level C compilers
# $1 - targets object file
# $2 - source
# target-specific: CFLAGS
KLIB_R_CC = $(call SUP,KCC,$2)$(call \
  WRAP_CC_COMPILER,$(KCC) $(DEF_CFLAGS) $(KCC_PARAMS) $(CFLAGS) -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
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

# tools colors
BISON_COLOR := $(GEN_COLOR)
FLEX_COLOR  := $(GEN_COLOR)

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - EXE
# $v - R
define EXE_AUX_TEMPLATEv
$1: RPATH := $(subst $$,$$$$,$(RPATH))
$1: MAP := $2
$1: $2
endef

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - DLL
# $v - R
define DLL_AUX_TEMPLATEv
$1: MODVER := $(MODVER)
$1: RPATH := $(subst $$,$$$$,$(RPATH))
$1: MAP := $2
$1: $2
endef

# auxiliary defines for EXE or DLL
# $t - EXE or DLL
MOD_AUX_TEMPLATE1 = $(foreach v,$(call GET_VARIANTS,$t),$(call $t_AUX_TEMPLATEv,$(call FORM_TRG,$t,$v),$2))
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
NEEDED_DIRS += $4
$(STD_TARGET_VARS)
$1: $(call OBJ_RULES,CC,$(filter %.c,$2),$3,$4)
$1: $(call OBJ_RULES,CXX,$(filter %.cpp,$2),$3,$4)
$1: $(call OBJ_RULES,ASM,$(filter %.asm,$2),$3,$4)
$1: COMPILER   := $(TRG_COMPILER)
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
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX TCC TCXX AR TAR KCC KLD YASMC FLEXC BISONC YASM_FLAGS \
  KLIB_NAME_PREFIX DEF_SHARED_FLAGS DEF_SHARED_LIBS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE RPATH_OPTION DEF_C_LIBS DEF_CXX_LIBS CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION \
  EXE_R_LD DLL_R_LD LIB_R_LD LIB_D_LD KLIB_R_LD DRV_R_LD \
  UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT WRAP_CC_COMPILER \
  DEF_CXXFLAGS DEF_CFLAGS OS_APP_FLAGS APP_FLAGS OS_APP_DEFINES APP_DEFINES CC_PARAMS CMN_CXX CMN_CC \
  PIC_OPTION EXE_R_CXX EXE_R_CC LIB_R_CXX LIB_R_CC DLL_R_CXX DLL_R_CC LIB_D_CXX LIB_D_CC \
  KDEPS_INCLUDE_FILTER OS_KRN_FLAGS KRN_FLAGS OS_KRN_DEFINES KRN_DEFINES \
  KCC_PARAMS KLIB_R_CC DRV_R_CC KLIB_R_ASM DRV_R_ASM BISON FLEX BISON_COLOR FLEX_COLOR \
  EXE_AUX_TEMPLATEv=t;v DLL_AUX_TEMPLATEv=t;v MOD_AUX_TEMPLATE1=t MOD_AUX_TEMPLATE=t DRV_TEMPLATE=DRV;LIB_DIR;KLIBS;SYSLIBS;SYSLIBPATH;v)
