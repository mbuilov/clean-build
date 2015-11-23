OSTYPE := UNIX

ifneq ($(filter default undefined,$(origin CC)),)
# 64-bit arch: CC="cc -m64"
# 32-bit arch: CC="cc -m32"
CC := cc -m$(if $(filter %64,$(UCPU)),64,32)
endif

ifneq ($(filter default undefined,$(origin CXX)),)
# 64-bit arch: CXX="CC -m64"
# 32-bit arch: CXX="CC -m32"
CXX := CC -m$(if $(filter %64,$(UCPU)),64,32)
endif

ifneq ($(filter default undefined,$(origin AR)),)
AR := ar
endif

ifneq ($(filter default undefined,$(origin TCC)),)
# 64-bit arch: TCC="cc -m64"
# 32-bit arch: TCC="cc -m32"
TCC := cc -m$(if $(filter %64,$(TCPU)),64,32)
endif

ifneq ($(filter default undefined,$(origin TCXX)),)
# 64-bit arch: TCXX="CC -m64"
# 32-bit arch: TCXX="CC -m32"
TCXX := CC -m$(if $(filter %64,$(TCPU)),64,32)
endif

ifneq ($(filter default undefined,$(origin TAR)),)
TAR := ar
endif

ifneq ($(filter default undefined,$(origin KCC)),)
# sparc64: KCC="cc -xregs=no%appl -m64 -xmodel=kernel
# sparc32: KCC="cc -xregs=no%appl -m32
# intel64: KCC="cc -m64 -xmodel=kernel
# intel32: KCC="cc -m32
KCC := cc -m$(if $(filter %64,$(KCPU)),64 -xmodel=kernel,32) $(if $(filter sparc%,$(KCPU)),-xregs=no%appl)
endif

ifneq ($(filter default undefined,$(origin KLD)),)
# 64-bit arch: KLD="ld -64"
KLD := ld $(if $(filter %64,$(KCPU)),-64)
endif

ifndef YASMC
# intel64: YASM="yasm -f elf64 -m amd64"
# imtel32: YASM="yasm -f elf32 -m x86"
YASM := yasm -f $(if $(filter %64,$(KCPU)),elf64,elf32) $(if $(filter x86%,$(KCPU)),-m $(if $(filter %64,$(KCPU)),amd64,x86))
endif

ifndef FLEXC
FLEXC := flex
endif

ifndef BISONC
BISONC := bison
endif

EXE_SUFFIX :=
OBJ_SUFFIX := .o
LIB_PREFIX := lib
LIB_SUFFIX := .a
IMP_PREFIX := lib
IMP_SUFFIX := .so
DLL_PREFIX := lib
DLL_SUFFIX := .so
KLIB_NAME_PREFIX := k_
KLIB_PREFIX := lib$(KLIB_NAME_PREFIX)
KLIB_SUFFIX := .a
DRV_PREFIX :=
DRV_SUFFIX :=

# import library and dll - the same file
DLL_DIR = $(LIB_DIR)
IMP_DIR = $(LIB_DIR)

ifndef OS_PREDEFINES
OS_PREDEFINES := SOLARIS UNIX $(OSVARIANT)
endif
ifndef OS_APPDEFS
OS_APPDEFS := $(if $(filter %64,$(UCPU)),LP64,ILP32) _REENTRANT
endif
ifndef OS_KRNDEFS
OS_KRNDEFS := $(if $(filter %64,$(KCPU)),LP64,ILP32) _KERNEL
endif

# supported target variants:
# R - default variant (position-dependent code for EXE, position-independent code for DLL)
# D - position-independent code in shared libraries (for LIB)
VARIANTS_FILTER = $(if $(filter LIB,$1),D)

# use D-variant of static library for DLL
VARIANT_LIB_MAP = $(if $(filter DLL,$1),D,$2)

# the same default variant of DLL may be linked with EXE or DLL
VARIANT_IMP_MAP := R

# default flags for EXE-linker
ifeq (undefined,$(origin DEF_EXE_FLAGS))
DEF_EXE_FLAGS :=
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

# default flags for shared objects
ifeq (undefined,$(origin DEF_SHARED_FLAGS))
DEF_SHARED_FLAGS := -ztext -xnolib
endif

