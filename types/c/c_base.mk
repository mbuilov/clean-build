#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules for compiling C/C++/Assembler source files

# Note: $(CLEAN_BUILD_DIR)/core/_defs.mk must be included prior this file

# included by:
#  $(CLEAN_BUILD_DIR)/types/_c.mk
#  $(CLEAN_BUILD_DIR)/types/_kc.mk

# by default, enable use of C/C++ precompiled headers
NO_PCH:=

# object file suffix
# note: may overridden by selected C/C++ compiler
OBJ_SUFFIX := .o

# C/C++ sources masks
CC_MASK  := %.c
CXX_MASK := %.cpp

# form name of dependent library for given variant of the target
# $1 - target type: EXE,DLL,...
# $2 - variant of target EXE,DLL,...: R,P,S,... (if empty, assume R)
# $3 - dependency name, e.g. mylib or mylib/flag1/flag2/...
# $4 - dependency type: LIB,DLL,...
# note: used by DEP_LIBS/DEP_IMPS macros from $(CLEAN_BUILD_DIR)/types/_c.mk
# example:
#  always use D-variant of static library if target is a DLL,
#  else use the same variant (R or P) of static library as target (EXE) (for example for P-EXE use P-LIB)
#  LIB_DEP_MAP = $(if $(filter DLL,$1),D,$2)
DEP_LIBRARY = $(firstword $(subst /, ,$3))$(call VARIANT_SUFFIX,$4,$($4_DEP_MAP))

# add source-dependencies for object files
# $1 - source dependencies list, e.g. dir1/src1/| dir2/dep1| dep2 dir3/src2/| dep3
# $2 - objdir
ADD_OBJ_SDEPS = $(subst |, ,$(subst $(space),$(newline),$(join \
  $(patsubst %,$2/%$(OBJ_SUFFIX):,$(basename $(notdir $(filter %/|,$1)))),$(subst | ,|,$(filter-out %/|,$1)))))

# call compiler: OBJ_CXX,OBJ_CC,OBJ_ASM,...
# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $5 - objects: $(patsubst %,$4/%$(OBJ_SUFFIX),$(basename $(notdir $2)))
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# returns: list of object files
# note: postpone expansion of ORDER_DEPS to optimize parsing
define OBJ_RULES_BODY
$5
$(subst $(space),$(newline),$(join $(addsuffix :,$5),$2))
$(call ADD_OBJ_SDEPS,$(subst |,| ,$(call FILTER_SDEPS,$2,$3)),$4)
$5:| $4 $$(ORDER_DEPS)
	$$(call OBJ_$1,$$@,$$<,$t,$v)
endef
ifndef NO_DEPS
$(call define_append,OBJ_RULES_BODY,$(newline)-include $$(addsuffix .d,$$5))
endif

# rule that defines how to build objects from sources
# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# returns: list of object files
ifndef TOCLEAN
OBJ_RULES = $(if $2,$(call OBJ_RULES_BODY,$1,$2,$3,$4,$(patsubst %,$4/%$(OBJ_SUFFIX),$(basename $(notdir $2)))))
else
# note: cleanup auto-generated dependencies
OBJ_RULES1 = $(call TOCLEAN,$1 $(addsuffix .d,$1))
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$(patsubst %,$4/%$(OBJ_SUFFIX),$(basename $(notdir $2)))))
endif

# which compiler type to use for the target: CXX or CC?
# note: CXX compiler may compile C sources, but also links standard C++ libraries (like libstdc++)
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources: $(TRG_SRC)
# $t - target type: EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
TRG_COMPILER = $(if $(filter $(CXX_MASK),$2),CXX,CC)

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# $t - target type: EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: assume INCLUDE paths do not contain spaces
TRG_INCLUDE = $(call fixpath,$(INCLUDE))

# defines for the target
# $t - target type: EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: this macro may be overridden in project configuration makefile, for example:
# TRG_DEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) $(foreach \
#   cpu,$($(if $(filter DRV KLIB KDLL,$t),K,$(TMD))CPU),$(if \
#   $(filter sparc% mips% ppc%,$(cpu)),B_ENDIAN,L_ENDIAN) $(if \
#   $(filter arm% sparc% mips% ppc%,$(cpu)),ADDRESS_NEEDALIGN)) $(DEFINES)
TRG_DEFINES = $(DEFINES)

# make list of sources for the target, used by TRG_SRC
GET_SOURCES = $(SRC) $(WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC = $(call fixpath,$(GET_SOURCES))

# make absolute paths of source dependencies
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS))

