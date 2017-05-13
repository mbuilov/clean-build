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
  $(filter simple,$(flavor INST_RPATH)),$(INST_RPATH),$$(INST_RPATH))$(newline)MAP:=$(newline)endef)

# compilers/linkers
CC   := gcc -m$(if $(UCPU:%64=),32,64)
CXX  := g++ -m$(if $(UCPU:%64=),32,64)
LD   := ld$(if $(filter x86%,$(UCPU)), -m$(if $(UCPU:%64=),elf_i386,elf_x86_64))
AR   := ar
TCC  := gcc -m$(if $(TCPU:%64=),32,64)
TCXX := g++ -m$(if $(TCPU:%64=),32,64)
TLD  := ld$(if $(filter x86%,$(TCPU)), -m$(if $(TCPU:%64=),elf_i386,elf_x86_64))
TAR  := ar
KCC  := gcc -m$(if $(KCPU:%64=),32,64)
KLD  := ld$(if $(filter x86%,$(KCPU)), -m$(if $(KCPU:%64=),elf_i386,elf_x86_64))

# make used by kbuild
KMAKE := $(MAKE)

# for building kernel modules
MODULES_PATH := /lib/modules/$(shell uname -r)/build

# yasm/flex/bison compilers
YASMC  := yasm
FLEXC  := flex
BISONC := bison

# note: assume yasm used only for drivers
YASM_FLAGS := -f $(if $(KCPU:%64=),elf32,elf64)$(if $(filter x86%,$(KCPU)), -m $(if $(KCPU:%64=),x86,amd64))

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
KLIB_PREFIX:=
KLIB_SUFFIX := .o

# kernel module (driver) prefix/suffix
DRV_PREFIX:=
DRV_SUFFIX := .ko

# import library and dll - the same file
# NOTE: DLL_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)

# standard defines
OS_PREDEFINES := LINUX UNIX

# application-level and kernel-level defines
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LP64) _REENTRANT _GNU_SOURCE

# note: recursive macro by default - to use $($t) dynamic value
# $t - KLIB
OS_KRNDEFS = $(if $(KCPU:%64=),ILP32,LP64) _KERNEL \
  KBUILD_STR\(s\)=\\\#s KBUILD_BASENAME=KBUILD_STR\($($t)\) KBUILD_MODNAME=KBUILD_STR\($($t)\)

# prefix to pass options to linker
WLPREFIX := -Wl,

# variants filter function - get possible variants for the target, needed by $(MTOP)/c.mk
# $1 - LIB,EXE,DLL
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - position-independent code in executables (for EXE and LIB)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if \
                  $(filter EXE,$1),P,$(if \
                  $(filter LIB,$1),P D))

# determine suffix for static LIB or for import library of DLL
# $1 - target variant R,P,D,<empty>
# note: overrides value from $(MTOP)/c.mk
LIB_VAR_SUFFIX = $(if \
                 $(filter P,$1),_pie,$(if \
                 $(filter D,$1),_pic))

# for $(EXE_VAR_SUFFIX) from $(MTOP)/c.mk:
# get target name suffix for EXE,DRV in case of multiple target variants
# $1 - EXE,DRV
# $2 - target variant P (not R or <empty>)
# $3 - list of variants of target $1 to build (filtered by target platform specific $(VARIANTS_FILTER))
# note: overrides value from $(MTOP)/c.mk
EXE_SUFFIX_GEN = $(if $(word 2,$3),_pie)

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependent static library name
# use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP = $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target: EXE,DLL
# $2 - variant of target EXE or DLL: R,P,<empty>
# $3 - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with any P- or R-EXE or R-DLL
VARIANT_IMP_MAP := R

# default flags for shared objects (executables and shared libraries)
DEF_SHARED_FLAGS := -Wl,--warn-common -Wl,--no-demangle

# default shared libs for target executables and shared libraries
DEF_SHARED_LIBS:=

# default flags for EXE-target linker
DEF_EXE_FLAGS:=

