OSTYPE := UNIX

ifneq ($(filter default undefined,$(origin CC)),)
# 64-bit arch: CC="cc -m64"
# 32-bit arch: CC="cc -m32"
CC := cc -m$(if $(UCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin CXX)),)
# 64-bit arch: CXX="CC -m64"
# 32-bit arch: CXX="CC -m32"
CXX := CC -m$(if $(UCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin AR)),)
AR := ar
endif

ifneq ($(filter default undefined,$(origin TCC)),)
# 64-bit arch: TCC="cc -m64"
# 32-bit arch: TCC="cc -m32"
TCC := cc -m$(if $(TCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin TCXX)),)
# 64-bit arch: TCXX="CC -m64"
# 32-bit arch: TCXX="CC -m32"
TCXX := CC -m$(if $(TCPU:%64=),32,64)
endif

ifneq ($(filter default undefined,$(origin TAR)),)
TAR := ar
endif

ifneq ($(filter default undefined,$(origin KCC)),)
# sparc64: KCC="cc -xregs=no%appl -m64 -xmodel=kernel
# sparc32: KCC="cc -xregs=no%appl -m32
# intel64: KCC="cc -m64 -xmodel=kernel
# intel32: KCC="cc -m32
KCC := cc -m$(if $(KCPU:%64=),32,64 -xmodel=kernel)$(if $(filter sparc%,$(KCPU)), -xregs=no%appl)
endif

ifneq ($(filter default undefined,$(origin KLD)),)
# 64-bit arch: KLD="ld -64"
KLD := ld$(if $(filter %64,$(KCPU)), -64)
endif

ifndef YASMC
# intel64: YASM="yasm -f elf64 -m amd64"
# imtel32: YASM="yasm -f elf32 -m x86"
YASM := yasm -f $(if $(KCPU:%64=),elf32,elf64)$(if $(filter x86%,$(KCPU)), -m $(if $(KCPU:%64=),x86,amd64))
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
LIB_SUFFIX := .a    # static library (archive)
IMP_PREFIX := lib
IMP_SUFFIX := .so   # implementaton library for dll, the same as dll itself
DLL_PREFIX := lib
DLL_SUFFIX := .so   # dynamic-loaded library
KLIB_NAME_PREFIX := k_
KLIB_PREFIX := lib$(KLIB_NAME_PREFIX)
KLIB_SUFFIX := .a   # kernel-mode static library
DRV_PREFIX :=
DRV_SUFFIX :=       # kernel module
endif

# import library and dll - the same file
# NOTE: DLL_DIR and IMP_DIR must be recursive because $(LIB_DIR) have different values in TOOL-mode and non-TOOL mode
DLL_DIR = $(LIB_DIR)
IMP_DIR = $(LIB_DIR)

# solaris variant, such as SOLARIS9,SOLARIS10,SOLARIS11 and so on
# note: empty (generic variant) by default
ifndef OSVARIANT
OSVARIANT:=
endif

# standard defines
OS_PREDEFINES ?= $(OSVARIANT) SOLARIS UNIX

# application-level and kernel-level defines
# note: OS_APPDEFS and OS_KRNDEFS are may be defined as empty
ifeq (undefined,$(origin OS_APPDEFS))
OS_APPDEFS := $(if $(UCPU:%64=),ILP32,LP64) _REENTRANT
endif
ifeq (undefined,$(origin OS_KRNDEFS))
OS_KRNDEFS := $(if $(KCPU:%64=),ILP32,LP64) _KERNEL
endif

# supported target variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if $(filter LIB,$1),D)

# for $(DEP_LIB_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $l - dependent static library name
# use the same variant (R) of static library as target EXE (R)
# always use D-variant of static library for DLL
VARIANT_LIB_MAP ?= $(if $(filter DLL,$1),D,$2)

# for $(DEP_IMP_SUFFIX) from $(MTOP)/c.mk:
# $1 - target EXE,DLL
# $2 - variant of target EXE or DLL
# $d - dependent dynamic library name
# the same one default variant (R) of DLL may be linked with R-EXE or R-DLL
ifeq (undefined,$(origin VARIANT_IMP_MAP))
VARIANT_IMP_MAP := R
endif

# default flags for shared objects
ifeq (undefined,$(origin DEF_SHARED_FLAGS))
DEF_SHARED_FLAGS := -ztext -xnolib
endif

# default flags for EXE-linker
ifeq (undefined,$(origin DEF_EXE_FLAGS))
DEF_EXE_FLAGS:=
endif

# default flags for shared objects linker
ifeq (undefined,$(origin DEF_SO_FLAGS))
DEF_SO_FLAGS := -zdefs -G
endif

