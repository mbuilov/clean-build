ifneq ($(filter default undefined,$(origin CC)),)
CC := gcc
endif

ifneq ($(filter default undefined,$(origin CXX)),)
CXX := g++
endif

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
TCC := gcc
endif

ifneq ($(filter default undefined,$(origin TCXX)),)
TCXX := g++
endif

ifneq ($(filter default undefined,$(origin TLD)),)
TLD := ld
endif

ifneq ($(filter default undefined,$(origin TAR)),)
TAR := ar
endif

ifneq ($(filter default undefined,$(origin KCC)),)
KCC := gcc
endif

ifneq ($(filter default undefined,$(origin KLD)),)
KLD := ld
endif

ifneq ($(filter default undefined,$(origin KMAKE)),)
KMAKE := $(MAKE)
endif

ifneq ($(filter default undefined,$(origin YASM)),)
YASM := yasm -f $(if $(filter %64,$(KCPU)),elf64,elf32) $(if $(filter x86%,$(KCPU)),-m $(if $(filter %64,$(KCPU)),amd64,x86))
endif

EXE_SUFFIX :=
OBJ_SUFFIX := .o
LIB_PREFIX := lib
LIB_SUFFIX := .a
IMP_PREFIX := lib
IMP_SUFFIX := .so
DLL_PREFIX := lib
DLL_SUFFIX := .so
KLIB_PREFIX :=
KLIB_SUFFIX := .o
DRV_PREFIX :=
DRV_SUFFIX := .ko

# import library and dll - the same file
DLL_DIR = $(LIB_DIR)
IMP_DIR = $(LIB_DIR)

ifndef OS_PREDEFINES
OS_PREDEFINES := LINUX UNIX $(OSVARIANT)
endif
ifndef OS_APPDEFS
OS_APPDEFS := $(if $(filter %64,$(UCPU)),LP64,ILP32) _GNU_SOURCE _REENTRANT
endif
OS_KRNDEFS ?= $(if $(filter %64,$(KCPU)),LP64,ILP32) _KERNEL \
               KBUILD_STR\(s\)=\\\#s KBUILD_BASENAME=KBUILD_STR\($(KLIB)\) KBUILD_MODNAME=KBUILD_STR\($(KLIB)\)

WLPREFIX := -Wl,

# supported target variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# P - position-independent code in executables (for EXE and LIB)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if \
                   $(filter EXE,$1),P,$(if \
                   $(filter LIB,$1),P D))

# use the same variant of static library as target EXE
# use D-variant of static library for DLL
VARIANT_LIB_MAP = $(if $(filter DLL,$1),D,$2)

# the same default variant of DLL may be linked with P- or R-EXE
VARIANT_IMP_MAP := R

# $1 - target, $2 - objects, $3 - variant
CMN_LIBS  = -pipe -o $1 $2 $(WLPREFIX)--warn-common $(WLPREFIX)--no-demangle $(addprefix $(WLPREFIX)-rpath=,$(strip \
            $(RPATH))) $(addprefix $(WLPREFIX)-rpath-link=,$(RPATH_LINK)) $(if $(strip $(LIBS)$(DLLS)),$(addprefix \
            -L,$(LIB_DIR)) $(addprefix -l$(call VARIANT_LIB_PREFIX,$3),$(LIBS)) $(addprefix \
            -l,$(DLLS))) $(addprefix -L,$(SYSLIBPATH)) $(addprefix -l,$(SYSLIBS)) $(LDFLAGS)

ifeq (undefined,$(origin STD_SOFLAGS))
STD_SOFLAGS := -shared -Xlinker --no-undefined
endif

ifeq (undefined,$(origin STD_LIBFLAGS))
STD_LIBFLAGS := -r --warn-common
endif

EXE_R_LD  = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(call CMN_LIBS,$1,$2,R)
EXE_P_LD  = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(call CMN_LIBS,$1,$2,P) -pie
DLL_R_LD  = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(STD_SOFLAGS) $(addprefix \
             $(WLPREFIX)--version-script=,$(MAP)) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD  = $(call SUPRESS,$(TMD)AR,$1)$($(TMD)AR) -crs $1 $2
LIB_P_LD  = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)LD) $(STD_LIBFLAGS) -o $1 $2 $(LDFLAGS)
LIB_D_LD  = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)LD) $(STD_LIBFLAGS) -o $1 $2 $(LDFLAGS)
KLIB_LD   = $(call SUPRESS,KLD,$1)$(KLD) $(STD_LIBFLAGS) -o $1 $2 $(LDFLAGS)

DEPS_FLAGS := $(if $(NO_DEPS),,-MMD -MP)

ifneq ($(filter %D,$(TARGET)),)
DEF_APP_FLAGS := -Wall -ggdb
else
DEF_APP_FLAGS := -Wall -g -O2
endif

ifeq (undefined,$(origin APP_FLAGS))
APP_FLAGS := $(DEF_APP_FLAGS)
endif