# default flags for SO-target linker
DEF_SO_FLAGS := -shared -Wl,--no-undefined

# default flags for static library position-independent code linker (with -fpie or -fpic options)
DEF_LD_FLAGS := -r --warn-common

# default flags for kernel library linker
DEF_KLD_FLAGS := -r --warn-common

# default flags for objects archiver
DEF_AR_FLAGS := -crs

# how to mark exported symbols from a DLL
DLL_EXPORTS_DEFINE := "__attribute__((visibility(\"default\")))"

# how to mark imported symbols from a DLL
DLL_IMPORTS_DEFINE:=

# runtime-path option for EXE or DLL
# target-specific: RPATH
RPATH_OPTION = $(addprefix $(WLPREFIX)-rpath=,$(strip $(RPATH)))

# runtime path to search shared libraries
RPATH_LINK:=

# linktime-path option for EXE or DLL
# target-specific: RPATH_LINK
RPATH_LINK_OPTION = $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK))

# common linker options for EXE or DLL
# $1 - target
# $2 - objects
# $3 - variant
# target-specific: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, LDFLAGS
CMN_LIBS = -pipe -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(RPATH_LINK_OPTION) $(if $(strip \
  $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(DLLS)) $(if $(LIBS),$(WLPREFIX)-Bstatic $(addprefix -l,$(addsuffix \
  $(call LIB_VAR_SUFFIX,$3),$(LIBS))) $(WLPREFIX)-Bdynamic)) $(addprefix -L,$(SYSLIBPATH)) $(SYSLIBS) $(DEF_SHARED_LIBS) $(LDFLAGS)

# what to export from a dll
# target-specific: MAP
VERSION_SCRIPT_OPTION = $(addprefix $(WLPREFIX)--version-script=,$(MAP))

# append soname option if target shared library have version info (some number after .so)
# $1 - full path to target shared library, for ex. /aa/bb/cc/libmy_lib.so, if MODVER=1.2.3 then soname will be libmy_lib.so.1
# target-specific: MODVER
SONAME_OPTION = $(addprefix $(WLPREFIX)-soname=$(notdir $1).,$(firstword $(subst ., ,$(MODVER))))

# different linkers
# $1 - target
# $2 - objects
# target-specific: TMD, COMPILER
EXE_R_LD = $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
EXE_P_LD = $(call SUP,$(TMD)XLD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,P) -pie
DLL_R_LD = $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(SONAME_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD = $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_P_LD = $(call SUP,$(TMD)LD,$1)$($(TMD)LD) $(DEF_LD_FLAGS) -o $1 $2 $(LDFLAGS)
LIB_D_LD = $(LIB_P_LD)
KLIB_R_LD = $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)

# flags for auto-dependencies generation
AUTO_DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)

# flags for application level C/C++-compiler
APP_FLAGS := -Wall -fvisibility=hidden
ifdef DEBUG
APP_FLAGS += -ggdb
else
APP_FLAGS += -g -O2
endif

# default flags for C++ compiler
DEF_CXXFLAGS:=

# default flags for C compiler
DEF_CFLAGS := -std=c99 -pedantic

# common options for application-level C++ and C compilers
# $1 - target
# $2 - source
# target-specific: DEFINES, INCLUDE
CC_PARAMS = -pipe -c $(APP_FLAGS) $(AUTO_DEPS_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target
# $2 - source
# target-specific: WITH_PCH, TMD, PCHS, CXXFLAGS, CFLAG
CMN_CXX = $(if $(filter $2,$(WITH_PCH)),$(call SUP,P$(TMD)CXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_cxx.h,$(call SUP,$(TMD)CXX,$2)$($(TMD)CXX)) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS)
CMN_CC  = $(if $(filter $2,$(WITH_PCH)),$(call SUP,P$(TMD)CC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,$(TMD)CC,$2)$($(TMD)CC)) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS)

# C++ and C precompiled header compilers
# $1 - target
# $2 - source
# target-specific: CXXFLAGS, CFLAGS
PCH_CXX = $(call SUP,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS)
PCH_CC  = $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS)

