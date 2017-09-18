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
# $1 - P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_SUFFIX := _pie

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_SUFFIX := _pic

# only one non-regular variant of EXE is supported - P - see $(EXE_SUPPORTED_VARIANTS)
# $1 - R or P
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
EXE_VARIANT_COPTS   = $(if $(findstring P,$1),$(PIC_COPTION))
EXE_VARIANT_CXXOPTS = $(EXE_VARIANT_COPTS)
EXE_VARIANT_LOPTS   = $(if $(findstring P,$1),$(PIE_LOPTION))

# only one non-regular variant of LIB is supported - D - see $(LIB_SUPPORTED_VARIANTS)
# $1 - R or D
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_VARIANT_COPTS   = $(if $(findstring D,$1),$(PIC_COPTION))
LIB_VARIANT_CXXOPTS = $(LIB_VARIANT_COPTS)

# determine which variant of static library to link with EXE or DLL
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P, if empty, then assume R
# $3 - dependency name, e.g. mylib
# note: if returns empty value - then assume it's default variant R
# use D-variant of static library for pie-EXE or regular DLL
# note: override defaults from $(CLEAN_BUILD_DIR)/impl/_c.mk
LIB_DEP_MAP = $(if $(findstring DLL,$1)$(findstring P,$2),D)

# cc linking flags modifiable by user
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
# note: use CXX compiler instead of ar to create C++ static library archives
#  - for adding necessary C++ templates to the archives,
#  see https://docs.oracle.com/cd/E19205-01/819-5267/bkamp/index.html
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
# $4 - $2.d
# $5 - prefixes of system includes to filter out

# /^$(tab)*\//!{p;d;}           - print all lines not started with optional tabs and /, start new circle
# s/^\$(tab)*//;                - strip-off leading tabs
# $(foreach x,$5,\@^$x.*@d;)    - delete lines started with system include paths, start new circle
# s@.*@&:\$(newline)$2: &@;w $4 - make dependencies, then write to generated dep-file

CC_GEN_DEPS_COMMAND = $(SED) -n \
-e '/^$(tab)*\//!{p;d;}' \
-e 's/^\$(tab)*//;$(foreach x,$5,\@^$x.*@d;)s@.*@&:\$(newline)$2: &@;w $4'

# either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options
# $2 - target object file
# $3 - source
# $4 - $2.d
# $5 - prefixes of system includes to filter out
ifdef NO_DEPS
WRAP_CC = $1
else
WRAP_CC = { { $1 -H 2>&1 && echo OK >&2; } | $(CC_GEN_DEPS_COMMAND) 2>&1; } 3>&2 2>&1 1>&3 3>&- | grep OK > /dev/null
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
  WRAP_CC,$($(TMD)CXX) $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $2 $(CXXFLAGS),$1,$2,$1.d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  = $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_CC,$($(TMD)CC) $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $2 $(CFLAGS),$1,$2,$1.d,$(UDEPS_INCLUDE_FILTER))

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
# target-specific: TMD, PCH, CXXOPTS, COPTS, PCH_GEN_DIR
# note: sources like $(PCH_GEN_DIR)$(notdir $2).cc are generated by SUNCC_PCH_RULE_TEMPL
CMN_PCXX = $(call SUP,$(TMD)PCXX,$2)$(call WRAP_CC,$($(TMD)CXX) -xpch=use:$(dir $1)$(basename $(notdir \
  $(PCH)))_cc $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $(PCH_GEN_DIR)$(notdir \
  $2).cc $(CXXFLAGS),$1,$2,$1.d,$(UDEPS_INCLUDE_FILTER))
CMN_PCC  = $(call SUP,$(TMD)PCC,$2)$(call WRAP_CC,$($(TMD)CC) -xpch=use:$(dir $1)$(basename $(notdir \
  $(PCH)))_c $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $(PCH_GEN_DIR)$(notdir \
  $2).c $(CFLAGS),$1,$2,$1.d,$(UDEPS_INCLUDE_FILTER))

# override C++ and C compilers to support compiling with precompiled header
# $1 - target object file
# $2 - source
# $3 - non-empty variant: R,P,D
# target-specific: CXX_WITH_PCH, CC_WITH_PCH
CMN_CXX = $(if $(filter $2,$(CXX_WITH_PCH)),$(CMN_PCXX),$(CMN_NCXX))
CMN_CC  = $(if $(filter $2,$(CC_WITH_PCH)),$(CMN_PCC),$(CMN_NCC))

# compilers of C/C++ precompiled header
# $1 - target object of generated source $3:
#  /build/obj/xxx_pch_cc.o or
#  /build/obj/xxx_pch_c.o
# $2 - pch header (full path, e.g. /src/include/xxx.h)
# $3 - generated source for precompiling header $2:
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.cc or
#  $(pch_gen_dir)$(basename $(notdir $2))_pch.c
# $4 - non-empty variant: R,P,D
# target-specific: TMD, CXXOPTS, COPTS
# note: pch object xxx_c.cpch or xxx_cc.Cpch will be created as a side-effect of this compilation
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$(call WRAP_CC,$($(TMD)CXX) -xpch=collect:$(dir $1)$(basename $(notdir \
  $2))_cc $(DEF_CXXFLAGS) $(CC_PARAMS) $(CXXOPTS) -o $1 $3 $(CXXFLAGS),$1,$3,$1.d,$(UDEPS_INCLUDE_FILTER))
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$(call WRAP_CC,$($(TMD)CC) -xpch=collect:$(dir $1)$(basename $(notdir \
  $2))_c $(DEF_CFLAGS) $(CC_PARAMS) $(COPTS) -o $1 $3 $(CFLAGS),$1,$3,$1.d,$(UDEPS_INCLUDE_FILTER))

# different precompiled header compilers
# note: used by SUNCC_PCH_RULE_TEMPL macro from $(CLEAN_BUILD_DIR)/compilers/suncc_pch.mk
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
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(foreach t,$(C_APP_TARGETS),$$(if $$($$t),$$(SUNCC_PCH_TEMPLATEt)))))

endif # !NO_PCH

# for DLL:         define target-specific variable MODVER
# for DLL and EXE: define target-specific variables RPATH and MAP
$(call define_prepend,DEFINE_C_APP_EVAL,$$(eval $$(UNIX_MOD_AUX_APP)))

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX AR TCC TCXX TAR PIC_COPTION PIE_LOPTION \
  LDFLAGS CMN_LDFLAGS EXE_LDFLAGS DLL_LDFLAGS ARFLAGS CXX_ARFLAGS DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE RPATH_OPTION \
  CMN_LIBS VERSION_SCRIPT SONAME_OPTION EXE_LD DLL_LD LIB_LD UDEPS_INCLUDE_FILTER CC_GEN_DEPS_COMMAND WRAP_CC \
  CFLAGS CXXFLAGS CMN_CFLAGS DEF_CFLAGS DEF_CXXFLAGS APP_DEFINES CC_PARAMS CMN_CXX CMN_CC \
  EXE_CXX EXE_CC DLL_CXX DLL_CC LIB_CXX LIB_CC CMN_NCXX CMN_NCC CMN_PCXX CMN_PCC PCH_CXX PCH_CC \
  PCH_EXE_CXX PCH_EXE_CC PCH_DLL_CXX PCH_DLL_CC PCH_LIB_CXX PCH_LIB_CC)
