#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# global variable: INST_RPATH - location where to search for external dependency libraries on runtime: /opt/lib or $ORIGIN/../lib
# note: INST_RPATH may be overridden either in project configuration makefile or in command line
INST_RPATH:=

# reset additional variables at beginning of target makefile
# RPATH - runtime path for dynamic linker to search for shared libraries
# MAP   - linker map file (used mostly to list exported symbols)
define C_PREPARE_GCC_APP_VARS
RPATH := $(INST_RPATH)
MAP:=
endef

# optimization
$(call try_make_simple,C_PREPARE_GCC_APP_VARS,INST_RPATH)

# patch code executed at beginning of target makefile
$(call define_append,C_PREPARE_APP_VARS,$(newline)$$(C_PREPARE_GCC_APP_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_GCC_APP_VARS)

# compilers/linkers
CC   := gcc -m$(if $(CPU:%64=),32,64)
CXX  := g++ -m$(if $(CPU:%64=),32,64)
LD   := ld$(if $(CPU:x86%=),, -m$(if $(CPU:%64=),elf_i386,elf_x86_64))
AR   := ar

# tools compilers/linkers
TCC  := gcc -m$(if $(TCPU:%64=),32,64)
TCXX := g++ -m$(if $(TCPU:%64=),32,64)
TLD  := ld$(if $(TCPU:x86%=),, -m$(if $(TCPU:%64=),elf_i386,elf_x86_64))
TAR  := ar

# prefix for passing options from gcc command line to the linker
WLPREFIX := -Wl,

# position-independent code for executables/shared objects (dynamic libraries)
PIC_CC_OPTION := -fpic
PIE_CC_OPTION := -fpie
PIE_LD_OPTION := -pie

# supported variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - position-independent code in executables (for EXE and LIB)
# D - position-independent code in shared libraries (for LIB)
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_NON_REGULAR_VARIANTS := P
LIB_NON_REGULAR_VARIANTS := P D

# only one non-regular variant of EXE is supported - P
# $1 - target: EXE
# $2 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX := _pie

# two non-regular variants of LIB are supported: P and D
# $1 - target: LIB
# $2 - P or D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_SUFFIX = $(if $(filter P,$2),_pie,_pic)

# only one non-regular variant of EXE is supported - P
# $1 - target: EXE
# $2 - P
EXE_VARIANT_DEFINES  :=
EXE_VARIANT_CFLAGS   := $(PIE_CC_OPTION)
EXE_VARIANT_CXXFLAGS := $(PIE_CC_OPTION)
EXE_VARIANT_LDFLAGS  := $(PIE_LD_OPTION)

# two non-regular variants of LIB are supported: P and D
# $1 - target: EXE
# $2 - P or D
LIB_VARIANT_DEFINES  :=
LIB_VARIANT_CFLAGS   = $(if $(filter P,$2),$(PIE_CC_OPTION),$(PIC_CC_OPTION))
LIB_VARIANT_CXXFLAGS = $(if $(filter P,$2),$(PIE_CC_OPTION),$(PIC_CC_OPTION))
LIB_VARIANT_LDFLAGS  :=

# default shared libs for target executables and shared libraries
SHARED_DEF_LIBS:=

# default flags for shared objects (executables and shared libraries)
SHARED_DEF_FLAGS := -Wl,--warn-common -Wl,--no-demangle

# default flags for EXE-target linker
EXE_DEF_FLAGS:=

# default flags for SO-target linker
SO_DEF_FLAGS := -shared -Wl,--no-undefined

# default flags for static library position-independent code linker (with -fpie or -fpic options)
LD_DEF_FLAGS := -r --warn-common

# default flags for objects archiver
AR_DEF_FLAGS := -crs

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE := "__attribute__((visibility(\"default\")))"

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE:=

# option for passing dynamic linker runtime path for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix $(WLPREFIX)-rpath=,$(strip $(RPATH)))

# link-time path to search for shared libraries
RPATH_LINK:=

# option for passing link-time path for EXE or DLL
# target-specific: RPATH_LINK
RPATH_LINK_OPTION = $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK))

# common linker options for EXE or DLL
# $1 - target EXE or DLL
# $2 - objects
# $3 - variant of the target
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, LDFLAGS
CMN_LIBS = -pipe -o $1 $2 $(SHARED_DEF_FLAGS) $(RPATH_OPTION) $(RPATH_LINK_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),$(WLPREFIX)-Bstatic $(addprefix -l,$(addsuffix \
  $(call DEPENDENCY_SUFFIX,$1,$3,LIB),$(LIBS))) $(WLPREFIX)-Bdynamic)) $(addprefix \
  -L,$(SYSLIBPATH)) $(SYSLIBS) $(SHARED_DEF_LIBS) $(LDFLAGS)