# position-independent code for executables/shared objects (dynamic libraries)
PIE_OPTION := -fpie
PIC_OPTION := -fpic

# different compilers
# $1 - target
# $2 - source
EXE_R_CXX = $(CMN_CXX) -o $1 $2
EXE_R_CC  = $(CMN_CC) -o $1 $2
EXE_P_CXX = $(EXE_R_CXX) $(PIE_OPTION)
EXE_P_CC  = $(EXE_R_CC) $(PIE_OPTION)
LIB_R_CXX = $(EXE_R_CXX)
LIB_R_CC  = $(EXE_R_CC)
LIB_P_CXX = $(EXE_P_CXX)
LIB_P_CC  = $(EXE_P_CC)
DLL_R_CXX = $(CMN_CXX) $(PIC_OPTION) -o $1 $2
DLL_R_CC  = $(CMN_CC) $(PIC_OPTION) -o $1 $2
LIB_D_CXX = $(DLL_R_CXX)
LIB_D_CC  = $(DLL_R_CC)

# different precompiler header compilers
# $1 - target
# $2 - source
PCH_EXE_R_CXX = $(PCH_CXX) -o $1 $2
PCH_EXE_R_CC  = $(PCH_CC) -o $1 $2
PCH_EXE_P_CXX = $(PCH_EXE_R_CXX) $(PIE_OPTION)
PCH_EXE_P_CC  = $(PCH_EXE_R_CC) $(PIE_OPTION)
PCH_LIB_R_CXX = $(PCH_EXE_R_CXX)
PCH_LIB_R_CC  = $(PCH_EXE_R_CC)
PCH_LIB_P_CXX = $(PCH_EXE_P_CXX)
PCH_LIB_P_CC  = $(PCH_EXE_P_CC)
PCH_DLL_R_CXX = $(PCH_CXX) $(PIC_OPTION) -o $1 $2
PCH_DLL_R_CC  = $(PCH_CC) $(PIC_OPTION) -o $1 $2
PCH_LIB_D_CXX = $(PCH_DLL_R_CXX)
PCH_LIB_D_CC  = $(PCH_DLL_R_CC)

# parameters for kernel-level static library
# target-specific: DEFINES, INCLUDE, CFLAGS
KLIB_PARAMS = -pipe -c $(KRN_FLAGS) $(AUTO_DEPS_FLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)

# kernel-level C compiler
# $1 - target
# $2 - source
# target-specific: WITH_PCH, PCH
KLIB_R_CC = $(if $(filter $2,$(WITH_PCH)),$(call SUP,PKCC,$2)$(KCC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,KCC,$2)$(KCC)) $(KLIB_PARAMS) -o $1 $2

# kernel-level precompiled header C compiler
# $1 - target
# $2 - source
PCH_KLIB_R_CC = $(call SUP,PCHKLIB,$2)$(KCC) $(KLIB_PARAMS) -o $1 $2

# kernel-level assembler
# $1 - target
# $2 - source
# target-specific: ASMFLAGS
KLIB_R_ASM = $(call SUP,ASM,$2)$(YASMC) $(YASM_FLAGS) -o $1 $2 $(ASMFLAGS)

# $1 - target
# $2 - source
BISON = $(call SUP,BISON,$2)$(BISONC) -o $1 -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

# compile with precompiled headers by default
NO_PCH:=

ifndef NO_PCH

# NOTE: $(PCH) - makefile-related path to header to precompile

# $1 - $(call FORM_OBJ_DIR,$t,$v)
# $2 - $(call FORM_TRG,$1,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P,
define PCH_TEMPLATE1
TRG_PCH := $(call FIXPATH,$(PCH))
TRG_WITH_PCH := $(call FIXPATH,$(WITH_PCH))
$2: PCH := $$(TRG_PCH)
$2: WITH_PCH := $$(TRG_WITH_PCH)
ifneq (,$$(filter %.c,$$(TRG_WITH_PCH)))
C_GCH := $1/$$(basename $$(notdir $$(TRG_PCH)))_pch_c.h
$$(C_GCH).gch: $$(TRG_PCH) | $1 $$(ORDER_DEPS)
	$$(call PCH_$t_$v_CC,$$@,$$(PCH))
