#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc compiler toolchain (app-level), included by $(CLEAN_BUILD_DIR)/impl/_c.mk

# common suncc compiler definitions
ifeq (,$(filter-out undefined environment,$(origin SED_DEPS_SCRIPT)))
include $(dir $(lastword $(MAKEFILE_LIST)))suncc_cmn.mk
endif

# define RPATH and target-specific MAP and MODVER (for DLLs) variables
include $(dir $(lastword $(MAKEFILE_LIST)))unixcc.mk

# target compilers/linkers
CC  := cc
CXX := CC
AR  := /usr/ccs/bin$(if $(TCPU:x86_64=),,/amd64)/ar

# native compilers/linkers to use for build tools
TCC  := $(CC)
TCXX := $(CXX)
TAR  := $(AR)

# how to mark symbols exported from a DLL
# note: override definition in $(CLEAN_BUILD_DIR)/impl/_c.mk
DLL_EXPORTS_DEFINE := $(call DEFINE_SPECIAL,__attribute__((visibility("default"))))

# default values of user-defined C/C++ compiler flags
# note: may be taken from the environment in project configuration makefile
CFLAGS   := $(if $(DEBUG),-g,-fast)
CXXFLAGS := $(CFLAGS)

# compiler options for 64-bit target
# note: about '-xport64' option see https://docs.oracle.com/cd/E19205-01/819-5267/bkbgj/index.html
CPU64_COPTIONS   := -xarch=sse2
CPU64_CXXOPTIONS := $(CPU64_COPTIONS) -xport64

# cc flags to compile/link for selected CPU
CPU_CFLAGS   := -m$(if $(CPU:%64=),32,64 $(CPU64_COPTIONS))
CPU_CXXFLAGS := -m$(if $(CPU:%64=),32,64 $(CPU64_CXXOPTIONS))

# flags for objects archiver
# note: may be taken from the environment in project configuration makefile
# note: for handling C++ templates, CC compiler is used to create C++ static libraries
ARFLAGS     := -c -r
CXX_ARFLAGS := -xar

# default values of user-defined cc flags for linking executables and shared libraries
# note: may be taken from the environment in project configuration makefile
# '-xs' - allows debugging by dbx after deleting object (.o) files
LDFLAGS := $(if $(DEBUG),-xs)

# flags for the tool mode
TCFLAGS       := $(CFLAGS)
TCXXFLAGS     := $(CXXFLAGS)
TCPU_CFLAGS   := -m$(if $(TCPU:%64=),32,64 $(CPU64_COPTIONS))
TCPU_CXXFLAGS := -m$(if $(TCPU:%64=),32,64 $(CPU64_CXXOPTIONS))
TARFLAGS      := $(ARFLAGS)
TCXX_ARFLAGS  := $(CXX_ARFLAGS)
TLDFLAGS      := $(LDFLAGS)

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
# $1 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX := _pie

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_SUFFIX := _pic

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - R or P
# $(TMD) - T in tool mode, empty otherwise
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_CFLAGS   = $(if $(findstring P,$1),$(PIC_COPTION)) $($(TMD)CFLAGS)
EXE_CXXFLAGS = $(if $(findstring P,$1),$(PIC_COPTION)) $($(TMD)CXXFLAGS)
EXE_LDFLAGS  = $(if $(findstring P,$1),$(PIE_LOPTION)) $($(TMD)LDFLAGS)

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - R or D
# $(TMD) - T in tool mode, empty otherwise
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_CFLAGS   = $(if $(findstring D,$1),$(PIC_COPTION)) $($(TMD)CFLAGS)
LIB_CXXFLAGS = $(if $(findstring D,$1),$(PIC_COPTION)) $($(TMD)CXXFLAGS)

# determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib
# note: if returns empty value - then assume it's default variant R
# use D-variant of static library for pie-EXE or regular DLL
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_DEP_MAP = $(if $(findstring DLL,$1)$(findstring P,$2),D)

# make linker command for linking EXE, DLL or LIB
# target-specific: TMD, COMPILER, VCFLAGS, VCXXFLAGS
GET_LINKER = $($(TMD)$(COMPILER)) $(if $(COMPILER:CXX=),$($(TMD)CPU_CFLAGS) $(VCFLAGS),$($(TMD)CPU_CXXFLAGS) $(VCXXFLAGS))

# option for specifying dynamic linker runtime search path for EXE or DLL
# possibly target-specific: RPATH
MK_RPATH_OPTION = $(addprefix -R,$(strip $(RPATH)))

# cc options to begin the list of static/dynamic libraries to link to the target
BSTATIC_OPTION  := -Bstatic
BDYNAMIC_OPTION := -Bdynamic

