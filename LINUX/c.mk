OSTYPE := UNIX

# additional variables that may have target-dependent variant (EXE_RPATH, DLL_RPATH and so on)
TRG_VARS += RPATH

# additional variables without target-dependent variants
BLD_VARS += MAP

# reset additional variables
define RESET_OS_VARS
RPATH := $(INST_RPATH)
MAP   :=
endef

ifneq ($(filter default undefined,$(origin CC)),)
CC := gcc
endif

ifneq ($(filter default undefined,$(origin CXX)),)
CXX := g++
endif

# to build kernel modules
ifndef MODULES_PATH
MODULES_PATH := /lib/modules/$(shell uname -r)/build
endif

ifneq ($(filter default undefined,$(origin LD)),)
LD := ld
endif

ifneq ($(filter default undefined,$(origin AR)),)
AR := ar
endif

ifneq ($(filter default undefined,$(origin TCC)),)
TCC := $(CC)
endif

ifneq ($(filter default undefined,$(origin TCXX)),)
TCXX := $(CXX)
endif

ifneq ($(filter default undefined,$(origin TLD)),)
TLD := $(LD)
endif

ifneq ($(filter default undefined,$(origin TAR)),)
TAR := $(AR)
endif

ifneq ($(filter default undefined,$(origin KCC)),)
KCC := $(CC)
endif

ifneq ($(filter default undefined,$(origin KLD)),)
KLD := $(LD)
endif

ifneq ($(filter default undefined,$(origin KMAKE)),)
KMAKE := $(MAKE)
endif

ifndef YASMC
YASMC := yasm -f $(if $(KCPU:%64=),elf32,elf64) $(if $(filter x86%,$(KCPU)),-m $(if $(KCPU:%64=),x86,amd64))
endif

ifndef FLEXC
FLEXC := flex
endif

ifndef BISONC
BISONC := bison
endif

# prefixes/suffixes of build targets, may be already defined in $(TOP)/make/project.mk
# note: if OBJ_SUFFIX is defined, then all prefixes/suffixes must be also defined
ifndef OBJ_SUFFIX
EXE_SUFFIX :=
OBJ_SUFFIX := .o
LIB_PREFIX := lib
LIB_SUFFIX := .a   # static library (archive)
IMP_PREFIX := lib
IMP_SUFFIX := .so  # implementaton library for dll, the same as dll itself
DLL_PREFIX := lib
DLL_SUFFIX := .so  # dynamic-loaded library
KLIB_PREFIX :=
KLIB_SUFFIX := .o  # kernel-mode static library
DRV_PREFIX :=
DRV_SUFFIX := .ko  # kernel module
endif

# import library and dll - the same file
# NOTE: DLL_DIR and IMP_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)
IMP_DIR = $(LIB_DIR)

# linux variant, such as DEBIAN,ARCH,GENTOO and so on
# note: empty (generic variant) by default
ifndef OSVARIANT
OSVARIANT:=
endif

# standard defines
OS_PREDEFINES ?= $(OSVARIANT) LINUX UNIX

# application-level and kernel-level defines
# note: OS_APPDEFS and OS_KRNDEFS are may be defined as empty
ifeq (undefined,$(origin OS_APPDEFS))
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LP64) _REENTRANT _GNU_SOURCE
endif

# note: recursive macro by default - to use $(KLIB) dynamic value
OS_KRNDEFS ?= $(if $(KCPU:%64=),ILP32,LP64) _KERNEL \
  KBUILD_STR\(s\)=\\\#s KBUILD_BASENAME=KBUILD_STR\($(KLIB)\) KBUILD_MODNAME=KBUILD_STR\($(KLIB)\)

# prefix to pass options to linker
ifeq (undefined,$(origin WLPREFIX))
WLPREFIX := -Wl,
endif

# supported target variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - position-independent code in executables (for EXE and LIB)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER ?= $(if \
                   $(filter EXE,$1),P,$(if \
                   $(filter LIB,$1),P D))

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l - dependent static library name
# use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP ?= $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $d - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with any P- or R-EXE or R-DLL
ifeq (undefined,$(origin VARIANT_IMP_MAP))
VARIANT_IMP_MAP := R
endif