# specify what symbols to export from a dll
# target-specific: MAP
VERSION_SCRIPT_OPTION = $(addprefix $(WLPREFIX)--version-script=,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix $(WLPREFIX)-soname=$(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE, DLL, LIB
# $1 - target EXE,DLL,LIB
# $2 - objects
# target variants: R,P,D
# target-specific: TMD, COMPILER
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_R_LD = $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(EXE_DEF_FLAGS) $(call CMN_LIBS,$1,$2,R)
EXE_P_LD = $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(EXE_DEF_FLAGS) $(call CMN_LIBS,$1,$2,P)
DLL_R_LD = $(call SUP,$(TMD)SLD,$1)$($(TMD)$(COMPILER)) $(SO_DEF_FLAGS) $(VERSION_SCRIPT_OPTION) $(SONAME_OPTION) $(call CMN_LIBS,$1,$2,R)
LIB_R_LD = $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(AR_DEF_FLAGS) $1 $2
LIB_P_LD = $(call SUP,$(TMD)LD,$1)$($(TMD)LD) $(LD_DEF_FLAGS) -o $1 $2 $(LDFLAGS)
LIB_D_LD = $(LIB_P_LD)

# flags for auto-dependencies generation
AUTO_DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)

# default flags for application-level C++ compiler
DEF_CXXFLAGS:=

# default flags for application-level C compiler
DEF_CFLAGS := -std=c99 -pedantic

# flags for application-level C/C++-compiler
DEF_APP_FLAGS := -Wall -fvisibility=hidden
ifdef DEBUG
DEF_APP_FLAGS += -ggdb
else
DEF_APP_FLAGS += -g -O2
endif

# APP_FLAGS may be overridden in project makefile
APP_FLAGS := $(DEF_APP_FLAGS)

# application-level defines
DEF_APP_DEFINES := _GNU_SOURCE

# APP_DEFINES may be overridden in project makefile
APP_DEFINES := $(DEF_APP_DEFINES)

# common options for application-level C++ and C compilers
# $1 - target object file
# $2 - source
# target-specific: DEFINES, INCLUDE, COMPILER
CC_PARAMS = -pipe -c $(APP_FLAGS) $(AUTO_DEPS_FLAGS) $(call \
  DEFINES_ESCAPE_STRING,$(addprefix -D,$(APP_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - compiler name
# target-specific: TMD, CXXFLAGS, CFLAGS
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXFLAGS) -o $1 $2
CMN_CC  = $(call SUP,$(TMD)CC,$2)$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(CFLAGS) -o $1 $2

# compilers for each variant of EXE, DLL, LIB
# $1 - target object file
# $2 - source
# target variants: R,P,D
# note: used by OBJ_RULES from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_R_CXX = $(CMN_CXX)
EXE_R_CC  = $(CMN_CC)
EXE_P_CXX = $(CMN_CXX)
EXE_P_CC  = $(CMN_CC)
DLL_R_CXX = $(CMN_CXX) $(PIC_CC_OPTION)
DLL_R_CC  = $(CMN_CC) $(PIC_CC_OPTION)
LIB_R_CXX = $(EXE_R_CXX) ??????????
LIB_R_CC  = $(EXE_R_CC)
LIB_P_CXX = $(EXE_P_CXX)
LIB_P_CC  = $(EXE_P_CC)
LIB_D_CXX = $(DLL_R_CXX)
LIB_D_CC  = $(DLL_R_CC)

ifndef NO_PCH

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin GCC_PCH_TEMPLATEt)))
include $(dir $(lastword $(MAKEFILE_LIST)))gcc_pch.mk
endif

# override C++ and C compilers to support precompiled headers
# $1 - target object file
# $2 - source
# $3 - compiler name
# target-specific: CXX_WITH_PCH, CC_WITH_PCH, TMD, PCH, CXXFLAGS, CFLAGS
CMN_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(call SUP,P$(TMD)CXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_cxx.h,$(call SUP,$(TMD)CXX,$2)$($(TMD)CXX)) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXFLAGS) -o $1 $2
CMN_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(call SUP,P$(TMD)CC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,$(TMD)CC,$2)$($(TMD)CC)) $(DEF_CFLAGS) $(CC_PARAMS) $(CFLAGS) -o $1 $2

# compilers for C++ and C precompiled header
# $1 - target .gch
# $2 - source
# target-specific: CXXFLAGS, CFLAGS
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXFLAGS) -o $1 $2
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(CFLAGS) -o $1 $2