# common cc flags for linking executables and shared libraries
# tip: may use -filt=%none to not demangle C++ names
CMN_LDFLAGS := -ztext

# cc flags for linking an EXE
DEF_EXE_LDFLAGS := $(CMN_LDFLAGS)

# cc flags for linking a DLL
DEF_DLL_LDFLAGS := -G -zdefs $(CMN_LDFLAGS)

# common linker options for EXE or DLL
# $1 - path to target EXE or DLL
# $2 - objects
# $3 - target: EXE or DLL
# $4 - non-empty variant: R,P,D
# target-specific: LIBS, DLLS, LIB_DIR
CMN_LIBS = -o $1 $2 $(MK_RPATH_OPTION) $(if $(firstword \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),$(BSTATIC_OPTION) $(addprefix \
  -l,$(addsuffix $(call DEP_SUFFIX,$3,$4,LIB),$(LIBS))) $(BDYNAMIC_OPTION)))

# specify what symbols to export from a dll
# target-specific: MAP
MK_MAP_OPTION = $(addprefix -M,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
MK_SONAME_OPTION = $(addprefix -h $(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# linkers for each variant of EXE,DLL,LIB
# $1 - path to target EXE,DLL,LIB
# $2 - objects for linking the target
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, VLDFLAGS
# note: used by EXE_TEMPLATE, DLL_TEMPLATE, LIB_TEMPLATE from $(CLEAN_BUILD_DIR)/impl/_c.mk
# note: use CXX compiler instead of ld to create shared libraries
#  - for calling C++ constructors of static objects when loading the libraries,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamq/index.html
# note: use CXX compiler instead of ar to create C++ static library archives
#  - for adding necessary C++ templates to the archives,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamp/index.html
EXE_LD = $(call SUP,$(TMD)EXE,$1)$(GET_LINKER) $(CMN_LIBS) $(DEF_EXE_LDFLAGS) $(VLDFLAGS)
DLL_LD = $(call SUP,$(TMD)DLL,$1)$(GET_LINKER) $(MK_MAP_OPTION) $(MK_SONAME_OPTION) $(CMN_LIBS) $(DEF_DLL_LDFLAGS) $(VLDFLAGS)
LIB_LD = $(call SUP,$(TMD)LIB,$1)$(if $(COMPILER:CXX=),$($(TMD)AR) $($(TMD)ARFLAGS) $1 $2,$(GET_LINKER) $(CXX_ARFLAGS) -o $1 $2)

# prefix of system headers to filter-out while dependencies generation
# note: used as $(SED) expression
UDEPS_INCLUDE_FILTER := /usr/include/

# either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - prefixes of system includes to filter out - $(UDEPS_INCLUDE_FILTER)
ifdef NO_DEPS
WRAP_CC = $1
else
WRAP_CC = { { $1 -H 2>&1 && echo OK >&2; } | $(SED) -n $(SED_DEPS_SCRIPT) 2>&1; } 3>&2 2>&1 1>&3 3>&- | grep OK > /dev/null
endif

# common cc flags for compiling application-level C/C++ sources
CMN_CFLAGS := -v -xldscope=hidden

# default cc flags for compiling application-level C sources
DEF_CFLAGS := $(CMN_CFLAGS)

# default cc flags for compiling application-level C++ sources
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg $(CMN_CFLAGS)

# common options for application-level C/C++ compilers
# $1 - target object file
# $2 - source
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: VDEFINES, VINCLUDE
CMN_PARAMS = -c -o $1 $2 $(VDEFINES) $(VINCLUDE)

# parameters of application-level C and C++ compilers
# $1 - target object file
# $2 - source
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, VCFLAGS, VCXXFLAGS
CC_PARAMS = $($(TMD)CPU_CFLAGS) $(CMN_PARAMS) $(DEF_CFLAGS) $(VCFLAGS)
CXX_PARAMS = $($(TMD)CPU_CXXFLAGS) $(CMN_PARAMS) $(DEF_CXXFLAGS) $(VCXXFLAGS)

# C/C++ compilers for each variant of EXE,DLL,LIB
# $1 - target object file
# $2 - source
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD
# note: used by OBJ_RULES_BODY macro from $(CLEAN_BUILD_DIR)/impl/c_base.mk
OBJ_CC  = $(call SUP,$(TMD)CC,$2)$(call WRAP_CC,$($(TMD)CC) $(CC_PARAMS),$1,$(UDEPS_INCLUDE_FILTER))
OBJ_CXX = $(call SUP,$(TMD)CXX,$2)$(call WRAP_CC,$($(TMD)CXX) $(CXX_PARAMS),$1,$(UDEPS_INCLUDE_FILTER))

ifndef NO_PCH

# add support for precompiled headers

ifeq (,$(filter-out undefined environment,$(origin SUNCC_PCH_TEMPLATEt)))
include $(dir $(lastword $(MAKEFILE_LIST)))suncc_pch.mk
endif

# C/C++ compilers for compiling without precompiled header
$(eval OBJ_NCC  = $(value OBJ_CC))
$(eval OBJ_NCXX = $(value OBJ_CXX))

# C/C++ compilers for compiling using precompiled header
# $1 - target object file
# $2 - source
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: TMD, PCH, PCH_GEN_DIR
# note: sources like $(PCH_GEN_DIR)$(notdir $2).cc are generated by SUNCC_PCH_RULE_TEMPL
OBJ_PCC  = $(call SUP,$(TMD)PCC,$2)$(call WRAP_CC,$($(TMD)CC) -xpch=use:$(dir $1)$(basename $(notdir \
  $(PCH)))_c $(call CC_PARAMS,$1,$(PCH_GEN_DIR)$(notdir $2).c),$1,$(UDEPS_INCLUDE_FILTER))
OBJ_PCXX = $(call SUP,$(TMD)PCXX,$2)$(call WRAP_CC,$($(TMD)CXX) -xpch=use:$(dir $1)$(basename $(notdir \
  $(PCH)))_cc $(call CXX_PARAMS,$1,$(PCH_GEN_DIR)$(notdir $2).cc),$1,$(UDEPS_INCLUDE_FILTER))

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - target: EXE,DLL,LIB
# $4 - non-empty variant: R,P,D
# target-specific: CXX_WITH_PCH, CC_WITH_PCH
OBJ_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(OBJ_PCC),$(OBJ_NCC))
OBJ_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(OBJ_PCXX),$(OBJ_NCXX))

# compilers of C/C++ precompiled header
# $1 - target object of generated source $3:
#  /build/obj/xxx_pch_cc.o or
#  /build/obj/xxx_pch_c.o
# $2 - pch header (full path, e.g. /src/include/xxx.h)
# $3 - generated source for precompiling header $2:
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.cc or
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.c
# $4 - target: EXE,DLL,LIB
# $5 - non-empty variant: R,P,D
# target-specific: TMD
# note: pch object xxx_c.cpch or xxx_cc.Cpch will be created as a side-effect of this compilation
# note: used by SUNCC_PCH_RULE_TEMPL macro from $(CLEAN_BUILD_DIR)/compilers/suncc_pch.mk
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$(call WRAP_CC,$($(TMD)CC) -xpch=collect:$(dir $1)$(basename $(notdir \
  $2))_c $(call CC_PARAMS,$1,$3,$4,$5),$1,$(UDEPS_INCLUDE_FILTER))
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$(call WRAP_CC,$($(TMD)CXX) -xpch=collect:$(dir $1)$(basename $(notdir \
  $2))_cc $(call CXX_PARAMS,$1,$3,$4,$5),$1,$(UDEPS_INCLUDE_FILTER))

# reset additional variables
# PCH - either absolute or makefile-related path to header to precompile
$(call append_simple,C_PREPARE_APP_VARS,$(newline)PCH:=)

# for all application-level targets: add support for precompiled headers
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(SUNCC_PCH_TEMPLATEt)))))