# default flags for shared objects
ifeq (undefined,$(origin DEF_SHARED_FLAGS))
DEF_SHARED_FLAGS := -Wl,--warn-common -Wl,--no-demangle
endif

# default flags for EXE-linker
ifeq (undefined,$(origin DEF_EXE_FLAGS))
DEF_EXE_FLAGS :=
endif

# default flags for shared objects linker
ifeq (undefined,$(origin DEF_SO_FLAGS))
DEF_SO_FLAGS := -shared -Xlinker --no-undefined
endif

# default flags for static library (-fpie or -fpic) linker
ifeq (undefined,$(origin DEF_LD_FLAGS))
DEF_LD_FLAGS := -r --warn-common
endif

# default flags for kernel library linker
ifeq (undefined,$(origin DEF_KLD_FLAGS))
DEF_KLD_FLAGS := -r --warn-common
endif

# default flags for static library archiver
ifeq (undefined,$(origin DEF_AR_FLAGS))
DEF_AR_FLAGS := -crs
endif

# runtime-path option for EXE or DLL
# target-specfic: RPATH
RPATH_OPTION ?= $(addprefix $(WLPREFIX)-rpath=,$(strip $(RPATH)))

# linktime-path option for EXE or DLL
# target-specfic: RPATH_LINK
RPATH_LINK_OPTION ?= $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK))

# common linker options for EXE or DLL
# $1 - target, $2 - objects, $3 - variant
# target-specfic: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, LDFLAGS
CMN_LIBS ?= -pipe -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(RPATH_LINK_OPTION) $(if \
  $(strip $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(addsuffix $(call \
  VARIANT_LIB_SUFFIX,$3),$(LIBS)) $(DLLS))) $(addprefix -L,$(SYSLIBPATH)) $(addprefix -l,$(SYSLIBS)) $(LDFLAGS)

# what to export from a dll
# target-specfic: MAP
VERSION_SCRIPT_OPTION ?= $(addprefix $(WLPREFIX)--version-script=,$(MAP))

# different linkers
# $1 - target, $2 - objects
# target-specfic: TMD, COMPILER
EXE_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
EXE_P_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,P) -pie
DLL_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD ?= $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_P_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)LD) $(DEF_LD_FLAGS) -o $1 $2 $(LDFLAGS)
LIB_D_LD ?= $(LIB_P_LD)
KLIB_LD  ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)

# flags for auto-dependencies generation
ifeq (undefined,$(origin AUTO_DEPS_FLAGS))
AUTO_DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)
endif

# flags for application level C/C++-compiler
ifeq (undefined,$(origin APP_FLAGS))
ifdef DEBUG
APP_FLAGS := -Wall -ggdb
else
APP_FLAGS := -Wall -g -O2
endif
endif

# default flags for C++ compiler
ifeq (undefined,$(origin DEF_CXXFLAGS))
DEF_CXXFLAGS:=
endif

# default flags for C compiler
ifeq (undefined,$(origin DEF_CFLAGS))
DEF_CFLAGS := -std=c99 -pedantic
endif

# common options for application-level C++ and C compilers
# $1 - target, $2 - source
# target-specfic: DEFINES, INCLUDE
CC_PARAMS ?= -pipe -c $(APP_FLAGS) $(AUTO_DEPS_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target, $2 - source
# target-specfic: WITH_PCH, TMD, PCHS, CXXFLAGS, CFLAG
CMN_CXX ?= $(if $(filter $2,$(WITH_PCH)),$(call SUP,P$(TMD)CXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_cxx.h,$(call SUP,$(TMD)CXX,$2)$($(TMD)CXX)) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS)
CMN_CC  ?= $(if $(filter $2,$(WITH_PCH)),$(call SUP,P$(TMD)CC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,$(TMD)CC,$2)$($(TMD)CC)) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS)

# C++ and C precompiled header compilers
# $1 - target, $2 - source
# target-specfic: CXXFLAGS, CFLAGS
PCH_CXX ?= $(call SUP,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS)
PCH_CC  ?= $(call SUP,$(TMD)PCHCC,$2)$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS)

