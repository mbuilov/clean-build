#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# define RPATH and target-specific MAP and MODVER (for DLLs) variables
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# command prefix for cross-compilation
CROSS_PREFIX:=

# target compilers/linkers
CC  := $(CROSS_PREFIX)gcc
CXX := $(CROSS_PREFIX)g++
AR  := $(CROSS_PREFIX)ar

# native compilers/linkers to use for build tools
TCC  := $(if $(CROSS_PREFIX),gcc,$(CC))
TCXX := $(if $(CROSS_PREFIX),g++,$(CXX))
TAR  := $(if $(CROSS_PREFIX),ar,$(AR))

# default values of user-defined C/C++ compiler flags
# note: may be taken from the environment in project configuration makefile
# note: CFLAGS   - used by EXE_CFLAGS,   LIB_CFLAGS,   DLL_CFLAGS   (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
# note: CXXFLAGS - used by EXE_CXXFLAGS, LIB_CXXFLAGS, DLL_CXXFLAGS (from $(CLEAN_BUILD_DIR)/impl/_c.mk)
CFLAGS   := $(if $(DEBUG),-ggdb,-g -O2)
CXXFLAGS := $(CFLAGS)

# gcc flags to compile/link for selected CPU
CPU_CFLAGS   := -m$(if $(CPU:%64=),32,64)
CPU_CXXFLAGS := $(CPU_CFLAGS)

# flags for objects archiver
# note: may be taken from the environment in project configuration makefile
# note: used by LIB_LD
ARFLAGS := -crs

# default values of user-defined gcc flags for linking executables and shared libraries
# note: may be taken from the environment in project configuration makefile
# note: used by EXE_LDFLAGS, LIB_LDFLAGS, DLL_LDFLAGS from $(CLEAN_BUILD_DIR)/impl/_c.mk
LDFLAGS:=

# flags for the tool mode
TCFLAGS       := $(CFLAGS)
TCXXFLAGS     := $(CXXFLAGS)
TCPU_CFLAGS   := -m$(if $(TCPU:%64=),32,64)
TCPU_CXXFLAGS := $(TCPU_CFLAGS)
TARFLAGS      := $(ARFLAGS)
TLDFLAGS      := $(LDFLAGS)

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
# $(TMD) - T in tool mode, empty otherwise
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_CFLAGS   = $(if $(findstring P,$1),$(PIE_COPTION)) $($(TMD)CFLAGS)
EXE_CXXFLAGS = $(if $(findstring P,$1),$(PIE_COPTION)) $($(TMD)CXXFLAGS)
EXE_LDFLAGS  = $(if $(findstring P,$1),$(PIE_LOPTION)) $($(TMD)LDFLAGS)

# two non-regular variants of LIB are supported: P and D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - R, P or D
# $(TMD) - T in tool mode, empty otherwise
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_CFLAGS   = $(if $(findstring P,$1),$(PIE_COPTION),$(if $(findstring D,$1),$(PIC_COPTION))) $($(TMD)CFLAGS)
LIB_CXXFLAGS = $(if $(findstring P,$1),$(PIE_COPTION),$(if $(findstring D,$1),$(PIC_COPTION))) $($(TMD)CXXFLAGS)

# make linker command for linking EXE or DLL
# target-specific: TMD, COMPILER, VCFLAGS, VCXXFLAGS
GET_LINKER = $($(TMD)$(COMPILER)) $(if $(COMPILER:CXX=),$($(TMD)CPU_CFLAGS) $(VCFLAGS),$($(TMD)CPU_CXXFLAGS) $(VCXXFLAGS))

# gcc option to use pipe for communication between the various stages of compilation
PIPE_OPTION := -pipe

# prefix for passing options from gcc command line to the linker
WLPREFIX := -Wl,

# option for specifying dynamic linker runtime search path for EXE or DLL
# possibly target-specific: RPATH
MK_RPATH_OPTION = $(addprefix $(WLPREFIX)-rpath=,$(strip $(RPATH)))

# link-time path to search for shared libraries
# note: assume if needed, will be redefined as target-specific value in target makefile
RPATH_LINK:=

# option for specifying link-time search path for linking an EXE or DLL
# possibly target-specific: RPATH_LINK
MK_RPATH_LINK_OPTION = $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK))

# gcc options to begin the list of static/dynamic libraries to link to the target
BSTATIC_OPTION  := -Wl,-Bstatic
BDYNAMIC_OPTION := -Wl,-Bdynamic

# common gcc flags for linking executables and shared libraries
CMN_LDFLAGS := -Wl,--warn-common -Wl,--no-demangle

# default gcc flags for linking an EXE
DEF_EXE_LDFLAGS := $(CMN_LDFLAGS)

# default gcc flags for linking a DLL
DEF_DLL_LDFLAGS := -shared -Wl,--no-undefined $(CMN_LDFLAGS)

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target type: EXE or DLL
# $4 - non-empty variant: R,P,D
# target-specific: LIBS, DLLS, LIB_DIR
CMN_LIBS = $(PIPE_OPTION) -o $1 $2 $(MK_RPATH_OPTION) $(MK_RPATH_LINK_OPTION) $(if $(firstword \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),$(BSTATIC_OPTION) $(patsubst \
  %,-l%$(call DEP_SUFFIX,$3,$4,LIB),$(LIBS)) $(BDYNAMIC_OPTION)))

