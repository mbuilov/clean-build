ifneq ($(filter default undefined,$(origin CC)),)
CC := gcc
endif

ifneq ($(filter default undefined,$(origin CXX)),)
CXX := g++
endif

ifeq ($(MODULES_PATH),)
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

PREDEFINES += LINUX UNIX $(OSVARIANT)
APPDEFS    += $(if $(filter %64,$(UCPU)),LP64,ILP32) _GNU_SOURCE _REENTRANT
KRNDEFS    += $(if $(filter %64,$(KCPU)),LP64,ILP32) _KERNEL \
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

EXE_R_LD  = $(call SUPRESS,LD     $1)$($(TMD)$(COMPILER)) $(call CMN_LIBS,$1,$2,R)
EXE_P_LD  = $(call SUPRESS,LD     $1)$($(TMD)$(COMPILER)) $(call CMN_LIBS,$1,$2,P) -pie
DLL_R_LD  = $(call SUPRESS,LD     $1)$($(TMD)$(COMPILER)) -shared -Xlinker --no-undefined $(addprefix \
             $(WLPREFIX)--version-script=,$(MAP)) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD  = $(call SUPRESS,AR     $1)$($(TMD)AR) -crs $1 $2
LIB_P_LD  = $(call SUPRESS,LD     $1)$($(TMD)LD) -r --warn-common -o $1 $2 $(LDFLAGS)
LIB_D_LD  = $(call SUPRESS,LD     $1)$($(TMD)LD) -r --warn-common -o $1 $2 $(LDFLAGS)
KLIB_LD   = $(call SUPRESS,KLD    $1)$(KLD) -r --warn-common -o $1 $2 $(LDFLAGS)

# $1 - target, $2 - source
UCPU_FLAGS := $(if $(filter %D,$(TARGET)),-ggdb,-g -O2)
CC_PARAMS = -pipe -c -Wall $(UCPU_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))
CMN_CXX  = $(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,PCXX   $2)$($(TMD)CXX) -I$(dir $1) -include $(basename \
            $(notdir $(PCH)))_pch_cxx.h,$(call SUPRESS,CXX    $2)$($(TMD)CXX)) $(CC_PARAMS) $(CXXFLAGS)
CMN_CC   = $(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,PCC    $2)$($(TMD)CC) -I$(dir $1) -include $(basename \
            $(notdir $(PCH)))_pch_c.h,$(call SUPRESS,CC     $2)$($(TMD)CC)) $(CC_PARAMS) -std=c99 -pedantic $(CFLAGS)

PCH_CXX  = $(call SUPRESS,PCHCXX $2)$($(TMD)CXX) $(CC_PARAMS) $(CXXFLAGS)
PCH_CC   = $(call SUPRESS,PCHCC  $2)$($(TMD)CC) $(CC_PARAMS) -std=c99 -pedantic $(CFLAGS)

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

KLIB_PARAMS = -pipe -c $(KERN_COMPILE_OPTIONS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)
KLIB_R_CC  = $(if $(filter $2,$(WITH_PCH)),$(call SUPRESS,PKCC   $2)$(KCC) -I$(dir $1) -include $(basename \
              $(notdir $(PCH)))_pch_c.h,$(call SUPRESS,KCC    $2)$(KCC)) $(KLIB_PARAMS) -o $1 $2

PCH_KLIB_R_CC = $(call SUPRESS,PCHKLI $2)$(KCC) $(KLIB_PARAMS) -o $1 $2

KLIB_R_ASM ?= $(call SUPRESS,ASM    $2)$(YASM) -o $1 $2 $(ASMFLAGS)

BISON = $(call SUPRESS,BISON  $2)cd $1; bison -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUPRESS,FLEX   $2)flex -o$1 $2

ifndef NO_PCH

