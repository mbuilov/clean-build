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

# object file suffix
# note: may overridden by selected C/C++ compiler
OBJ_SUFFIX := .o

# C/C++/Assembler sources masks
CC_MASK  := %.c
CXX_MASK := %.cpp
ASM_MASK := %.asm

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
# $6 - compiler: $t_$v_$1
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,S,...
# returns: list of object files
# note: postpone expansion of ORDER_DEPS to optimize parsing
define OBJ_RULES_BODY
$5
$(subst $(space),$(newline),$(join $(addsuffix :,$5),$2))$(if \
  $3,$(foreach x,$2,$(call ADD_OBJ_SDEPS,$4,$(call EXTRACT_SDEPS,$x,$3))))
$5:| $4 $$(ORDER_DEPS)
	$$(call $6,$$@,$$<)
endef

# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $5 - $(addprefix $4/,$(basename $(notdir $2)))
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,S,...
# returns: list of object files
# note: cleanup auto-generated dependencies
ifdef TOCLEAN
OBJ_RULES1 = $(call TOCLEAN,$(addsuffix .d,$5) $(addsuffix $(OBJ_SUFFIX),$5))
else
OBJ_RULES1 = $(call OBJ_RULES_BODY,$1,$2,$3,$4,$(addsuffix $(OBJ_SUFFIX),$5),$t_$v_$1)
ifndef NO_DEPS
OBJ_RULES1 += $(newline)-include $(addsuffix .d,$5)
endif
endif

# rule that defines how to build objects from sources
# $1 - sources type: CXX,CC,ASM,...
# $2 - sources to compile
# $3 - sdeps (result of FIX_SDEPS)
# $4 - objdir
# $t - target type: EXE,LIB,...
# $v - non-empty variant: R,P,S,...
# returns: list of object files
OBJ_RULES = $(if $2,$(call OBJ_RULES1,$1,$2,$3,$4,$(addprefix $4/,$(basename $(notdir $2)))))

# which compiler type to use for the target? CXX or CC?
# note: CXX compiler may compile C sources, but also links standard C++ library (libstdc++.so)
# $1     - target file: $(call FORM_TRG,$t,$v)
# $2     - sources: $(TRG_SRC)
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_COMPILER = $(if $(filter $(CXX_MASK),$2),CXX,CC)

# optimization
$(call subst_simple,TRG_COMPILER,CXX_MASK)

# make absolute paths to include directories - we need absolute paths to headers in generated .d dependency file
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
TRG_DEFINES  = $(DEFINES)
TRG_CFLAGS   = $(CFLAGS)
TRG_CXXFLAGS = $(CXXFLAGS)
TRG_LDFLAGS  = $(LDFLAGS)

# make list of sources for the target, used by TRG_SRC
GET_SOURCES = $(SRC) $(WITH_PCH)

# make absolute paths to sources - we need absolute path to source in generated .d dependency file
TRG_SRC = $(call fixpath,$(GET_SOURCES))

# make absolute paths of source dependencies
TRG_SDEPS = $(call FIX_SDEPS,$(SDEPS))

# helper macro for target makefiles to pass string define value to C-compiler
# result of this macro will be processed by SUBST_DEFINES
# example: DEFINES := MY_MESSAGE=$(call STRING_DEFINE,"my message")
STRING_DEFINE = $(subst $(tab),$$(tab),$(subst $(space),$$(space),$(subst $$,$$$$,$1)))

# process result of STRING_DEFINE to make values of defines passed to C-compiler
# called by macro that expands to C-complier call
SUBST_DEFINES = $(eval SUBST_DEFINES_:=$(subst $(comment),$$(comment),$1))$(SUBST_DEFINES_)

# list of target types that may be built from C/C++/Assembler sources
# note: should be appended in makefile implementing target templates
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
# $v - non-empty variant: R,P,S,...
define C_BASE_TEMPLATE
NEEDED_DIRS+=$4
$(STD_TARGET_VARS)
$1:$(call OBJ_RULES,CC,$(filter $(CC_MASK),$2),$3,$4)
$1:$(call OBJ_RULES,CXX,$(filter $(CXX_MASK),$2),$3,$4)
$1:COMPILER := $(TRG_COMPILER)
$1:INCLUDE  := $(TRG_INCLUDE)
$1:DEFINES  := $(TRG_DEFINES)
$1:CFLAGS   := $(TRG_CFLAGS)
$1:CXXFLAGS := $(TRG_CXXFLAGS)
$1:LDFLAGS  := $(TRG_LDFLAGS)
endef

# optimization
$(call subst_simple,C_BASE_TEMPLATE,CC_MASK CXX_MASK)

# code to be called at beginning of target makefile
# $(MODVER) - module version (for dll, exe or driver) in form major.minor.patch (for example 1.2.3)
define C_PREPARE_BASE_VARS
MODVER:=$(PRODUCT_VER)
SRC:=
WITH_PCH:=
SDEPS:=
INCLUDE:=
DEFINES:=
CFLAGS:=
CXXFLAGS:=
LDFLAGS:=
SYSINCLUDE:=
SYSLIBS:=
SYSLIBPATH:=
LIBS:=
DLLS:=
DEFINE_TARGETS_EVAL_NAME:=DEFINE_C_TARGETS_EVAL
MAKE_CONTINUE_EVAL_NAME:=CLEAN_BUILD_C_EVAL
endef