# $1 - target, $2 - objects, $3 - variant
CMN_LIBS = $(DEF_SHARED_FLAGS) -o $1 $2 $(addprefix -R,$(strip $(RPATH))) $(if $(strip $(LIBS)$(DLLS)),$(addprefix \
           -L,$(LIB_DIR)) $(addprefix -l$(call VARIANT_LIB_PREFIX,$3),$(LIBS)) $(addprefix \
           -l,$(DLLS))) $(addprefix -L,$(SYSLIBPATH)) $(addprefix -l,$(SYSLIBS)) $(if \
           $(filter CXX,$(COMPILER)),-lCstd -lCrun) -lc $(LDFLAGS)
EXE_R_LD = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_EXE_FLAGS) $(call CMN_LIBS,$1,$2,R)
DLL_R_LD = $(call SUPRESS,$(TMD)LD,$1)$($(TMD)$(COMPILER)) $(DEF_SO_FLAGS) $(addprefix -M,$(MAP)) $(call CMN_LIBS,$1,$2,D)
LIB_R_LD = $(call SUPRESS,$(TMD)AR,$1)$($(TMD)AR) $(DEF_AR_FLAGS) $1 $2
LIB_D_LD = $(LIB_R_LD)
KLIB_LD  = $(call SUPRESS,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(LDFLAGS)
DRV_LD   = $(call SUPRESS,KLD,$1)$(KLD) $(DEF_KLD_FLAGS) -o $1 $2 $(if \
            $(KLIBS),$(addprefix -L,$(LIB_DIR)) $(addprefix -l$(KLIB_NAME_PREFIX),$(KLIBS))) $(LDFLAGS)

# $2 - target, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
SED_DEPS_SCRIPT = 1x;1s@.*@$2: $3 \\@;1x;/^COMPILATION_FAILED$$/H;s@^COMPILATION_FAILED$$@/&@;/^$(tab)*\//!p;/^$(tab)*\//!s@.*@|@;s@^/COMPILATION_FAILED$$@|@;/^|/!s@^$(tab)*@@;$(subst \
$(space),,$(foreach x,$5,s@^$x.*@|@;))/^|/!H;/^|/!s@.*@&:@;/^|/!x;/^|/!s@.*@& \\@;/^|/!x;$$x;$$H;$$s@.*@@;$$H;$$x;$$s@^|@@;/^|/d;w $4

# $1 - compiler with options, $2 - target, $3 - source, $4 - $(basename $2).d, $5 - prefixes of system includes
ifdef NO_DEPS
WRAP_COMPILER = $1
else
WRAP_COMPILER = ($1 -H 2>&1 || echo COMPILATION_FAILED) | sed -n '$(SED_DEPS_SCRIPT)' && if grep COMPILATION_FAILED $4 > /dev/null; then rm $4 && false; fi
endif

UDEPS_INCLUDE_FILTER ?= /usr/include/

ifdef DEBUG
DEF_APP_FLAGS := -g -DDEBUG
else
DEF_APP_FLAGS := -O
endif

ifeq (undefined,$(origin APP_FLAGS))
APP_FLAGS := $(DEF_APP_FLAGS)
endif

# disable some C++ compiler warnings
# badargtype2w - (Anachronism) when passing pointers to functions
# wbadasg      - (Anachronism) assigning extern "C" ...

ifeq (undefined,$(origin DEF_CXXFLAGS))
DEF_CXXFLAGS := -erroff=badargtype2w,wbadasg
endif

ifeq (undefined,$(origin DEF_CFLAGS))
DEF_CFLAGS:=
endif

# $1 - target, $2 - source, $3 - aux flags
CC_PARAMS = $(APP_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE))
CMN_CC   = $(call SUPRESS,$(TMD)CC,$2)$(call \
  WRAP_COMPILER,$($(TMD)CC) $(CC_PARAMS) $(DEF_CFLAGS) $(CFLAGS) -c -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))
