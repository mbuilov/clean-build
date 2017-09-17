#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules for compiling C/C++/Assembler files

# included by:
#  $(CLEAN_BUILD_DIR)/impl/_c.mk
#  $(CLEAN_BUILD_DIR)/impl/_kc.mk 

ifeq (,$(filter-out undefined environment,$(origin EXTRACT_SDEPS)))
include $(dir $(lastword $(MAKEFILE_LIST)))../core/_defs.mk
endif

# by default, enable compiling with precompiled headers
NO_PCH:=

# object file suffix
# note: may overridden by selected C/C++ compiler
OBJ_SUFFIX := .o

# C/C++ sources masks
CC_MASK  := %.c
CXX_MASK := %.cpp

# get suffix of dependent library for given variant of the target
# $1 - target type: EXE,DLL,...
# $2 - variant of target EXE,DLL,...: R,P,S,... (if empty, assume R)
# $3 - dependency type: LIB,DLL,...
# example:
#  always use D-variant of static library for DLL
#  else use the same variant (R or P) of static library as target (EXE) (for example for P-EXE use P-LIB)
#  LIB_DEP_MAP = $(if $(filter DLL,$1),D,$2)
DEP_SUFFIX = $(call VARIANT_SUFFIX,$3,$($3_DEP_MAP))

# add source-dependencies for an object file
# $1 - objdir
# $2 - source dependencies
# $x - source
ADD_OBJ_SDEPS = $(if $2,$(newline)$1/$(basename $(notdir $x))$(OBJ_SUFFIX): $2)

# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $5 - $(addsuffix $(OBJ_SUFFIX),$(addprefix $4/,$(basename $(notdir $2))))
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,S,...
# returns: list of object files
# note: postpone expansion of ORDER_DEPS to optimize parsing
define OBJ_RULES_BODY
$5
$(subst $(space),$(newline),$(join $(addsuffix :,$5),$2))$(if \
  $3,$(foreach x,$2,$(call ADD_OBJ_SDEPS,$4,$(call EXTRACT_SDEPS,$x,$3))))
$5:| $4 $$(ORDER_DEPS)
	$$(call $t_$1,$$@,$$<,$v)
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
# $v - non-empty variant: R,P,S,...
# returns: list of object files
ifndef TOCLEAN
OBJ_RULES = $(if $2,$(call OBJ_RULES_BODY,$1,$2,$3,$4,$(addprefix \
  $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2))))))
else
# note: cleanup auto-generated dependencies
OBJ_RULES1 = $(call TOCLEAN,$1 $(addsuffix .d,$1))
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$(addprefix \
  $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2))))))
endif

# which compiler type to use for the target: CXX or CC?
# note: CXX compiler may compile C sources, but also links standard C++ libraries (like libstdc++)
# $1     - target file: $(call FORM_TRG,$t,$v)
# $2     - sources: $(TRG_SRC)
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_COMPILER = $(if $(filter $(CXX_MASK),$2),CXX,CC)

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
# note: do not touch paths in $(SYSINCLUDE) - assume they are absolute
# note: $(SYSINCLUDE) paths are normally filtered-out while .d dependency file generation
TRG_INCLUDE = $(call fixpath,$(INCLUDE)) $(SYSINCLUDE)

# target flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
# note: these macros may be overridden in project configuration makefile, for example:
# TRG_DEFINES = $(if $(DEBUG),_DEBUG) TARGET_$(TARGET:D=) $(foreach \
#   cpu,$($(if $(filter DRV KLIB KDLL,$t),K,$(TMD))CPU),$(if \
#   $(filter sparc% mips% ppc%,$(cpu)),B_ENDIAN,L_ENDIAN) $(if \
#   $(filter arm% sparc% mips% ppc%,$(cpu)),ADDRESS_NEEDALIGN)) $(DEFINES)
TRG_DEFINES = $(DEFINES)
TRG_COPTS   = $(COPTS)
TRG_CXXOPTS = $(CXXOPTS)
TRG_LOPTS   = $(LOPTS)