# make compiler options string to specify included headers search path
# note: assume there are no spaces in include paths
# note: MK_INCLUDE_OPTION is overridden in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk
MK_INCLUDE_OPTION = $(addprefix -I,$1)

# helper macro for passing define value containing special symbols (e.g. quoted string) to C-compiler
# result of this macro will be processed by DEFINE_ESCAPE_VALUE
# example: DEFINES := MY_MESSAGE=$(call DEFINE_SPECIAL,"my message")
DEFINE_SPECIAL = $(unspaces)

# process result of DEFINE_SPECIAL to make shell-escaped value of define for passing it to C-compiler
# $1 - define_name
# $d - $1="1$(space)2"
# returns: define_name='"1 2"'
DEFINE_ESCAPE_VALUE = $1=$(call SHELL_ESCAPE,$(call tospaces,$(patsubst $1=%,%,$d)))

# process result of DEFINE_SPECIAL to make shell-escaped values of defines for passing them to C-compiler
# $1 - list of defines
# example: -DA=1 -DB="b" -DC="1$(space)2"
# returns: -DA=1 -DB='"b"' -DC='"1 2"'
DEFINE_ESCAPE_VALUES = $(foreach d,$1,$(call DEFINE_ESCAPE_VALUE,$(firstword $(subst =, ,$d))))

# make compiler options string to specify defines
# note: MK_DEFINES_OPTION1 is overridden in $(CLEAN_BUILD_DIR)/compilers/msvc/cmn.mk
MK_DEFINES_OPTION1 = $(addprefix -D,$1)
MK_DEFINES_OPTION = $(call DEFINE_ESCAPE_VALUES,$(MK_DEFINES_OPTION1))

# C/C++ compiler and linker flags for the target
# $t - target type: EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: these flags should contain values of standard user-defined C/C++ compilers and linker flags, such as
#  CFLAGS, CXXFLAGS, LDFLAGS and so on, that are normally taken from the environment (in project configuration makefile),
#  their default values should be set in compiler-specific makefile, e.g.: $(CLEAN_BUILD_DIR)/compilers/gcc.mk.
TRG_CFLAGS   = $(call $t_CFLAGS,$v)
TRG_CXXFLAGS = $(call $t_CXXFLAGS,$v)
TRG_LDFLAGS  = $(call $t_LDFLAGS,$v)

# list of target types that may be built from C/C++/Assembler sources
# note: appended in:
#  $(CLEAN_BUILD_DIR)/types/_c.mk
#  $(CLEAN_BUILD_DIR)/types/_kc.mk
C_TARGETS:=

# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(TRG_SRC)
# $3 - $(TRG_SDEPS)
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
C_RULES_TEMPLv = $($t_TEMPLATE)

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $t - EXE,DLL,...
C_RULES_TEMPLt = $(foreach v,$(call GET_VARIANTS,$t),$(call \
  C_RULES_TEMPLv,$(call FORM_TRG,$t,$v),$1,$2,$(call FORM_OBJ_DIR,$t,$v))$(newline))

# expand target rules template $t_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
C_RULES_TEMPL = $(foreach t,$(C_TARGETS),$(if $($t),$(C_RULES_TEMPLt)))

# redefine macro $1 with new value $2 as target-specific variable bound to namespace identified by target-specific variable TRG,
#  this is usable when it is needed to redefine some variable (e.g. DEF_CFLAGS) as target-specific (e.g. for an EXE), allow
#  inheritance of that variable to dependent objects (of EXE), but prevent inheritance to dependent DLLs and their objects
# note: target-specific variable TRG, those value is used as a namespace name, defined by C_BASE_TEMPLATE
# example: $(call C_REDEFINE,DEF_CFLAGS,-Wall)
C_REDEFINE = $(foreach t,$(C_TARGETS),$(if $($t),$(foreach v,$(call GET_VARIANTS,$t),$(eval $(call \
  FORM_TRG,$t,$v): $$(call keyed_redefine,$$1,TRG,$(notdir $(call FORM_OBJ_DIR,$t,$v)),$$2)))))

