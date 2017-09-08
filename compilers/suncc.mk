#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# define INST_RPATH, RPATH and MAP variables
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# compilers/linkers
# note: about '-xport64' option see https://docs.oracle.com/cd/E19205-01/819-5267/bkbgj/index.html
CC  := cc -m$(if $(CPU:%64=),32,64 -xarch=sse2)
CXX := CC -m$(if $(CPU:%64=),32,64 -xarch=sse2 -xport64)
AR  := /usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar

# tools compilers/linkers
TCC  := cc -m$(if $(TCPU:%64=),32,64 -xarch=sse2)
TCXX := CC -m$(if $(TCPU:%64=),32,64 -xarch=sse2 -xport64)
TAR  := $(AR)

# position-independent code for executables/shared objects (dynamic libraries)
PIC_COPTION := -Kpic
PIE_LOPTION := -ztype=pie

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
EXE_VARIANT_COPTS   := $(PIC_COPTION)
EXE_VARIANT_CXXOPTS := $(PIC_COPTION)
EXE_VARIANT_LOPTS   := $(PIE_LOPTION)

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - target: LIB
# $2 - D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_COPTS   := $(PIC_COPTION)
LIB_VARIANT_CXXOPTS := $(PIC_COPTION)

# determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency type: LIB
# note: if returns empty value - then assume it's default variant R
# use D-variant of static library for pie-EXE or DLL
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_DEP_MAP = $(if $(filter DLL,$1)$(filter P,$2),D)

# ld flags that may be modified by user
# note: '-xs' - allows debugging by dbx without object (.o) files
LDFLAGS := $(if $(DEBUG),-g -xs,-fast)

# common cc flags for linking executables and shared libraries
# tip: may use -filt=%none to not demangle C++ names
CMN_LDFLAGS := -ztext

# cc flags for linking an EXE
EXE_LDFLAGS:=

# cc flags for linking a DLL
DLL_LDFLAGS := -G -zdefs

# flags for objects archiver
# note: for handling C++ templates, CC compiler is used to create C++ static libraries
ARFLAGS     := -c -r
CXX_ARFLAGS := -xar

# how to mark symbols exported from a DLL
DLL_EXPORTS_DEFINE := "__attribute__((visibility(\"default\")))"

# how to mark symbols imported from a DLL
DLL_IMPORTS_DEFINE:=

# option for specifying dynamic linker runtime search path for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix -R,$(strip $(RPATH)))

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target: EXE or DLL
# $4 - non-empty variant: R,P,D
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS
CMN_LIBS = -o $1 $2 $(RPATH_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),-Bstatic $(addprefix -l,$(addsuffix \
  $(call DEP_SUFFIX,$3,$4,LIB),$(LIBS))) -Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(CMN_LDFLAGS)

# specify what symbols to export from a dll
# target-specific: MAP
VERSION_SCRIPT = $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE, DLL, LIB
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, COMPILER, LOPTS
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: use CXX compiler instead of ld to create shared libraries
#  - for calling C++ constructors of static objects when loading the libraries,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamq/index.html
EXE_LD = $(call SUP,$(TMD)EXE,$1)$($(TMD)$(COMPILER)) $(CMN_LIBS) $(EXE_LDFLAGS) $(LOPTS) $(LDFLAGS)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$($(TMD)$(COMPILER)) $(VERSION_SCRIPT) $(SONAME_OPTION) $(CMN_LIBS) $(DLL_LDFLAGS) $(LOPTS) $(LDFLAGS)
LIB_LD = $(call SUP,$(TMD)LIB,$1)$(if $(COMPILER:CXX=),$($(TMD)AR) $(ARFLAGS) $1 $2,$($(TMD)$(COMPILER)) $(CXX_ARFLAGS) -o $1 $2)

# prefix of system headers to filter-out while dependencies generation
# note: used as $(SED) expression
UDEPS_INCLUDE_FILTER := /usr/include/

# $(SED) script to generate dependencies file from C compiler output
#
# note: '-xMD' cc option generates only partial makefile-dependency .d file
#  - it doesn't include empty targets for dependency headers:
#
#  e.o: e.c
#  e.o: e.h
#  e.h:      <--- missing in generated .d file
#
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

# either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes to filter out
ifdef NO_DEPS
WRAP_CC = $1
else
WRAP_CC = { { $1 -H 2>&1 && echo OK >&2; } | sed -n $(SED_DEPS_SCRIPT) 2>&1; } 3>&2 2>&1 1>&3 3>&- | grep OK > /dev/null
endif