ifeq (undefined,$(origin STD_CFLAGS))
STD_CFLAGS := -std=c99 -pedantic
endif

# $1 - target, $2 - source
CC_PARAMS = -pipe -c $(APP_FLAGS) $(DEPS_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))
CMN_CXX  = $(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,P$(TMD)CXX,$2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
            $(notdir $(PCH)))_pch_cxx.h,$(call SUPRESS,$(TMD)CXX,$2)$($(TMD)CXX)) $(CC_PARAMS) $(CXXFLAGS)
CMN_CC   = $(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,P$(TMD)CC,$2)$($(TMD)CC) -I$(dir $1) -include $(basename \
            $(notdir $(PCH)))_pch_c.h,$(call SUPRESS,$(TMD)CC,$2)$($(TMD)CC)) $(CC_PARAMS) $(STD_CFLAGS) $(CFLAGS)

PCH_CXX  = $(call SUPRESS,$(TMD)PCHCXX,$2)$($(TMD)CXX) $(CC_PARAMS) $(CXXFLAGS)
PCH_CC   = $(call SUPRESS,$(TMD)PCHCC,$2)$($(TMD)CC) $(CC_PARAMS) $(STD_CFLAGS) $(CFLAGS)

EXE_R_CXX  = $(CMN_CXX) -o $1 $2
EXE_R_CC   = $(CMN_CC) -o $1 $2
EXE_P_CXX  = $(EXE_R_CXX) -fpie
EXE_P_CC   = $(EXE_R_CC) -fpie
LIB_R_CXX  = $(EXE_R_CXX)
LIB_R_CC   = $(EXE_R_CC)
LIB_P_CXX  = $(EXE_P_CXX)
LIB_P_CC   = $(EXE_P_CC)
DLL_R_CXX  = $(CMN_CXX) -fpic -o $1 $2
DLL_R_CC   = $(CMN_CC) -fpic -o $1 $2
LIB_D_CXX  = $(DLL_R_CXX)
LIB_D_CC   = $(DLL_R_CC)

PCH_EXE_R_CXX  = $(PCH_CXX) -o $1 $2
PCH_EXE_R_CC   = $(PCH_CC) -o $1 $2
PCH_EXE_P_CXX  = $(PCH_EXE_R_CXX) -fpie
PCH_EXE_P_CC   = $(PCH_EXE_R_CC) -fpie
PCH_LIB_R_CXX  = $(PCH_EXE_R_CXX)
PCH_LIB_R_CC   = $(PCH_EXE_R_CC)
PCH_LIB_P_CXX  = $(PCH_EXE_P_CXX)
PCH_LIB_P_CC   = $(PCH_EXE_P_CC)
PCH_DLL_R_CXX  = $(PCH_CXX) -fpic -o $1 $2
PCH_DLL_R_CC   = $(PCH_CC) -fpic -o $1 $2
PCH_LIB_D_CXX  = $(PCH_DLL_R_CXX)
PCH_LIB_D_CC   = $(PCH_DLL_R_CC)

KLIB_PARAMS = -pipe -c $(KERN_FLAGS) $(DEPS_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)
KLIB_R_CC  = $(if $(filter-out %.d,$1),$(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,PKCC,$2)$(KCC) -I$(dir $1) -include $(basename \
              $(notdir $(PCH)))_pch_c.h,$(call SUPRESS,KCC,$2)$(KCC)) $(KLIB_PARAMS) -o $1 $2)

PCH_KLIB_R_CC = $(if $(filter-out %.d,$1),$(call SUPRESS,PCHKLIB,$2)$(KCC) $(KLIB_PARAMS) -o $1 $2)

KLIB_R_ASM ?= $(if $(filter-out %.d,$1),$(call SUPRESS,ASM,$2)$(YASM) -o $1 $2 $(ASMFLAGS))

BISON = $(call SUPRESS,BISON,$2)cd $1; bison -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUPRESS,FLEX,$2)flex -o$1 $2

ifndef NO_PCH

# $1 - EXE,LIB,DLL,KLIB, $2 - $(call FORM_OBJ_DIR,$1,$v), $3 - $(call FORM_TRG,$1,$v), $v - R,P,D
define PCH_TEMPLATE1
TRG_PCH := $(if $($1_PCH),$($1_PCH),$(PCH))
TRG_WITH_PCH := $(WITH_PCH) $($1_WITH_PCH)
$3: PCH := $$(call FIXPATH,$$(TRG_PCH))
$3: WITH_PCH := $$(call FIXPATH,$$(TRG_WITH_PCH))
ifneq ($$(filter %.c,$$(TRG_WITH_PCH)),)
C_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_c.h
$$(C_GCH).gch: $$(CURRENT_DEPS) | $2
	$$(call PCH_$1_$v_CC,$$@,$$(PCH))