# base template for C/C++ targets
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - target type: EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: define target-specific variable TRG - an unique namespace name, for use in C_REDEFINE
# note: STD_TARGET_VARS also changes CB_NEEDED_DIRS, so do not remember its new value here
define C_BASE_TEMPLATE
$1:TRG := $(notdir $4)
CB_NEEDED_DIRS+=$4
$(STD_TARGET_VARS)
$1:$(call OBJ_RULES,CC,$(filter $(CC_MASK),$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter $(CXX_MASK),$2),$3,$4)
$1:COMPILER  := $(TRG_COMPILER)
$1:VINCLUDE  := $(call MK_INCLUDE_OPTION,$(TRG_INCLUDE))
$1:VDEFINES  := $(call MK_DEFINES_OPTION,$(TRG_DEFINES))
$1:VCFLAGS   := $(SYSCFLAGS) $(TRG_CFLAGS)
$1:VCXXFLAGS := $(SYSCFLAGS) $(TRG_CXXFLAGS)
$1:VLDFLAGS  := $(SYSLDFLAGS) $(TRG_LDFLAGS)
endef

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define C_PREPARE_BASE_VARS
MODVER:=$(PRODUCT_VER)
SRC:=
WITH_PCH:=
SDEPS:=
INCLUDE:=
DEFINES:=
SYSCFLAGS:=
SYSLDFLAGS:=
LIBS:=
DLLS:=
endef

# optimization
$(call try_make_simple,C_PREPARE_BASE_VARS,PRODUCT_VER)

# this code is normally evaluated at end of target makefile
C_DEFINE_RULES = $(call C_RULES_TEMPL,$(TRG_SRC),$(TRG_SDEPS))

# do not support assembler by default
# note: ASSEMBLER_SUPPORT may be overridden in project configuration makefile
# note: if ASSEMBLER_SUPPORT is defined, then must also be defined different assemblers, called from $(OBJ_RULES_BODY):
#  EXE_R_ASM, LIB_R_ASM, LIB_D_ASM, etc. - for all supported target variants
ASSEMBLER_SUPPORT:=

# ensure ASSEMBLER_SUPPORT variable is non-recursive (simple)
override ASSEMBLER_SUPPORT := $(ASSEMBLER_SUPPORT)

ifdef ASSEMBLER_SUPPORT

# Assembler sources mask
ASM_MASK := %.asm

# user-defined assembler flags,
#  normally taken from the environment (in project configuration makefile)
# note: assume assembler is not used in tool mode
ASMFLAGS:=

# assembler flags for the target
# $t - target type: EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: these flags should contain value of ASMFLAGS - standard user-defined assembler flags,
#  that are normally taken from the environment (in project configuration makefile),
#  their default values should be set in assembler-specific makefile, e.g.: $(CLEAN_BUILD_DIR)/compilers/nasm.mk.
TRG_ASMFLAGS = $($t_ASMFLAGS)

# template for adding assembler support
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - target type: EXE,DLL,LIB...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
define ASM_TEMPLATE
$1:$(call OBJ_RULES,ASM,$(filter $(ASM_MASK),$2),$3,$4)
$1:VASMFLAGS := $(TRG_ASMFLAGS)
endef

# patch C_BASE_TEMPLATE
$(call define_append,C_BASE_TEMPLATE,$(newline)$(value ASM_TEMPLATE))

# tool color
ASM_COLOR := [37m

endif # ASSEMBLER_SUPPORT

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_PCH OBJ_SUFFIX CC_MASK CXX_MASK \
  DEP_LIBRARY ADD_OBJ_SDEPS OBJ_RULES_BODY=t;v OBJ_RULES1=t;v OBJ_RULES=t;v \
  TRG_COMPILER=t;v TRG_INCLUDE=t;v;INCLUDE TRG_DEFINES=t;v;DEFINES GET_SOURCES=SRC;WITH_PCH TRG_SRC TRG_SDEPS=SDEPS \
  MK_INCLUDE_OPTION DEFINE_SPECIAL DEFINE_ESCAPE_VALUE DEFINE_ESCAPE_VALUES MK_DEFINES_OPTION1 MK_DEFINES_OPTION \
  TRG_CFLAGS=t;v TRG_CXXFLAGS=t;v TRG_LDFLAGS=t;v C_TARGETS C_RULES_TEMPLv=t;v C_RULES_TEMPLt=t C_RULES_TEMPL \
  C_REDEFINE C_BASE_TEMPLATE=t;v;$$t C_PREPARE_BASE_VARS C_DEFINE_RULES \
  ASM_MASK ASMFLAGS TRG_ASMFLAGS=t;v ASM_TEMPLATE ASM_COLOR)

# protect variables from modifications in target makefiles
# note: do not trace calls to ASSEMBLER_SUPPORT variable because it is used in ifdefs
$(call SET_GLOBAL,ASSEMBLER_SUPPORT,0)

# KCC_COLOR  := [31m
# KCXX_COLOR := [36m
# KAR_COLOR  := [32m
# KLD_COLOR  := [33m
# KXLD_COLOR := [37m