CMN_CXX  = $(call SUPRESS,$(TMD)CXX,$2)$(call \
  WRAP_COMPILER,$($(TMD)CXX) $(CC_PARAMS) $(DEF_CXXFLAGS) $(CXXFLAGS) -c -o $1 $2 $3,$1,$2,$(basename $1).d,$(UDEPS_INCLUDE_FILTER))

EXE_R_CXX = $(CMN_CXX)
EXE_R_CC  = $(CMN_CC)
LIB_R_CXX = $(EXE_R_CXX)
LIB_R_CC  = $(EXE_R_CC)
DLL_R_CXX = $(call CMN_CXX,$1,$2,-KPIC)
DLL_R_CC  = $(call CMN_CC,$1,$2,-KPIC)
LIB_D_CXX = $(DLL_R_CXX)
LIB_D_CC  = $(DLL_R_CC)

KDEPS_INCLUDE_FILTER ?= /usr/include/

ifdef DEBUG
DEF_KERN_FLAGS := -g -DDEBUG
else
DEF_KERN_FLAGS := -O
endif

ifeq (undefined,$(origin KERN_FLAGS))
KERN_FLAGS := $(DEF_KERN_FLAGS)
endif

KCC_PARAMS = $(KERN_FLAGS) $(call SUBST_DEFINES,$(addprefix -D,$(DEFINES))) $(addprefix -I,$(INCLUDE)) $(CFLAGS)
KLIB_R_CC = $(call SUPRESS,KCC,$2)$(call WRAP_COMPILER,$(KCC) $(KCC_PARAMS) -c -o $1 $2,$1,$2,$(basename $1).d,$(KDEPS_INCLUDE_FILTER))
DRV_R_CC  = $(KLIB_R_CC)

KLIB_R_ASM ?= $(call SUPRESS,ASM,$2)$(YASMC) -o $1 $2 $(ASMFLAGS)

BISON = $(call SUPRESS,BISON,$2)cd $1; $(BISONC) -d --fixed-output-files $(abspath $2)
FLEX  = $(call SUPRESS,FLEX,$2)$(FLEXC) -o$1 $2

# $1 - target file: $(call FORM_TRG,DRV)
# $2 - sources:     $(call TRG_SRC,DRV)
# $3 - deps:        $(call TRG_DEPS,DRV)
# $4 - objdir:      $(call FORM_OBJ_DIR,DRV)
# $5 - objects:     $(addprefix $4/,$(call OBJS,$2))
define DRV_TEMPLATE
NEEDED_DIRS += $4
$(call OBJ_RULES,DRV,CC,$(filter %.c,$2),$3,$4)
$(call OBJ_RULES,DRV,ASM,$(filter %.asm,$2),$3,$4)
$(call STD_TARGET_VARS,$1)
$1: LIB_DIR    := $(LIB_DIR)
$1: KLIBS      := $(KLIBS)
$1: INCLUDE    := $(call TRG_INCLUDE,DRV)
$1: DEFINES    := $(KRNDEFS) $(DEFINES) $(DRV_DEFINES)
$1: CFLAGS     := $(CFLAGS) $(DRV_CFLAGS)
$1: ASMFLAGS   := $(ASMFLAGS) $(DRV_ASMFLAGS)
$1: LDFLAGS    := $(LDFLAGS) $(DRV_LDFLAGS)
$1: $(addsuffix $(KLIB_SUFFIX),$(addprefix $(LIB_DIR)/$(KLIB_PREFIX),$(KLIBS))) $5 | $(BIN_DIR) $(ORDER_DEPS)
	$$(call DRV_LD,$$@,$$(filter %$(OBJ_SUFFIX),$$^))
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1 $5
endef

# how to build driver
DRV_RULES1 = $(call DRV_TEMPLATE,$1,$2,$3,$4,$(addprefix $4/,$(call OBJS,$2)))
DRV_RULES = $(if $(DRV),$(call DRV_RULES1,$(call FORM_TRG,DRV),$(call TRG_SRC,DRV),$(call TRG_DEPS,DRV),$(call FORM_OBJ_DIR,DRV)))

# this code is normally evaluated at end of target Makefile
define OS_DEFINE_TARGETS
$(if $(DLL),$(call FORM_TRG,DLL,R): $(call TRG_MAP,DLL))
$(DRV_RULES)
endef