$(if $(NO_DEPS),,-include $$(C_GCH).d)
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.c,$$(TRG_WITH_PCH)))))): $$(C_GCH).gch
CLEAN += $$(C_GCH).gch $$(C_GCH).d
endif
ifneq ($$(filter %.cpp,$$(TRG_WITH_PCH)),)
CXX_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_cxx.h
$$(CXX_GCH).gch: $$(CURRENT_DEPS) | $2
	$$(call PCH_$1_$v_CXX,$$@,$$(PCH))
$(if $(NO_DEPS),,-include $$(CXX_GCH).d)
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.cpp,$$(TRG_WITH_PCH)))))): $$(CXX_GCH).gch
CLEAN += $$(CXX_GCH).gch $$(CXX_GCH).d
endif
endef

PCH_TEMPLATE2 = $(if $($t),$(if $(word 2,$(firstword $($t_PCH)$(PCH)) $(firstword $($t_WITH_PCH)$(WITH_PCH))),$(foreach \
  v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(newline)$(call PCH_TEMPLATE1,$t,$(call FORM_OBJ_DIR,$t,$v),$(call FORM_TRG,$t,$v))),$(foreach \
  v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(call FORM_TRG,$t,$v): WITH_PCH:=$(newline))))

# code to eval to build with precompiled headers
PCH_TEMPLATES = $(foreach t,EXE LIB DLL KLIB,$(PCH_TEMPLATE2))

# $1 - EXE,LIB,DLL,... $2 - $(filter %.c,$src), $3 - $(filter %.cpp,$src), $4 - pch header, $5 - objdir
define ADD_WITH_PCH2
$(empty)
$(if $2,$(addprefix $5/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2)))): $5/$4_pch_c.h.gch)
$(if $3,$(addprefix $5/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))): $5/$4_pch_cxx.h.gch)
endef

# function to add (generated?) sources to $({EXE,LIB,DLL,...}_WITH_PCH) list - to compile sources with pch header
# $1 - EXE,LIB,DLL,... $2 - sources
ADD_WITH_PCH1 = $(foreach v,$(call GET_VARIANTS,$1,VARIANTS_FILTER),$(call ADD_WITH_PCH2,$1,$2,$3,$4,$(call FORM_OBJ_DIR,$1,$v)))
ADD_WITH_PCH = $(eval $1_WITH_PCH += $2$(call \
  ADD_WITH_PCH1,$1,$(filter %.c,$2),$(filter %.cpp,$2),$(basename $(notdir $(if $($1_PCH),$($1_PCH),$(PCH))))))

endif # NO_PCH

# $1 - dest dir, $2 - file, $3 - aux dep
define COPY_FILE_RULE
$(empty)
$1/$(notdir $2): $2 $3 | $1
	$$(call SUPRESS,CP,$$@)cp -f$(if $(VERBOSE:0=),v) $$< $$@
endef

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - blddir:      $(BLD_DIR)/DRV_$(DRV)
# $5 - klibs:       $(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))
define DRV_TEMPLATE
NEEDED_DIRS += $4
# copy sources
$(foreach x,$2,$(call COPY_FILE_RULE,$4,$x,$(call EXTRACT_SRC_DEPS,$x,$3)))
# copy klibs
$(foreach x,$5,$(call COPY_FILE_RULE,$4,$(LIB_DIR)/$x))
$(call STD_TARGET_VARS,$1)
# generate Makefile for kbuild
$4/Makefile: | $4
	$$(call SUPRESS,GEN,$$@)echo "obj-m += $(DRV_PREFIX)$(DRV).o" > $$@ && \
  echo "$(DRV_PREFIX)$(DRV)-objs := $(notdir $(2:.c=.o)) $5" >> $$@ && \
  echo "EXTRA_CFLAGS += $(addprefix -D,$(EXTRA_DRV_DEFINES)) $(addprefix -I,$(call TRG_INCLUDE,DRV))" >> $$@
# call kbuild
$4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX): $(addprefix $4/,$(notdir $2) $5) $(CURRENT_DEPS) | $4/Makefile
	+$$(call SUPRESS,KBUILD,$$@)$(KMAKE) V=$(VERBOSE) CC="$(KCC)" LD="$(KLD)" AR="$(AR)" $(addprefix \
  KBUILD_EXTRA_SYMBOLS=,$(KBUILD_EXTRA_SYMBOLS)) -C $(MODULES_PATH) M=$$(patsubst %/,%,$$(dir $$@)) $(addprefix ARCH=,$(ARCH))
$1: $4/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX) | $(BIN_DIR)
	$$(call SUPRESS,CP,$$@)cp -f$(if $(VERBOSE:0=),v) $$< $$@
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $4
endef

# how to build kernel module
DRV_RULES = $(if $(DRV),$(call DRV_TEMPLATE,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call \
  TRG_DEPS,DRV),$(BLD_DIR)/DRV_$(DRV),$(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))))

# this code is normally evaluated at end of target Makefile
define OS_DEFINE_TARGETS
$(PCH_TEMPLATES)
$(if $(DLL),$(call FORM_TRG,DLL,R): $(call TRG_MAP,DLL))
$(DRV_RULES)
endef