# default flags for kernel library linker
ifeq (undefined,$(origin DEF_KLD_FLAGS))
DEF_KLD_FLAGS := -r
endif

# default flags for static library archiver
ifeq (undefined,$(origin DEF_AR_FLAGS))
DEF_AR_FLAGS := -c -r
endif

# runtime-path option for EXE or DLL
# target-specfic: RPATH
RPATH_OPTION ?= $(addprefix -R,$(strip $(RPATH)))

# standard C libraries
ifeq (undefined,$(origin DEF_C_LIBS))
DEF_C_LIBS := c
endif

# standard C++ libraries
ifeq (undefined,$(origin DEF_CXX_LIBS))
DEF_CXX_LIBS := Cstd Crun
endif

# common linker options for EXE or DLL
# $1 - target, $2 - objects, $3 - variant
# target-specfic: LIBS, DLLS, LIB_DIR, SYSLIBPATH, SYSLIBS, COMPILER, LDFLAGS
CMN_LIBS ?= -o $1 $2 $(DEF_SHARED_FLAGS) $(RPATH_OPTION) $(if \
  $(strip $(LIBS)$(DLLS)),-L$(LIB_DIR) $(addprefix -l,$(addsuffix $(call \
  VARIANT_LIB_SUFFIX,$3),$(LIBS)) $(DLLS))) $(addprefix -L,$(SYSLIBPATH)) $(addprefix -l,$(SYSLIBS) $(if \
  $(filter CXX,$(COMPILER)),$(DEF_CXX_LIBS)) $(DEF_C_LIBS)) $(LDFLAGS)

# what to export from a dll
# target-specfic: MAP
VERSION_SCRIPT_OPTION ?= $(addprefix -M,$(MAP))

# different linkers
# $1 - target, $2 - objects
# target-specfic: TMD, COMPILER, MAP
EXE_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
DLL_R_LD ?= $(call SUP,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(VERSION_SCRIPT_OPTION) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD ?= $(call SUP,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_D_LD ?= $(LIB_R_LD)
KLIB_LD  ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)
DRV_LD   ?= $(call SUP,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(if \
  $(KLIBS),-L$(LIB_DIR) $(addprefix -l$(KLIB_NAME_PREFIX),$(KLIBS))) $(LDFLAGS)

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin UDEPS_INCLUDE_FILTER))
UDEPS_INCLUDE_FILTER := /usr/include/
endif

# $(SED) script to generate dependencies file from C compiler output
# $2 - target object file, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes to filter out
SED_DEPS_SCRIPT ?= 1x;1s@.*@$2: $3 \\@;1x;\
/^COMPILATION_FAILED$$/H;s@^COMPILATION_FAILED$$@/&@;\
/^$(tab)*\//!p;/^$(tab)*\//!s@.*@|@;s@^/COMPILATION_FAILED$$@|@;/^|/!s@^$(tab)*@@;\
$(foreach x,$5,s@^$x.*@|@;)/^|/!H;/^|/!s@.*@&:@;/^|/!x;/^|/!s@.*@& \\@;/^|/!x;$$x;$$H;$$s@.*@@;$$H;$$x;$$s@^|@@;/^|/d;w $4

# WRAP_COMPILER - either just call compiler or call compiler and auto-generate dependencies
# $1 - compiler with options, $2 - target, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER ?= ($1 -H 2>&1 || echo COMPILATION_FAILED) | \
sed -n '$(SED_DEPS_SCRIPT)' && if grep COMPILATION_FAILED $4 > /dev/null; then rm $4 && false; fi
endif

# flags for application level C-compiler
ifeq (undefined,$(origin APP_FLAGS))
ifdef DEBUG
APP_FLAGS := -g -DDEBUG
else
APP_FLAGS := -O
endif
endif

# default flags for C++ compiler
ifeq (undefined,$(origin DEF_CXXFLAGS))
# disable some C++ warnings:
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg
endif

# default flags for C compiler
ifeq (undefined,$(origin DEF_CFLAGS))
DEF_CFLAGS:=
endif

# common options for applicaton-level C++ and C compilers
# $1 - target, $2 - source
# target-specfic: DEFINES, INCLUDE
CC_PARAMS ?= -c $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))