endif # !NO_PCH

# for DLL:         define target-specific variable MODVER
# for DLL and EXE: define target-specific variables RPATH and MAP
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(UNIX_MOD_AUX_APP)))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX AR TCC TCXX TAR CFLAGS CXXFLAGS CPU64_COPTIONS CPU64_CXXOPTIONS CPU_CFLAGS CPU_CXXFLAGS \
  ARFLAGS CXX_ARFLAGS LDFLAGS TCFLAGS TCXXFLAGS TCPU_CFLAGS TCPU_CXXFLAGS TARFLAGS TCXX_ARFLAGS TLDFLAGS PIC_COPTION PIE_LOPTION \
  GET_LINKER MK_RPATH_OPTION BSTATIC_OPTION BDYNAMIC_OPTION CMN_LDFLAGS DEF_EXE_LDFLAGS DEF_DLL_LDFLAGS \
  CMN_LIBS MK_MAP_OPTION MK_SONAME_OPTION EXE_LD DLL_LD LIB_LD \
  UDEPS_INCLUDE_FILTER WRAP_CC CMN_CFLAGS DEF_CFLAGS DEF_CXXFLAGS CMN_PARAMS CC_PARAMS CXX_PARAMS \
  OBJ_CC OBJ_CXX OBJ_NCC OBJ_NCXX OBJ_PCC OBJ_PCXX PCH_CC PCH_CXX)