# different compilers
# $1 - target, $2 - source
EXE_R_CXX ?= $(CMN_CXX) -o $1 $2
EXE_R_CC  ?= $(CMN_CC) -o $1 $2
EXE_P_CXX ?= $(EXE_R_CXX) -fpie
EXE_P_CC  ?= $(EXE_R_CC) -fpie
LIB_R_CXX ?= $(EXE_R_CXX)
LIB_R_CC  ?= $(EXE_R_CC)
LIB_P_CXX ?= $(EXE_P_CXX)
LIB_P_CC  ?= $(EXE_P_CC)
DLL_R_CXX ?= $(CMN_CXX) -fpic -o $1 $2
DLL_R_CC  ?= $(CMN_CC) -fpic -o $1 $2
LIB_D_CXX ?= $(DLL_R_CXX)
LIB_D_CC  ?= $(DLL_R_CC)

# different precompiler header compilers
# $1 - target, $2 - source
PCH_EXE_R_CXX ?= $(PCH_CXX) -o $1 $2
PCH_EXE_R_CC  ?= $(PCH_CC) -o $1 $2
PCH_EXE_P_CXX ?= $(PCH_EXE_R_CXX) -fpie
PCH_EXE_P_CC  ?= $(PCH_EXE_R_CC) -fpie
PCH_LIB_R_CXX ?= $(PCH_EXE_R_CXX)
PCH_LIB_R_CC  ?= $(PCH_EXE_R_CC)
PCH_LIB_P_CXX ?= $(PCH_EXE_P_CXX)
PCH_LIB_P_CC  ?= $(PCH_EXE_P_CC)
PCH_DLL_R_CXX ?= $(PCH_CXX) -fpic -o $1 $2
PCH_DLL_R_CC  ?= $(PCH_CC) -fpic -o $1 $2
PCH_LIB_D_CXX ?= $(PCH_DLL_R_CXX)
PCH_LIB_D_CC  ?= $(PCH_DLL_R_CC)

# parameters for kernel-level static library
# target-specfic: DEFINES, INCLUDE, CFLAGS
KLIB_PARAMS ?= -pipe -c $(KRN_FLAGS) $(AUTO_DEPS_FLAGS) $(call \
  SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)

# kernel-level C compiler
# $1 - target, $2 - source
# target-specfic: WITH_PCH, PCH
KLIB_R_CC ?= $(if $(filter $2,$(WITH_PCH)),$(call SUP,PKCC,$2)$(KCC) -I$(dir $1) -include $(basename \
  $(notdir $(PCH)))_pch_c.h,$(call SUP,KCC,$2)$(KCC)) $(KLIB_PARAMS) -o $1 $2

# kernel-level precompiled header C compiler
# $1 - target, $2 - source
PCH_KLIB_R_CC ?= $(call SUP,PCHKLIB,$2)$(KCC) $(KLIB_PARAMS) -o $1 $2

# kernel-level assembler
# $1 - target, $2 - source
# target-specfic: ASMFLAGS
KLIB_R_ASM ?= $(call SUP,ASM,$2)$(YASMC) -o $1 $2 $(ASMFLAGS)

# $1 - target, $2 - source
BISON ?= $(call SUP,BISON,$2)cd $1; $(BISONC) -d --fixed-output-files $(abspath $2)
FLEX  ?= $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

ifndef NO_PCH

# NOTE: $(PCH) - makefile-related path to header to precompile

# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call FORM_OBJ_DIR,$1,$v)
# $3 - $(call FORM_TRG,$1,$v)
# $v - R,P,
# note: $(NO_DEPS) - may be recursive and so have different values, for example depending on value of $(CURRENT_MAKEFILE)
define PCH_TEMPLATE1
TRG_PCH := $(call FIXPATH,$(firstword $($1_PCH) $(PCH)))
TRG_WITH_PCH := $(call FIXPATH,$(WITH_PCH) $($1_WITH_PCH))
$3: PCH := $$(TRG_PCH)
$3: WITH_PCH := $$(TRG_WITH_PCH)
ifneq ($$(filter %.c,$$(TRG_WITH_PCH)),)
C_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_c.h
$$(C_GCH).gch: $$(TRG_PCH) | $2 $$(ORDER_DEPS)
	$$(call PCH_$1_$v_CC,$$@,$$(PCH))