# template C_BASE_TEMPLATE_IMPL may be subsequently patched
$(eval define C_BASE_TEMPLATE_IMPL$(newline)$(value C_BASE_TEMPLATE)$(newline)endef)

# template C_PREPARE_VARS_IMPL may be subsequently patched
$(eval define C_PREPARE_VARS_IMPL$(newline)$(value C_PREPARE_BASE_VARS)$(newline)endef)

# reset build targets, target-specific variables and variables modifiable in target makefiles
CLEAN_BUILD_C_EVAL = $(DEF_HEAD_CODE_EVAL)$(eval $(C_PREPARE_VARS_IMPL))

# this code is normally evaluated at end of target makefile
DEFINE_C_TARGETS_EVAL = $(eval $(call C_RULES,$(TRG_SRC),$(TRG_SDEPS)))$(DEF_TAIL_CODE_EVAL)

# do not support assembler by default
# note: ASSEMBLER_SUPPORT may be overridden in protect configuration makefile
# note: if ASSEMBLER_SUPPORT is defined, then must also be defined different assemblers, called from $(OBJ_RULES_BODY):
#  EXE_R_ASM, LIB_R_ASM, LIB_D_ASM, etc. - for all supported target variants
ASSEMBLER_SUPPORT:=

# ensure ASSEMBLER_SUPPORT variable is non-recursive (simple)
override ASSEMBLER_SUPPORT := $(ASSEMBLER_SUPPORT)

ifdef ASSEMBLER_SUPPORT

# target assembler flags
# $t     - EXE,LIB,DLL,DRV,KLIB,KDLL,...
# $v     - non-empty variant: R,P,S,...
# $(TMD) - T in tool mode, empty otherwise
TRG_ASMFLAGS = $(ASMFLAGS)

# template for adding assembler support
# $1 - target file: $(call FORM_TRG,$t,$v)
# $2 - sources:     $(TRG_SRC)
# $3 - sdeps:       $(TRG_SDEPS)
# $4 - objdir:      $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,DLL,LIB...
# $v - non-empty variant: R,P,S,...
define ASM_TEMPLATE
$1:$(call OBJ_RULES,ASM,$(filter $(ASM_MASK),$2),$3,$4)
$1:ASMFLAGS := $(TRG_ASMFLAGS)
endef

# optimization
$(call subst_simple,ASM_TEMPLATE,ASM_MASK)

# patch C_BASE_TEMPLATE_IMPL
$(call define_append,C_BASE_TEMPLATE_IMPL,$(newline)$(value ASM_TEMPLATE))

# tool color
ASM_COLOR := [37m

# reset ASMFLAGS at beginning of target makefile
$(call define_append,C_PREPARE_VARS_IMPL,$(newline)ASMFLAGS:=)

endif # ASSEMBLER_SUPPORT

# optimization
$(call try_make_simple,C_PREPARE_VARS_IMPL,PRODUCT_VER)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,OBJ_SUFFIX CC_MASK CXX_MASK ASM_MASK ADD_OBJ_SDEPS=x OBJ_RULES_BODY=t;v OBJ_RULES1=t;v OBJ_RULES=t;v \
  TRG_COMPILER=t;v TRG_INCLUDE=t;v;INCLUDE;SYSINCLUDE TRG_DEFINES=t;v;DEFINES TRG_CFLAGS=t;v;CFLAGS \
  TRG_CXXFLAGS=t;v;CXXFLAGS TRG_LDFLAGS=t;v;LDFLAGS GET_SOURCES=SRC;WITH_PCH \
  TRG_SRC TRG_SDEPS=SDEPS STRING_DEFINE SUBST_DEFINES C_TARGETS C_RULESv=t;v C_RULESt=t C_RULES \
  C_BASE_TEMPLATE=t;v C_PREPARE_BASE_VARS C_BASE_TEMPLATE_IMPL=t;v;$$t \
  TRG_ASMFLAGS=t;v;ASMFLAGS ASM_TEMPLATE ASM_COLOR)

# protect variables from modifications in target makefiles
# note: do not trace calls to ASSEMBLER_SUPPORT variable because it is used in ifdefs
# note: do not trace calls to C_PREPARE_VARS_IMPL variable because its $(value) is subsequently taken
# note: do not trace calls to CLEAN_BUILD_C_EVAL variable because its $(value) is subsequently taken
# note: do not trace calls to DEFINE_C_TARGETS_EVAL variable because its $(value) is subsequently taken
$(call SET_GLOBAL,ASSEMBLER_SUPPORT C_PREPARE_VARS_IMPL CLEAN_BUILD_C_EVAL DEFINE_C_TARGETS_EVAL,0)


## 
## # tools colors: C, C++ compilers, library archiver, shared library and executable linkers
## KCC_COLOR  := [31m
## KCXX_COLOR := [36m
## KAR_COLOR  := [32m
## KLD_COLOR  := [33m
## KXLD_COLOR := [37m
## 
## KCC_COLOR KCXX_COLOR KAR_COLOR KLD_COLOR KXLD_COLOR \
