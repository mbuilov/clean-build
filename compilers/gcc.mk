#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# define INST_RPATH, RPATH and MAP variables
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# compilers/linkers
CC   := gcc -m$(if $(CPU:%64=),32,64)
CXX  := g++ -m$(if $(CPU:%64=),32,64)
AR   := ar

# tools compilers/linkers
TCC  := gcc -m$(if $(TCPU:%64=),32,64)
TCXX := g++ -m$(if $(TCPU:%64=),32,64)
TAR  := $(AR)

# prefix for passing options from gcc command line to the linker
WLPREFIX := -Wl,

# position-independent code for executables/shared objects (dynamic libraries)
PIC_COPTION := -fpic
PIE_COPTION := -fpie
PIE_LOPTION := -pie

# supported variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - PIE - position-independent code in executables (for EXE and LIB)
# D - PIC - position-independent code in shared libraries (for LIB)
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_SUPPORTED_VARIANTS := P
LIB_SUPPORTED_VARIANTS := P D

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX := _pie

# two non-regular variants of LIB are supported: P and D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - P or D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_SUFFIX = $(if $(findstring P,$1),_pie,_pic)

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - R or P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_COPTS   = $(if $(findstring P,$1),$(PIE_COPTION))
EXE_VARIANT_CXXOPTS = $(EXE_VARIANT_COPTS)
EXE_VARIANT_LOPTS   = $(if $(findstring P,$1),$(PIE_LOPTION))

# two non-regular variants of LIB are supported: P and D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - R, P or D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_COPTS   = $(if $(findstring P,$1),$(PIE_COPTION),$(if $(findstring D,$1),$(PIC_COPTION)))
LIB_VARIANT_CXXOPTS = $(LIB_VARIANT_COPTS)

# user-modifiable gcc flags for linking executables and shared libraries
LDFLAGS := $(if $(DEBUG),-ggdb,-O)

# common gcc flags for linking executables and shared libraries
CMN_LDFLAGS := -Wl,--no-demangle -Wl,--warn-common

# gcc flags for linking an EXE
EXE_LDFLAGS:=

# gcc flags for linking a DLL
DLL_LDFLAGS := -shared -Wl,--no-undefined

# flags for objects archiver
ARFLAGS := -crs

# how to mark symbols exported from a DLL
DLL_EXPORTS_DEFINE := "__attribute__((visibility(\"default\")))"

# how to mark symbols imported from a DLL
DLL_IMPORTS_DEFINE:=

# option for specifying dynamic linker runtime search path for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix $(WLPREFIX)-rpath=,$(strip $(RPATH)))

# link-time path to search for shared libraries
RPATH_LINK:=

# option for specifying link-time search path for linking an EXE or DLL
# target-specific: RPATH_LINK
RPATH_LINK_OPTION = $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK))