# choose INCLUDE/DEFINES/COPTS/CXXOPTS/LOPTS for non-regilar target variant
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: $t_VARIANT_... macros should be defined in C/C++ compiler definitions makefile
VARIANT_INCLUDE = $(if $(filter-out R,$v),$(call $t_VARIANT_INCLUDE,$v))
VARIANT_DEFINES = $(if $(filter-out R,$v),$(call $t_VARIANT_DEFINES,$v))
VARIANT_COPTS   = $(if $(filter-out R,$v),$(call $t_VARIANT_COPTS,$v))
VARIANT_CXXOPTS = $(if $(filter-out R,$v),$(call $t_VARIANT_CXXOPTS,$v))
VARIANT_LOPTS   = $(if $(filter-out R,$v),$(call $t_VARIANT_LOPTS,$v))

# make list of sources for the target, used by TRG_SRC
GET_SOURCES = $(SRC) $(WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC = $(call fixpath,$(GET_SOURCES))

# make absolute paths of source dependencies
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS))

# helper macro for target makefiles to pass string define value to C-compiler
# result of this macro will be processed by DEFINE_ESCAPE_STRING
# example: DEFINES := MY_MESSAGE=$(call STRING_DEFINE,"my message")
STRING_DEFINE = $(unspaces)

# process result of STRING_DEFINE to make value of define for passing it to C-compiler
# escape characters in string value of define for passing it via shell
# $1 - define_name
# $d - $1="1$(space)2"
# returns: define_name="\"1 2\""
DEFINE_ESCAPE_STRING = $1=$(call SHELL_ESCAPE,$(call tospaces,$(patsubst $1=%,%,$d)))