ifndef NO_DEPS
-include $$(C_GCH).d)
endif
$$(addprefix $1/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.c,$$(TRG_WITH_PCH)))))): $$(C_GCH).gch
$$(call TOCLEAN,$$(C_GCH).gch $$(C_GCH).d)
endif
ifneq (,$$(filter %.cpp,$$(TRG_WITH_PCH)))
CXX_GCH := $1/$$(basename $$(notdir $$(TRG_PCH)))_pch_cxx.h
$$(CXX_GCH).gch: $$(TRG_PCH) | $1 $$(ORDER_DEPS)
	$$(call PCH_$t_$v_CXX,$$@,$$(PCH))
ifndef NO_DEPS
-include $$(CXX_GCH).d
endif
$$(addprefix $1/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.cpp,$$(TRG_WITH_PCH)))))): $$(CXX_GCH).gch
$$(call TOCLEAN,$$(CXX_GCH).gch $$(CXX_GCH).d)
ndif
endef

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: must reset target-specific WITH_PCH if not using precompiled header,
# otherwise DLL or LIB target may inherit WITH_PCH value from EXE, LIB target may inherit WITH_PCH value from DLL
PCH_TEMPLATE = $(if $(word 2,$(PCH) $(firstword $(WITH_PCH))),$(foreach \
  v,$(call GET_VARIANTS,$t),$(newline)$(call PCH_TEMPLATE1,$(call FORM_OBJ_DIR,$t,$v),$(call \
  FORM_TRG,$t,$v))),$(foreach v,$(call GET_VARIANTS,$t),$(call FORM_TRG,$t,$v): WITH_PCH:=$(newline)))

# set dependencies of objects compiled with pch header on .gch
# $1 - $(filter %.c,$src)
# $2 - $(filter %.cpp,$src)
# $3 - pch header name
# $4 - objdir
define ADD_WITH_PCH2
$(empty)
$(if $1,$(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $1)))): $4/$3_pch_c.h.gch)
$(if $2,$(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2)))): $4/$3_pch_cxx.h.gch)
endef

# function to add (generated?) sources to $({EXE,LIB,DLL,...}_WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,...
# $2 - sources
ADD_WITH_PCH1 = $(foreach v,$(call GET_VARIANTS,$1),$(call ADD_WITH_PCH2,$2,$3,$4,$(call FORM_OBJ_DIR,$1,$v)))
ADD_WITH_PCH  = $(eval WITH_PCH += $2$(call \
  ADD_WITH_PCH1,$1,$(filter %.c,$2),$(filter %.cpp,$2),$(basename $(notdir $(PCH)))))

endif # NO_PCH

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
MOD_AUX_TEMPLATE  = $(call MOD_AUX_TEMPLATE1,$(call FIXPATH,$(MAP)))

# this code is evaluated from $(DEFINE_TARGETS)
define OS_DEFINE_TARGETS
$(foreach t,EXE LIB DLL KLIB,$(if $($t),$(PCH_TEMPLATE)))
$(foreach t,EXE DLL,$(if $($t),$(MOD_AUX_TEMPLATE)))
endef

# $1 - destination directory
# $2 - file
# $3 - aux dep
define COPY_FILE_RULE
$(empty)
$1/$(notdir $2): $2 $3 | $1
	$$(call SUP,CP,$$@)cp -f$(if $(VERBOSE),v) $$< $$@
endef