# $1 - EXE,LIB,DLL,KLIB, $2 - $(call FORM_OBJ_DIR,$1,$v), $3 - $(call FORM_TRG,$1,$v), $v - R,P,D
define PCH_TEMPLATE1
TRG_PCH := $(if $($1_PCH),$($1_PCH),$(PCH))
TRG_WITH_PCH := $(WITH_PCH) $($1_WITH_PCH)
$3: PCH := $$(call FIXPATH,$$(TRG_PCH))
$3: WITH_PCH := $$(call FIXPATH,$$(TRG_WITH_PCH))
ifneq ($$(filter %.c,$$(TRG_WITH_PCH)),)
C_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_c.h.gch
$$(C_GCH): $$(CURRENT_DEPS) | $2
	$$(call PCH_$1_$v_CC,$$@,$$(PCH))
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.c,$$(TRG_WITH_PCH)))))): $$(C_GCH)
CLEAN += $$(C_GCH)
endif
ifneq ($$(filter %.cpp,$$(TRG_WITH_PCH)),)
CXX_GCH := $2/$$(basename $$(notdir $$(TRG_PCH)))_pch_cxx.h.gch
$$(CXX_GCH): $$(CURRENT_DEPS) | $2
	$$(call PCH_$1_$v_CXX,$$@,$$(PCH))
$$(addprefix $2/,$$(addsuffix $(OBJ_SUFFIX),$$(basename $$(notdir $$(filter %.cpp,$$(TRG_WITH_PCH)))))): $$(CXX_GCH)
CLEAN += $$(CXX_GCH)
endif
endef

PCH_TEMPLATE2 = $(if $($t),$(if $($t_PCH)$(PCH),$(if $($t_WITH_PCH)$(WITH_PCH),$(foreach \
  v,$(call GET_VARIANTS,$t,VARIANTS_FILTER),$(newline)$(call PCH_TEMPLATE1,$t,$(call FORM_OBJ_DIR,$t,$v),$(call FORM_TRG,$t,$v))))))

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

# $1 - dest dir, $2 - file
define COPY_FILE_RULE
$(empty)
$1/$(notdir $2): $2 | $1
	$$(call SUPRESS,CP     $$@)cp -f$(if $(VERBOSE:0=),v) $$< $$@
endef

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - blddir:      $(BLD_DIR)/DRV_$(DRV)
# $4 - klibs:       $(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))
define DRV_TEMPLATE
$(call ADD_DIR_RULES,$3)
# copy sources
$(foreach x,$2,$(call COPY_FILE_RULE,$3,$x))
# copy klibs
$(foreach x,$4,$(call COPY_FILE_RULE,$3,$(LIB_DIR)/$x))
$(call STD_TARGET_VARS,$1)
# generate Makefile for kbuild
$3/Makefile: | $3
	$$(call SUPRESS,GEN    $$@)echo "obj-m += $(DRV_PREFIX)$(DRV).o" > $$@ && \
  echo "$(DRV_PREFIX)$(DRV)-objs := $(notdir $(2:.c=.o)) $4" >> $$@ && \
  echo "EXTRA_CFLAGS += $(addprefix -D,$(EXTRA_DRV_DEFINES)) $(addprefix -I,$(abspath $(call TRG_INCLUDE,DRV)))" >> $$@
# call kbuild
$3/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX): $(addprefix $3/,$(notdir $2) $4) $(CURRENT_DEPS) | $3/Makefile
	+$$(call SUPRESS,KBUILD $$@)$(KMAKE) V=$(VERBOSE) CC="$(KCC)" LD="$(KLD)" AR="$(AR)" $(addprefix \
  KBUILD_EXTRA_SYMBOLS=,$(KBUILD_EXTRA_SYMBOLS)) -C $(MODULES_PATH) M=$$(patsubst %/,%,$$(dir $$@)) $(addprefix ARCH=,$(ARCH))
$1: $3/$(DRV_PREFIX)$(DRV)$(DRV_SUFFIX) | $(BIN_DIR)
	$$(call SUPRESS,CP     $$@)cp -f$(if $(VERBOSE:0=),v) $$< $$@
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $3
endef

# how to build kernel module
DRV_RULES = $(if $(DRV),$(call DRV_TEMPLATE,$(call FORM_TRG,DRV),$(call \
  TRG_SRC,DRV),$(BLD_DIR)/DRV_$(DRV),$(addprefix $(KLIB_PREFIX),$(addsuffix $(KLIB_SUFFIX),$(KLIBS)))))

# this code is normally evaluated at end of target Makefile
define OS_DEFINE_TARGETS
$(PCH_TEMPLATES)
$(if $(DLL),$(call FORM_TRG,DLL,R): $(call TRG_MAP,DLL))
$(DRV_RULES)
endef