# C++ and C compilers
# $1 - target, $2 - source, $3 - aux flags
# target-specfic: TMD, CXXFLAGS, CFLAGS
CMN_CXX ?= $(call SUP,$(TMD)CXX,$2)$(call \
  WRAP_COMPILER,$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CC  ?= $(call SUP,$(TMD)CC,$2)$(call \
  WRAP_COMPILER,$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS) -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

# different compilers
# $1 - target, $2 - source
EXE_R_CXX ?= $(CMN_CXX)
EXE_R_CC  ?= $(CMN_CC)
LIB_R_CXX ?= $(EXE_R_CXX)
LIB_R_CC  ?= $(EXE_R_CC)
DLL_R_CXX ?= $(call CMN_CXX,$1,$2,-KPIC)
DLL_R_CC  ?= $(call CMN_CC,$1,$2,-KPIC)
LIB_D_CXX ?= $(DLL_R_CXX)
LIB_D_CC  ?= $(DLL_R_CC)

# $(SED) expression to filter-out system files while dependencies generation
ifeq (undefined,$(origin KDEPS_INCLUDE_FILTER))
KDEPS_INCLUDE_FILTER := /usr/include/
endif

# flags for kernel level C-compiler
ifeq (undefined,$(origin KERN_FLAGS))
ifdef DEBUG
KERN_FLAGS := -g -DDEBUG
else
KERN_FLAGS := -O
endif
endif

# common options for kernel-level C compiler
# $1 - target, $2 - source
# target-specfic: DEFINES, INCLUDE, CFLAGS
KCC_PARAMS ?= -c $(KERN_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)

# kernel-level C compilers
# $1 - target, $2 - source
KLIB_R_CC ?= $(call SUP,KCC,$2)$(call WRAP_COMPILER,$(KCC) $(KCC_PARAMS) -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
DRV_R_CC  ?= $(KLIB_R_CC)

# kernel-level assembler
# $1 - target, $2 - source
# target-specfic: ASMFLAGS
KLIB_R_ASM ?= $(call SUP,ASM,$2)$(YASMC) -o $1 $2 $(ASMFLAGS)
DRV_R_ASM  ?= $(KLIB_R_ASM)

# $1 - target, $2 - source
BISON = $(call SUP,BISON,$2)cd $1; $(BISONC) -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUP,FLEX,$2)$(FLEXC) -o$1 $2

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
# note: there are SYSLIBS and SYSLIBPATH for the driver
define DRV_TEMPLATE
NEEDED_DIRS += $4
$(call OBJ_RULES,DRV,CC,$(filter %.c,$2),$3,$4)
$(call OBJ_RULES,DRV,ASM,$(filter %.asm,$2),$3,$4)
$(STD_TARGET_VARS)
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(call TRG_INCLUDE,DRV)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(DRV_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DRV_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(DRV_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DRV_LDFLAGS)
$1: $(addsuffix $(KLIB_SUFFIX),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS))) $5
	$$(call DRV_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
CLEAN += $5
endef

# how to build driver
DRV_RULES1 = $(call DRV_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DRV_RULES = $(if $(DRV),$(call DRV_RULES1,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call TRG_DEPS,DRV),$(call FORM_OBJ_DIR,DRV)))

# this code is evaluated from $(DEFINE_TARGETS)
define OS_DEFINE_TARGETS
$(if $(DLL),$(call FORM_TRG,DLL,R): $(call TRG_MAP,DLL))
$(DRV_RULES)
endef

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CC CXX AR TCC TCXX TAR KCC KLD YASM FLEXC BISONC \
  EXE_SUFFIX OBJ_SUFFIX LIB_PREFIX LIB_SUFFIX IMP_PREFIX IMP_SUFFIX \
  DLL_PREFIX DLL_SUFFIX KLIB_NAME_PREFIX KLIB_PREFIX KLIB_SUFFIX DRV_PREFIX DRV_SUFFIX \
  DLL_DIR IMP_DIR OS_PREDEFINES OS_APPDEFS OS_KRNDEFS VARIANTS_FILTER \
  VARIANT_LIB_MAP VARIANT_IMP_MAP DEF_SHARED_FLAGS DEF_EXE_FLAGS DEF_SO_FLAGS DEF_KLD_FLAGS DEF_AR_FLAGS \
  RPATH_OPTION DEF_C_LIBS DEF_CXX_LIBS CMN_LIBS VERSION_SCRIPT_OPTION EXE_R_LD DLL_R_LD LIB_R_LD LIB_D_LD KLIB_LD DRV_LD \
  UDEPS_INCLUDE_FILTER SED_DEPS_SCRIPT WRAP_COMPILER APP_FLAGS DEF_CXXFLAGS DEF_CFLAGS CC_PARAMS CMN_CXX CMN_CC \
  EXE_R_CXX EXE_R_CC LIB_R_CXX LIB_R_CC DLL_R_CXX DLL_R_CC LIB_D_CXX LIB_D_CC KDEPS_INCLUDE_FILTER KERN_FLAGS \
  KCC_PARAMS KLIB_R_CC DRV_R_CC KLIB_R_ASM DRV_R_ASM BISON FLEX DRV_TEMPLATE DRV_RULES1 DRV_RULES)