# $1 - target file: $(call FORM_TRG,DRV,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV,$v)
# $5 - klibs:       $(addprefix $(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX)))
# 1) copy sources
# 2) copy klibs
# 3) generate Makefile for kbuild
# 4) call kbuild
define DRV_TEMPLATE1
$(foreach x,$2,$(call COPY_FILE_RULE,$4,$x,$(call EXTRACT_SDEPS,$x,$3)))
$(foreach x,$5,$(call COPY_FILE_RULE,$4,$(LIB_DIR)/$x))
$4/Makefile: | $4
	$$(call SUP,GEN,$$@)echo "obj-m += $(DRV_PREFIX)$(DRV).o" > $$@
	$(QUIET)echo "$(DRV_PREFIX)$(DRV)-objs := $(notdir $(2:.c=.o)) $5" >> $$@
	$(QUIET)echo "EXTRA_CFLAGS += $(addprefix -D,$(EXTRA_DRV_DEFINES)) $(addprefix -I,$(TRG_INCLUDE))" >> $$@
$4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX): $(addprefix $4/,$(notdir $2) $5) | $4/Makefile $$(ORDER_DEPS)
	+$$(call SUP,KBUILD,$$@)$(KMAKE) V=$(if $(VERBOSE),1,0) CC="$(KCC)" LD="$(KLD)" AR="$(AR)" $(addprefix \
  KBUILD_EXTRA_SYMBOLS=,$(KBUILD_EXTRA_SYMBOLS)) -C $(MODULES_PATH) M=$$(patsubst %/,%,$$(dir $$@)) $(addprefix ARCH=,$(ARCH))
$1: $4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX)
	$$(call SUP,CP,$$@)cp -f$(if $(VERBOSE),v) $$< $$@
endef

# how to build driver, used by $(C_RULES)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - DRV
# $v - R
define DRV_TEMPLATE
$(STD_TARGET_VARS)
NEEDED_DIRS += $4
$(call DRV_TEMPLATE1,$1,$2,$3,$4,$(addprefix $(KLIB_PREFIX),$(KLIBS:=$(KLIB_SUFFIX))))
$(call TOCLEAN,$4)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,INST_RPATH CC CXX MODULES_PATH LD AR TCC TCXX TLD TAR KCC KLD KMAKE YASMC FLEXC BISONC YASM_FLAGS \
  WLPREFIX DEF_SHARED_FLAGS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_LD_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS DLL_EXPORTS_DEFINE DLL_IMPORTS_DEFINE \
  RPATH_OPTION RPATH_LINK_OPTION CMN_LIBS VERSION_SCRIPT_OPTION SONAME_OPTION1 SONAME_OPTION \
  EXE_R_LD EXE_P_LD DLL_R_LD LIB_R_LD LIB_P_LD LIB_D_LD KLIB_LD AUTO_DEPS_FLAGS APP_FLAGS KRN_FLAGS DEF_CXXFLAGS DEF_CFLAGS CC_PARAMS \
  CMN_CXX CMN_CC PCH_CXX PCH_CC EXE_R_CXX EXE_R_CC EXE_P_CXX EXE_P_CC LIB_R_CXX LIB_R_CC LIB_P_CXX LIB_P_CC DLL_R_CXX DLL_R_CC \
  LIB_D_CXX LIB_D_CC PCH_EXE_R_CXX PCH_EXE_R_CC PCH_EXE_P_CXX PCH_EXE_P_CC PCH_LIB_R_CXX PCH_LIB_R_CC PCH_LIB_P_CXX PCH_LIB_P_CC \
  PCH_DLL_R_CXX PCH_DLL_R_CC PCH_LIB_D_CXX PCH_LIB_D_CC KLIB_PARAMS KLIB_R_CC PCH_KLIB_R_CC KLIB_R_ASM BISON FLEX \
  PCH_TEMPLATE1 PCH_TEMPLATE ADD_WITH_PCH2 ADD_WITH_PCH1 ADD_WITH_PCH \
  EXE_AUX_TEMPLATE2 DLL_AUX_TEMPLATE2 MOD_AUX_TEMPLATE1 MOD_AUX_TEMPLATE COPY_FILE_RULE DRV_TEMPLATE1)