# process result of STRING_DEFINE to make values of defines for passing them to C-compiler
# escape characters in string values of defines for passing them via shell
# $1 - list of defines
# example: A=1 B="b" C="1$(space)2"
# returns: A=1 B="\"b\"" C="\"1 2\""
# note: called by macro that expands to C-complier call
DEFINES_ESCAPE_STRING = $(if $(findstring ",$1),$(foreach d,$1,$(if $(findstring \
  =",$d),$(call DEFINE_ESCAPE_STRING,$(firstword $(subst =", ,$d))),$d)),$1)

# list of target types that may be built from C/C++/Assembler sources
# note: appended in:
#  $(CLEAN_BUILD_DIR)/impl/_c.mk
#  $(CLEAN_BUILD_DIR)/impl/_kc.mk
C_TARGETS:=

# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(TRG_SRC)
# $3 - $(TRG_SDEPS)
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,...
# $v - non-empty variant: R,P,S,...
C_RULESv = $($t_TEMPLATE)

# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
# $t - EXE,DLL,...
C_RULESt = $(foreach v,$(call GET_VARIANTS,$t),$(call C_RULESv,$(call FORM_TRG,$t,$v),$1,$2,$(call FORM_OBJ_DIR,$t,$v))$(newline))

# expand target rules template $t_TEMPLATE, for example - see EXE_TEMPLATE
# $1 - $(TRG_SRC)
# $2 - $(TRG_SDEPS)
C_RULES = $(foreach t,$(C_TARGETS),$(if $($t),$(C_RULESt)))

# base template for C/C++ targets
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $2 - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: STD_TARGET_VARS also changes CB_NEEDED_DIRS
define C_BASE_TEMPLATE
CB_NEEDED_DIRS+=$4
$(STD_TARGET_VARS)
$1:$(call OBJ_RULES,CC,$(filter $(CC_MASK),$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter $(CXX_MASK),$2),$3,$4)
$1:COMPILER := $(TRG_COMPILER)
$1:INCLUDE  := $(TRG_INCLUDE) $(VARIANT_INCLUDE)
$1:DEFINES  := $(TRG_DEFINES) $(VARIANT_DEFINES)
$1:COPTS    := $(TRG_COPTS) $(VARIANT_COPTS)
$1:CXXOPTS  := $(TRG_CXXOPTS) $(VARIANT_CXXOPTS)
$1:LOPTS    := $(TRG_LOPTS) $(VARIANT_LOPTS)
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
SYSINCLUDE:=
SYSLIBS:=
SYSLIBPATH:=
LIBS:=
DLLS:=
COPTS:=
CXXOPTS:=
LOPTS:=
endef

# this code is normally evaluated at end of target makefile
C_RULES_EVAL = $(eval $(call C_RULES,$(TRG_SRC),$(TRG_SDEPS)))

# do not support assembler by default
# note: ASSEMBLER_SUPPORT may be overridden in protect configuration makefile
# note: if ASSEMBLER_SUPPORT is defined, then must also be defined different assemblers, called from $(OBJ_RULES_BODY):
#  EXE_R_ASM, LIB_R_ASM, LIB_D_ASM, etc. - for all supported target variants
ASSEMBLER_SUPPORT:=

# ensure ASSEMBLER_SUPPORT variable is non-recursive (simple)
override ASSEMBLER_SUPPORT := $(ASSEMBLER_SUPPORT)

ifdef ASSEMBLER_SUPPORT

# Assembler sources mask
ASM_MASK := %.asm

# target assembler flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_ASMOPTS = $(ASMOPTS)

# choose ASMOPTS for non-regilar target variant
# $t - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v - non-empty variant: R,P,D,S... (one of variants supported by selected toolchain)
# note: $t_VARIANT_... macros should be defined in C/C++ compiler definitions makefile
VARIANT_ASMOPTS = $(if $(filter-out R,$v),$(call $t_VARIANT_ASMOPTS,$v))

# template for adding assembler support
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $v - non-empty variant: R,P,S,...
define ASM_TEMPLATE
$1:$(call OBJ_RULES,ASM,$(filter $(ASM_MASK),$2),$3,$4)
$1:ASMOPTS := $(TRG_ASMOPTS) $(VARIANT_ASMOPTS)
endef

# patch C_BASE_TEMPLATE
$(call define_append,C_BASE_TEMPLATE,$(newline)$(value ASM_TEMPLATE))

# tool color
ASM_COLOR := [37m

# reset ASMOPTS at beginning of target makefile
$(call define_append,C_PREPARE_BASE_VARS,$(newline)ASMOPTS:=)

endif # ASSEMBLER_SUPPORT

# optimization
$(call try_make_simple,C_PREPARE_BASE_VARS,PRODUCT_VER)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,NO_PCH OBJ_SUFFIX CC_MASK CXX_MASK DEP_SUFFIX ADD_OBJ_SDEPS=x OBJ_RULES_BODY=t;v OBJ_RULES1=t;v OBJ_RULES=t;v \
  TRG_COMPILER=t;v TRG_INCLUDE=t;v;INCLUDE;SYSINCLUDE TRG_DEFINES=t;v;DEFINES TRG_COPTS=t;v;COPTS TRG_CXXOPTS=t;v;CXXOPTS \
  TRG_LOPTS=t;v;LOPTS VARIANT_INCLUDE=t;v VARIANT_DEFINES=t;v VARIANT_COPTS=t;v VARIANT_CXXOPTS=t;v VARIANT_LOPTS=t;v \
  GET_SOURCES=SRC;WITH_PCH TRG_SRC TRG_SDEPS=SDEPS STRING_DEFINE DEFINE_ESCAPE_STRING DEFINES_ESCAPE_STRING \
  C_TARGETS C_RULESv=t;v C_RULESt=t C_RULES C_BASE_TEMPLATE=t;v;$$t C_PREPARE_BASE_VARS C_RULES_EVAL \
  ASM_MASK TRG_ASMOPTS=t;v;ASMOPTS VARIANT_ASMOPTS=t;v ASM_TEMPLATE ASM_COLOR)

# protect variables from modifications in target makefiles
# note: do not trace calls to ASSEMBLER_SUPPORT variable because it is used in ifdefs
$(call SET_GLOBAL,ASSEMBLER_SUPPORT,0)








## 
## # tools colors: C, C++ compilers, library archiver, shared library and executable linkers
## KCC_COLOR  := [31m
## KCXX_COLOR := [36m
## KAR_COLOR  := [32m
## KLD_COLOR  := [33m
## KXLD_COLOR := [37m
## 
## KCC_COLOR KCXX_COLOR KAR_COLOR KLD_COLOR KXLD_COLOR \