ifeq ($(NO_DEPS),)
-include $$(C_GCH).d)
endif
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.c,$$(TRG_WITH_PCH)))))): $$(C_GCH).gch
CLEAN += $$(C_GCH).gch $$(C_GCH).d
endif
ifneq ($$(filter %.cpp,$$(TRG_WITH_PCH)),)
CXX_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_cxx.h
$$(CXX_GCH).gch: $$(TRG_PCH) | $2 $$(ORDER_DEPS)
	$$(call PCH_$1_$v_CXX,$$@,$$(PCH))
ifeq ($(NO_DEPS),)
-include $$(CXX_GCH).d
endif
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.cpp,$$(TRG_WITH_PCH)))))): $$(CXX_GCH).gch
CLEAN += $$(CXX_GCH).gch $$(CXX_GCH).d
ndif
endef # PCH_TEMPLATE1

# $t - EXE,LIB,DLL,KLIB
# note: must reset target-specific WITH_PCH if not using precompiled header,
# otherwise DLL or LIB target may inherit WITH_PCH value from EXE, LIB target may inherit WITH_PCH value from DLL
PCH_TEMPLATE2 = $(if $($t),$(if $(word 2,$(firstword $($t_PCH)$(PCH)) $(firstword $($t_WITH_PCH)$(WITH_PCH))),$(foreach \
  v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(newline)$(call PCH_TEMPLATE1,$t,$(call FORM_OBJ_DIR,$t,$v),$(call FORM_TRG,$t,$v))),$(foreach \
  v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(call FORM_TRG,$t,$v): WITH_PCH:=$(newline))))

# code to eval to build with precompiled headers
PCH_TEMPLATES = $(foreach t,EXE LIB DLL KLIB,$(PCH_TEMPLATE2))

# set dependencies of objects compiled with pch header on .gch
# $1 - EXE,LIB,DLL,...
# $2 - $(filter %.c,$src)
# $3 - $(filter %.cpp,$src)
# $4 - pch header name
# $5 - objdir
define ADD_WITH_PCH2
$(empty)
$(if $2,$(addprefix $5/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2)))): $5/$4_pch_c.h.gch)
$(if $3,$(addprefix $5/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))): $5/$4_pch_cxx.h.gch)
endef

# function to add (generated?) sources to $({EXE,LIB,DLL,...}_WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,... $2 - sources
ADD_WITH_PCH1 = $(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call ADD_WITH_PCH2,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1,$v)))
ADD_WITH_PCH = $(eval $1_WITH_PCH += $2$(call \
  ADD_WITH_PCH1,$1,$(filter %.c,$2),$(filter %.cpp,$2),$(basename $(notdir $(firstword $($1_PCH) $(PCH))))))

endif # NO_PCH

# auxiliary defines for EXE
# $1 - $(call FORM_TRG,EXE,R)
define EXE_AUX_TEMPLATE1
$1: RPATH := $(RPATH) $(EXE_RPATH)
endef
EXE_AUX_TEMPLATE = $(call EXE_AUX_TEMPLATE1,$(call FORM_TRG,EXE,R))

# auxiliary defines for DLL
# $1 - $(call FORM_TRG,DLL,R)
# $2 - $(call FIXPATH,$(firstword $(DLL_MAP) $(MAP)))
define DLL_AUX_TEMPLATE1
$1: RPATH := $(RPATH) $(DLL_RPATH)
$1: MAP := $2
$1: $2
endef
DLL_AUX_TEMPLATE = $(call DLL_AUX_TEMPLATE1,$(call FORM_TRG,DLL,R),$(call FIXPATH,$(firstword $(DLL_MAP) $(MAP))))

# $1 - dest dir, $2 - file, $3 - aux dep
define COPY_FILE_RULE
$(empty)
$1/$(notdir $2): $2 $3 | $1
	$$(call SUP,CP,$$@)cp -f$(if $(VERBOSE),v) $$< $$@