# C/C++ compiler flags that may be modified by user
CFLAGS   := $(if $(DEBUG),-g,-fast)
CXXFLAGS := $(CFLAGS)

# common flags for application-level C/C++-compilers
CMN_CFLAGS := -v -xldscope=hidden

# default flags for application-level C compiler
DEF_CFLAGS := $(CMN_CFLAGS)

# default flags for application-level C++ compiler
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg $(CMN_CFLAGS)

# application-level defines
APP_DEFINES:=

# common options for application-level C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: DEFINES, INCLUDE, COMPILER
CC_PARAMS = -c $(call \
  DEFINES_ESCAPE_STRING,$(addprefix -D,$(APP_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: TMD, CXXOPTS, COPTS
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_CC,$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $2 $(CXXFLAGS),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  = $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_CC,$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# compilers for each variant of EXE, DLL, LIB
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
EXE_CXX = $(CMN_CXX)
EXE_CC  = $(CMN_CC)
DLL_CXX = $(CMN_CXX)
DLL_CC  = $(CMN_CC)
LIB_CXX = $(CMN_CXX)
LIB_CC  = $(CMN_CC)

ifndef NO_PCH

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin SUNCC_PCH_TEMPLATEt)))
include $(dir $(lastword $(MAKEFILE_LIST)))suncc_pch.mk
endif

# C/C++ compilers for compiling without precompiled header
$(eval CMN_NCXX = $(value CMN_CXX))
$(eval CMN_NCC  = $(value CMN_CC))

# C/C++ compilers for compiling using precompiled header
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: TMD, PCH, CXXOPTS, COPTS
CMN_PCXX = $(call SUP,$(TMD)PCXX,$2)$(call \
  WRAP_CC,$($(TMD)CXX) -xpch=use:$(dir $1)$(basename $(notdir $(PCH)))_cxx \
  $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $(dir $1)$(notdir \
  $2).pch.cc $(CXXFLAGS),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

CMN_PCC  = $(call SUP,P$(TMD)CC,$2)$(call \
  WRAP_CC,$($(TMD)CC) -xpch=use:$(dir $1)$(basename $(notdir $(PCH)))_c \
  $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $(dir $1)$(notdir \
  $2).pch.c $(CFLAGS),$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: CXX_WITH_PCH, CC_WITH_PCH
CMN_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(CMN_PCXX),$(CMN_NCXX))
CMN_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(CMN_PCC),$(CMN_NCC))

# compilers for C++ and C precompiled header
# $1 - target object of generated source $3
# $2 - pch header (full path, e.g. /src/include/xxx.h)
# $3 - generated source to precompile header $2:
#  $(dir $1)$(basename $(notdir $2))_cxx.cc or
#  $(dir $1)$(basename $(notdir $2))_c.c
# $4 - non-empty variant: R,P,D
# target-specific: TMD, CXXOPTS, COPTS
# note: pch object xxx_c.cpch or xxx_cxx.Cpch will be created as a side-effect of this compilation
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$(call \
  WRAP_CC,$($(TMD)CXX) -xpch=collect:$(dir $1)$(basename $(notdir $2))_cxx \
  $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $3 $(CXXFLAGS),$1,$3,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

PCH_CC = $(call SUP,$(TMD)PCHCC,$2)$(call \
  WRAP_CC,$($(TMD)CC) -xpch=collect:$(dir $1)$(basename $(notdir $2))_c \
  $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $3 $(CFLAGS),$1,$3,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))





# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $(basename $2).d
# $5 - prefixes of system includes to filter out

1) create fake source gg/1.c:
  #include "../ff/../1.h"
  #pragma hdrstop
2) compile it 
  cc -xpch=collect:ff/1_c -c -o ff/1.o gg/1.c
3) generate source gg/2.tmp.c:
  #include "../ff/../1.h"
  #pragma hdrstop
  #include "../2.c"
4) compile it
  cc -xpch=use:ff/1_c -c -o ff/2.o gg/2.tmp.c

PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS)


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

# static library archiver
# target-specific: COMPILER
# note: use CXX compiler instead of ar to create C++ static library archives
#  - for adding necessary C++ templates to the archives,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamp/index.html
AR  = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar,$(CXX))
TAR = $(if $(COMPILER:CXX=),/usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar,$(TCXX))