# tools colors
PCHCC_COLOR   := $(CC_COLOR)
PCHCXX_COLOR  := $(CXX_COLOR)
TPCHCC_COLOR  := $(PCHCC_COLOR)
TPCHCXX_COLOR := $(PCHCXX_COLOR)

# different precompiler header compilers for R,P and D target variants, used by PCH_TEMPLATEv
# $1 - target .gch
# $2 - source header
PCH_EXE_R_CXX = $(PCH_CXX)
PCH_EXE_R_CC  = $(PCH_CC)
PCH_EXE_P_CXX = $(PCH_EXE_R_CXX) $(PIE_CC_OPTION)
PCH_EXE_P_CC  = $(PCH_EXE_R_CC) $(PIE_CC_OPTION)
PCH_DLL_R_CXX = $(PCH_CXX) $(PIC_CC_OPTION)
PCH_DLL_R_CC  = $(PCH_CC) $(PIC_CC_OPTION)
PCH_LIB_R_CXX = $(PCH_EXE_R_CXX)
PCH_LIB_R_CC  = $(PCH_EXE_R_CC)
PCH_LIB_P_CXX = $(PCH_EXE_P_CXX)
PCH_LIB_P_CC  = $(PCH_EXE_P_CC)
PCH_LIB_D_CXX = $(PCH_DLL_R_CXX)
PCH_LIB_D_CC  = $(PCH_DLL_R_CC)

# reset additional variables
# PCH - either absolute or makefile-related path to header to precompile
$(call append_simple,C_PREPARE_APP_VARS,$(newline)PCH:=)

# for all targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(GCC_PCH_TEMPLATEt)))))

endif # NO_PCH

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - EXE
# $v - R
# note: last line must be empty
define EXE_AUX_TEMPLATEv
$1:RPATH := $$(RPATH)
$1:MAP := $2
$1:$2

endef

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(MAP))
# $t - DLL
# $v - R
# note: last line must be empty
define DLL_AUX_TEMPLATEv
$1:MODVER := $(MODVER)
$1:RPATH := $$(RPATH)
$1:MAP := $2
$1:$2

endef

# auxiliary defines for EXE or DLL
# $1 - $(call fixpath,$(MAP))
# $t - EXE or DLL
MOD_AUX_APPt = $(foreach v,$(call GET_VARIANTS,$t),$(call $t_AUX_TEMPLATEv,$(call FORM_TRG,$t,$v),$1))

# for DLL:         define target-specific variable MODVER
# for DLL and EXE: define target-specific variables RPATH and MAP
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,EXE DLL,$$(if $$($$t),$$(call MOD_AUX_APPt,$$(call fixpath,$$(MAP)))))))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,INST_RPATH C_PREPARE_GCC_APP_VARS CC CXX LD AR TCC TCXX TLD TAR \
  WLPREFIX PIE_CC_OPTION PIC_CC_OPTION SHARED_DEF_LIBS SHARED_DEF_FLAGS EXE_DEF_FLAGS SO_DEF_FLAGS LD_DEF_FLAGS AR_DEF_FLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE RPATH_OPTION RPATH_LINK RPATH_LINK_OPTION CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION \
  EXE_R_LD EXE_P_LD DLL_R_LD LIB_R_LD LIB_P_LD LIB_D_LD AUTO_DEPS_FLAGS DEF_CXXFLAGS DEF_CFLAGS \
  DEF_APP_FLAGS APP_FLAGS DEF_APP_DEFINES APP_DEFINES CC_PARAMS CMN_CXX CMN_CC \
  EXE_R_CXX EXE_R_CC EXE_P_CXX EXE_P_CC DLL_R_CXX DLL_R_CC LIB_R_CXX LIB_R_CC LIB_P_CXX LIB_P_CC LIB_D_CXX LIB_D_CC \
  NO_PCH PCH_CXX PCH_CC PCHCC_COLOR PCHCXX_COLOR TPCHCC_COLOR TPCHCXX_COLOR PCH_EXE_R_CXX PCH_EXE_R_CC PCH_EXE_P_CXX \
  PCH_EXE_P_CC PCH_DLL_R_CXX PCH_DLL_R_CC PCH_LIB_R_CXX PCH_LIB_R_CC PCH_LIB_P_CXX PCH_LIB_P_CC \
  PCH_LIB_D_CXX PCH_LIB_D_CC EXE_AUX_TEMPLATEv=t;v DLL_AUX_TEMPLATEv=t;v MOD_AUX_APPt=t)