endef

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - gendir:      $(GEN_DIR)/$(DRV)_DRV
# $5 - klibs:       $(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))
define DRV_TEMPLATE
NEEDED_DIRS += $4
# copy sources
$(foreach x,$2,$(call COPY_FILE_RULE,$4,$x,$(call EXTRACT_SRC_DEPS,$x,$3)))
# copy klibs
$(foreach x,$5,$(call COPY_FILE_RULE,$4,$(LIB_DIR)/$x))
$(STD_TARGET_VARS)
# generate Makefile for kbuild
$4/Makefile: | $4
	$$(call SUP,GEN,$$@)echo "obj-m += $(DRV_PREFIX)$(DRV).o" > $$@ && \
  echo "$(DRV_PREFIX)$(DRV)-objs := $(notdir $(2:.c=.o)) $5" >> $$@ && \
  echo "EXTRA_CFLAGS += $(addprefix -D,$(EXTRA_DRV_DEFINES)) $(addprefix -I,$(call TRG_INCLUDE,DRV))" >> $$@
# call kbuild
$4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX): $(addprefix $4/,$(notdir $2) $5) | $4/Makefile $$(ORDER_DEPS)
	+$$(call SUP,KBUILD,$$@)$(KMAKE) V=$(if $(VERBOSE),1,0) CC="$(KCC)" LD="$(KLD)" AR="$(AR)" $(addprefix \
  KBUILD_EXTRA_SYMBOLS=,$(KBUILD_EXTRA_SYMBOLS)) -C $(MODULES_PATH) M=$$(patsubst %/,%,$$(dir $$@)) $(addprefix ARCH=,$(ARCH))
$1: $4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX) | $(BIN_DIR)
	$$(call SUP,CP,$$@)cp -f$(if $(VERBOSE),v) $$< $$@
CLEAN += $4
endef

# how to build kernel module
DRV_RULES = $(if $(DRV),$(call DRV_TEMPLATE,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call \
  TRG_DEPS,DRV),$(GEN_DIR)/$(DRV)_DRV,$(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))))

# this code is normally evaluated at end of target Makefile
define OS_DEFINE_TARGETS
$(PCH_TEMPLATES)
$(if $(EXE),$(EXE_AUX_TEMPLATE))
$(if $(DLL),$(DLL_AUX_TEMPLATE))
$(DRV_RULES)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX MODULES_PATH LD AR TCC TCXX TLD TAR KCC KLD KMAKE YASMC FLEXC BISONC \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX DLL_PREFIX DLL_SUFFIX KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX \
  DLL_DIR IMP_DIR OS_PREDEFINES OS_APPDEFS OS_KRNDEFS WLPREFIX VARIANTS_FILTER VARIANT_LIB_MAP VARIANT_IMP_MAP DEF_SHARED_FLAGS \
  DEF_EXE_FLAGS DEF_SO_FLAGS DEF_LD_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS RPATH_OPTION RPATH_LINK_OPTION CMN_LIBS VERSION_SCRIPT_OPTION \
  EXE_R_LD EXE_P_LD DLL_R_LD LIB_R_LD LIB_P_LD LIB_D_LD KLIB_LD AUTO_DEPS_FLAGS APP_FLAGS KRN_FLAGS DEF_CXXFLAGS DEF_CFLAGS CC_PARAMS \
  CMN_CXX CMN_CC PCH_CXX PCH_CC EXE_R_CXX EXE_R_CC EXE_P_CXX EXE_P_CC LIB_R_CXX LIB_R_CC LIB_P_CXX LIB_P_CC DLL_R_CXX DLL_R_CC \
  LIB_D_CXX LIB_D_CC PCH_EXE_R_CXX PCH_EXE_R_CC PCH_EXE_P_CXX PCH_EXE_P_CC PCH_LIB_R_CXX PCH_LIB_R_CC PCH_LIB_P_CXX PCH_LIB_P_CC \
  PCH_DLL_R_CXX PCH_DLL_R_CC PCH_LIB_D_CXX PCH_LIB_D_CC KLIB_PARAMS KLIB_R_CC PCH_KLIB_R_CC KLIB_R_ASM BISON FLEX \
  PCH_TEMPLATE1 PCH_TEMPLATE2 PCH_TEMPLATES ADD_WITH_PCH2 ADD_WITH_PCH1 ADD_WITH_PCH \
  EXE_AUX_TEMPLATE1 EXE_AUX_TEMPLATE DLL_AUX_TEMPLATE1 DLL_AUX_TEMPLATE \
  COPY_FILE_RULE DRV_TEMPLATE DRV_RULES)