# gcc option to use pipe for communication between the various stages of compilation
PIPE_OPTION := -pipe

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target: EXE or DLL
# $4 - non-empty variant: R,P,D
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, LOPTS
CMN_LIBS = -pipe -o $1 $2 $(RPATH_OPTION) $(RPATH_LINK_OPTION) $(if $(firstword \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),$(WLPREFIX)-Bstatic $(addprefix -l,$(addsuffix \
  $(call DEP_SUFFIX,$3,$4,LIB),$(LIBS))) $(WLPREFIX)-Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(CMN_LDFLAGS)

# specify what symbols to export from a dll
# target-specific: MAP
VERSION_SCRIPT = $(addprefix $(WLPREFIX)--version-script=,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix $(WLPREFIX)-soname=$(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE, DLL, LIB
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, COMPILER
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_LD = $(call SUP,$(TMD)EXE,$1)$($(TMD)$(COMPILER)) $(CMN_LIBS) $(EXE_LDFLAGS) $(LOPTS) $(LDFLAGS)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$($(TMD)$(COMPILER)) $(VERSION_SCRIPT) $(SONAME_OPTION) $(CMN_LIBS) $(DLL_LDFLAGS) $(LOPTS) $(LDFLAGS)
LIB_LD = $(call SUP,$(TMD)LIB,$1)$($(TMD)AR) $(ARFLAGS) $1 $2

# flags for auto-dependencies generation
AUTO_DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)

# user-modifiable C/C++ compiler flags
CFLAGS   := $(if $(DEBUG),-ggdb,-g -O2)
CXXFLAGS := $(CFLAGS)

# common flags for application-level C/C++-compilers
CMN_CFLAGS := -Wall -fvisibility=hidden

# default flags for application-level C compiler
DEF_CFLAGS := -std=c99 -pedantic $(CMN_CFLAGS)

# default flags for application-level C++ compiler
DEF_CXXFLAGS := $(CMN_CFLAGS)

# application-level defines
APP_DEFINES := _GNU_SOURCE

# common options for application-level C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: DEFINES, INCLUDE, COMPILER
CC_PARAMS = -pipe -c $(AUTO_DEPS_FLAGS) $(call \
  DEFINES_ESCAPE_STRING,$(addprefix -D,$(APP_DEFINES) $(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: TMD, CXXOPTS, COPTS
CMN_CXX = $(call SUP,$(TMD)CXX,$2)$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $2 $(CXXFLAGS)
CMN_CC  = $(call SUP,$(TMD)CC,$2)$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS)

# compilers for each variant of EXE, DLL, LIB
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
EXE_CXX = $(CMN_CXX)
EXE_CC  = $(CMN_CC)
DLL_CXX = $(CMN_CXX)
DLL_CC  = $(CMN_CC)
LIB_CXX = $(CMN_CXX)
LIB_CC  = $(CMN_CC)

ifndef NO_PCH

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin GCC_PCH_TEMPLATEt)))
include $(dir $(lastword $(MAKEFILE_LIST)))gcc_pch.mk
endif

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# note: $(basename $(notdir $(PCH)))_pch_cxx.h and $(basename $(notdir $(PCH)))_pch_c.h files are virtual (i.e. do not exist)
# target-specific: CXX_WITH_PCH, CC_WITH_PCH, TMD, PCH, CXXOPTS, COPTS
CMN_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(call SUP,$(TMD)PCXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_cxx.h,$(call SUP,$(TMD)CXX,$2)$($(TMD)CXX)) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $2 $(CXXFLAGS)
CMN_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(call SUP,$(TMD)PCC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,$(TMD)CC,$2)$($(TMD)CC)) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS)

# compilers of C/C++ precompiled header
# $1 - target .gch (e.g. /build/obj/xxx_pch_c.h.gch or /build/obj/xxx_pch_cxx.h.gch)
# $2 - source pch header (full path, e.g. /src/include/xxx.h)
# $3 - non-empty variant: R,P,D
# target-specific: TMD, CXXOPTS, COPTS
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $2 $(CXXFLAGS)
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS)

# different precompiled header compilers
# note: used by GCC_PCH_RULE_TEMPL macro from $(CLEAN_BUILD_DIR)/compilers/gcc_pch.mk
PCH_EXE_CXX = $(PCH_CXX)
PCH_EXE_CC  = $(PCH_CC)
PCH_DLL_CXX = $(PCH_CXX)
PCH_DLL_CC  = $(PCH_CC)
PCH_LIB_CXX = $(PCH_CXX)
PCH_LIB_CC  = $(PCH_CC)

# reset additional variables
# PCH - either absolute or makefile-related path to header to precompile
$(call append_simple,C_PREPARE_APP_VARS,$(newline)PCH:=)

# for all application-level targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(GCC_PCH_TEMPLATEt)))))

endif # !NO_PCH

# for DLL:         define target-specific variable MODVER
# for DLL and EXE: define target-specific variables RPATH and MAP
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(UNIX_MOD_AUX_APP)))

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CC CXX AR TCC TCXX TAR WLPREFIX \
  PIC_COPTION PIE_COPTION PIE_LOPTION LDFLAGS CMN_LDFLAGS EXE_LDFLAGS DLL_LDFLAGS ARFLAGS \
  DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE RPATH_OPTION RPATH_LINK RPATH_LINK_OPTION CMN_LIBS VERSION_SCRIPT SONAME_OPTION \
  EXE_LD DLL_LD LIB_LD AUTO_DEPS_FLAGS CFLAGS CXXFLAGS CMN_CFLAGS DEF_CFLAGS DEF_CXXFLAGS APP_DEFINES \
  CC_PARAMS CMN_CXX CMN_CC EXE_CXX EXE_CC DLL_CXX DLL_CC LIB_CXX LIB_CC \
  PCH_CXX PCH_CC PCHCC_COLOR PCHCXX_COLOR TPCHCC_COLOR TPCHCXX_COLOR \
  PCH_EXE_CXX PCH_EXE_CC PCH_DLL_CXX PCH_DLL_CC PCH_LIB_CXX PCH_LIB_CC)