# specify what symbols to export from a dll/exe
# target-specific: MAP
MK_MAP_OPTION = $(addprefix $(WLPREFIX)--version-script=,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
MK_SONAME_OPTION = $(addprefix $(WLPREFIX)-soname=$(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE,DLL,LIB
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, VLDFLAGS
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_LD = $(call SUP,$(TMD)EXE,$1)$(GET_LINKER) $(MK_MAP_OPTION) $(CMN_LIBS) $(DEF_EXE_LDFLAGS) $(VLDFLAGS)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$(GET_LINKER) $(MK_MAP_OPTION) $(MK_SONAME_OPTION) $(CMN_LIBS) $(DEF_DLL_LDFLAGS) $(VLDFLAGS)
LIB_LD = $(call SUP,$(TMD)LIB,$1)$($(TMD)AR) $($(TMD)ARFLAGS) $1 $2

# flags for auto-dependencies generation
AUTO_DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)

# common gcc flags for compiling application-level C/C++ sources
CMN_CFLAGS := -Wall -fvisibility=hidden

# default gcc flags for compiling application-level C sources
DEF_CFLAGS := -std=c99 -pedantic $(CMN_CFLAGS)

# default gcc flags for compiling application-level C++ sources
DEF_CXXFLAGS := $(CMN_CFLAGS)

# common options for application-level C/C++ compilers
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: VDEFINES, VINCLUDE
CMN_PARAMS = $(PIPE_OPTION) -c -o $1 $2 $(AUTO_DEPS_FLAGS) $(VDEFINES) $(VINCLUDE)

# parameters of application-level C and C++ compilers
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, VCFLAGS, VCXXFLAGS
CC_PARAMS  = $($(TMD)CPU_CFLAGS) $(CMN_PARAMS) $(DEF_CFLAGS) $(VCFLAGS)
CXX_PARAMS = $($(TMD)CPU_CXXFLAGS) $(CMN_PARAMS) $(DEF_CXXFLAGS) $(VCXXFLAGS)

# C/C++ compilers for each variant of EXE,DLL,LIB
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
OBJ_CC  = $(call SUP,$(TMD)CC,$2)$($(TMD)CC) $(CC_PARAMS)
OBJ_CXX = $(call SUP,$(TMD)CXX,$2)$($(TMD)CXX) $(CXX_PARAMS)

ifndef NO_PCH

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin GCC_PCH_TEMPLATEt)))
include $(dir $(lastword $(MAKEFILE_LIST)))gcc/pch.mk
endif

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# note: $(basename $(notdir $(PCH)))_pch_cxx.h and $(basename $(notdir $(PCH)))_pch_c.h files are virtual (i.e. do not exist)
# target-specific: CC_WITH_PCH, CXX_WITH_PCH, TMD, PCH
OBJ_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(call SUP,$(TMD)PCC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,$(TMD)CC,$2)$($(TMD)CC)) $(CC_PARAMS)
OBJ_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(call SUP,$(TMD)PCXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_cxx.h,$(call SUP,$(TMD)CXX,$2)$($(TMD)CXX)) $(CXX_PARAMS)

# compilers of C/C++ precompiled header
# $1 - target .gch (e.g. /build/obj/xxx_pch_c.h.gch or /build/obj/xxx_pch_cxx.h.gch)
# $2 - source pch header (full path, e.g. /src/include/xxx.h)
# $3 - target type: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD
# note: used by GCC_PCH_RULE_TEMPL macro from $(CLEAN_BUILD_DIR)/compilers/gcc/pch.mk
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(CC_PARAMS)
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(CXX_PARAMS)

# reset additional user-modifiable variables
$(call define_append,C_PREPARE_APP_VARS,$(C_PREPARE_PCH_VARS))

# optimization
$(call try_make_simple,C_PREPARE_APP_VARS,C_PREPARE_PCH_VARS)

# for all application-level targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(GCC_PCH_TEMPLATEt)))))

endif # !NO_PCH

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CROSS_PREFIX CC CXX AR TCC TCXX TAR CFLAGS CXXFLAGS CPU_CFLAGS CPU_CXXFLAGS ARFLAGS LDFLAGS \
  TCFLAGS TCXXFLAGS TCPU_CFLAGS TCPU_CXXFLAGS TARFLAGS TLDFLAGS PIC_COPTION PIE_COPTION PIE_LOPTION \
  GET_LINKER PIPE_OPTION WLPREFIX MK_RPATH_OPTION RPATH_LINK MK_RPATH_LINK_OPTION BSTATIC_OPTION BDYNAMIC_OPTION \
  CMN_LDFLAGS DEF_EXE_LDFLAGS DEF_DLL_LDFLAGS CMN_LIBS MK_MAP_OPTION MK_SONAME_OPTION \
  EXE_LD DLL_LD LIB_LD AUTO_DEPS_FLAGS CMN_CFLAGS DEF_CFLAGS DEF_CXXFLAGS \
  CMN_PARAMS CC_PARAMS CXX_PARAMS OBJ_CC OBJ_CXX PCH_CC PCH_CXX)
