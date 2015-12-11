ifndef MAKE_DEFS_INCLUDED
# this file included by main $(MTOP)/make_c.mk or $(MTOP)/make_java.mk
# also this file may be included at beginning of target Makefile
MAKE_DEFS_INCLUDED := 1

# legend:
# $< - name of the first prerequisite
# $^ - names of all prerequisites
# $@ - file name of the target
# $? - prerequisites newer than the target

# standard defines & checks
# NOTE:
#  $(OS) (may be $(BUILD_OS)), $(SUPPORTED_OSES),
#  $(CPU) or $(UCPU),$(KCPU),$(TCPU), $(SUPPORTED_CPUS),
#  $(TARGET) and $(SUPPORTED_TARGETS) are must be defined

# disable builtin rules and variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# don't generate dependencies when cleaning up
ifneq ($(filter clean,$(MAKECMDGOALS)),)
NO_DEPS := 1
endif

# check values of TOP (and, if defined, XTOP) variables, include functions library
include $(MTOP)/make_top.mk
include $(MTOP)/make_functions.mk

# $(DEBUG) is non-empty for DEBUG targets like PROJECTD
DEBUG := $(filter %D,$(TARGET))

# project's $(TOP)/make/make_features.mk, if exists, should define something like:
# SUPPORTED_OSES    := WINXX SOLARIS LINUX
# SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc
# SUPPORTED_TARGETS := PROJECT PROJECTD
PROJECT_FEATURES ?= $(TOP)/make/make_features.mk
-include $(PROJECT_FEATURES)

ifndef SUPPORTED_OSES
$(error SUPPORTED_OSES not defined, it may be defined in $(PROJECT_FEATURES:$(TOP)/%,$$(TOP)/%))
endif
ifndef SUPPORTED_CPUS
$(error SUPPORTED_CPUS not defined, it may be defined in $(PROJECT_FEATURES:$(TOP)/%,$$(TOP)/%))
endif
ifndef SUPPORTED_TARGETS
$(error SUPPORTED_TARGETS not defined, it may be defined in $(PROJECT_FEATURES:$(TOP)/%,$$(TOP)/%))
endif

# OS - operating system we are building for
ifndef OS
$(error OS undefined, example: $(SUPPORTED_OSES))
else ifeq ($(filter $(OS),$(SUPPORTED_OSES)),)
$(error unknown OS=$(OS), please pick one of: $(SUPPORTED_OSES))
endif

# BUILD_OS - operating system we are building on
ifndef BUILD_OS
BUILD_OS := $(OS)
else ifeq ($(filter $(BUILD_OS),$(SUPPORTED_OSES)),)
$(error unknown BUILD_OS=$(BUILD_OS), please pick one of: $(SUPPORTED_OSES))
endif

# NOTE: don't use CPU variable in target makefiles, use UCPU or KCPU instead

# CPU variable contains default value for UCPU, KCPU, TCPU
ifdef CPU
ifeq ($(filter $(CPU),$(SUPPORTED_CPUS)),)
$(error unknown CPU=$(CPU), please pick one of: $(SUPPORTED_CPUS))
endif
endif

# CPU for user-level
ifdef UCPU
ifeq ($(filter $(UCPU),$(SUPPORTED_CPUS)),)
$(error unknown UCPU=$(UCPU), please pick one of: $(SUPPORTED_CPUS))
endif
else
ifndef CPU
$(error UCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
UCPU := $(CPU)
endif
endif

# CPU for kernel-level
ifdef KCPU
ifeq ($(filter $(KCPU),$(SUPPORTED_CPUS)),)
$(error unknown KCPU=$(KCPU), please pick one of: $(SUPPORTED_CPUS))
endif
else
ifndef CPU
$(error KCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
KCPU := $(CPU)
endif
endif

# CPU for build-tools
ifdef TCPU
ifeq ($(filter $(TCPU),$(SUPPORTED_CPUS)),)
$(error unknown TCPU=$(TCPU), please pick one of: $(SUPPORTED_CPUS))
endif
else
ifndef CPU
$(error TCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
TCPU := $(CPU)
endif
endif

# what to build
ifndef TARGET
$(error TARGET undefined, example: $(SUPPORTED_TARGETS))
endif
ifeq ($(filter $(TARGET),$(SUPPORTED_TARGETS)),)
$(error unknown TARGET=$(TARGET), please pick one of: $(SUPPORTED_TARGETS))
endif

# run via $(MAKE) V=1 for verbose output
ifeq ("$(origin V)","command line")
VERBOSE := $V
endif

# run via $(MAKE) M=1 to print makefile name the target comes from
ifeq ("$(origin M)","command line")
INFOMF := $M
endif

# run via $(MAKE) D=1 to debug makefiles
ifeq ("$(origin D)","command line")
MDEBUG := $D
endif

# run via $(MAKE) C=1 to check makefiles
ifeq ("$(origin C)","command line")
MCHECK := $C
endif

# 0 -> $(empty)
VERBOSE := $(VERBOSE:0=)
INFOMF := $(INFOMF:0=)
MDEBUG := $(MDEBUG:0=)
MCHECK := $(MCHECK:0=)

# check that internal variables were not changed in target makefiles
ifdef MCHECK

# convert value of $1 to string
CLEAN_BUILD_GET_PROTECTED_VALUE = $1@$(subst $$,$$$$,$(subst $(newline),$$(newline),$(subst \
  $(tab),$$(tab),$(subst $(space),$$(space),$(value $1)))))

# store values of clean-build protected variables which must not be changed in target makefiles
# check and set CLEAN_BUILD_NEED_TAIL_CODE - $(DEF_TAIL_CODE) must be evaluated after $(DEF_HEAD_CODE)
define CLEAN_BUILD_CHECK_AT_HEAD
ifndef CLEAN_BUILD_SAVE_PROTECTED_VALUES
CLEAN_BUILD_SAVE_PROTECTED_VALUES := $$(foreach x,$$(CLEAN_BUILD_PROTECTED_VARS),$$(call CLEAN_BUILD_GET_PROTECTED_VALUE,$$x))
endif
ifdef CLEAN_BUILD_NEED_TAIL_CODE
$$(error $$$$(DEFINE_TARGETS) was not evaluated at end of $$(CLEAN_BUILD_NEED_TAIL_CODE)!)
endif
CLEAN_BUILD_NEED_TAIL_CODE := $(CURRENT_MAKEFILE)
endef

# replace $1 protected vars values
# NOTE: if CLEAN_BUILD_SAVE_PROTECTED_VALUES is not defined yet - then $(DEF_HEAD_CODE) was never executed yet:
# - when it will be executed, it will save initial values of protected vars, so nothing to do here
# else - replace protected vars old values with current onces
define CLEAN_BUILD_REPLACE_PROTECTED_VARS1
ifdef CLEAN_BUILD_SAVE_PROTECTED_VALUES
CLEAN_BUILD_SAVE_PROTECTED_VALUES := $$(filter-out $$(addsuffix @%,$1),$$(CLEAN_BUILD_SAVE_PROTECTED_VALUES)) $$(foreach \
  x,$1,$$(call CLEAN_BUILD_GET_PROTECTED_VALUE,$$x))
endif
endef
CLEAN_BUILD_REPLACE_PROTECTED_VARS = $(eval $(CLEAN_BUILD_REPLACE_PROTECTED_VARS1))

# save $1 vars values - if not done this already
# NOTE: if CLEAN_BUILD_SAVE_PROTECTED_VALUES is not defined yet - then $(DEF_HEAD_CODE) was never executed yet:
# - when it will be executed, it will save values from given vars list $1, so it's not needed to do this here,
# else - re-save value of $(CLEAN_BUILD_PROTECTED_VARS) after appending vars list $1 to it
define CLEAN_BUILD_APPEND_PROTECTED_VARS1
CLEAN_BUILD_PROTECTED_VARS += $1
ifdef CLEAN_BUILD_SAVE_PROTECTED_VALUES
CLEAN_BUILD_SAVE_PROTECTED_VALUES := $$(filter-out CLEAN_BUILD_PROTECTED_VARS@%,$$(CLEAN_BUILD_SAVE_PROTECTED_VALUES)) $$(foreach \
  x,CLEAN_BUILD_PROTECTED_VARS $1,$$(call CLEAN_BUILD_GET_PROTECTED_VALUE,$$x))
endif
endef
CLEAN_BUILD_APPEND_PROTECTED_VARS = $(eval $(CLEAN_BUILD_APPEND_PROTECTED_VARS1))

# macro to check if clean-build protected $x variable value was changed in target makefile
define CLEAN_BUILD_CHECK_PROTECTED_VAR
ifneq ($$(filter $x@%,$$(CLEAN_BUILD_SAVE_PROTECTED_VALUES)),$$(call CLEAN_BUILD_GET_PROTECTED_VALUE,$x))
ifeq ($(filter $x,$(CLEAN_BUILD_OVERRIDEN_VARS)),)
$$(error $$$$($x) value was changed:$$(newline)old value:$$(newline)$$(filter \
  $x@%,$$(CLEAN_BUILD_SAVE_PROTECTED_VALUES))$$(newline)new value:$$(newline)$$(call CLEAN_BUILD_GET_PROTECTED_VALUE,$x)$$(newline))
endif
endif
$(empty)
endef

# check that values of protected vars were not changed
# note: error suppressed if variable name is specified in $(CLEAN_BUILD_OVERRIDEN_VARS) list
# note: $(CLEAN_BUILD_OVERRIDEN_VARS) list is cleared after checks
# note: $(CLEAN_BUILD_NEED_TAIL_CODE) value is cleared after checks to mark that $(DEF_TAIL_CODE) was evaluated
# note: normally, $(CLEAN_BUILD_NEED_TAIL_CODE) is checked at head of next included by $(MTOP)/make_parallel.mk target makefile,
# but for the last included target makefile - need to check $(CLEAN_BUILD_NEED_TAIL_CODE) here
# - $(MTOP)/make_parallel.mk call $(DEF_TAIL_CODE) with $1=@
define CLEAN_BUILD_CHECK_AT_TAIL
$(if $(filter @,$1),ifdef CLEAN_BUILD_NEED_TAIL_CODE$(newline)$$(error \
  $$$$(DEFINE_TARGETS) was not evaluated at end of $$(CLEAN_BUILD_NEED_TAIL_CODE)!)$(newline)endif)
ifneq (x$(space)x,x x)
$$(error $$$$(space) value was changed)
endif
ifneq (x$(tab)x,x	x)
$$(error $$$$(tab) value was changed)
endif
$(foreach x,$(CLEAN_BUILD_PROTECTED_VARS),$(CLEAN_BUILD_CHECK_PROTECTED_VAR))
CLEAN_BUILD_OVERRIDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=
endef

# check that $(CURRENT_MAKEFILE) is not already processed
define CHECK_MAKEFILE_NOT_PROCESSED
ifneq ($(filter $(CURRENT_MAKEFILE)-,$(PROCESSED_MAKEFILES)),)
$$(error makefile $(CURRENT_MAKEFILE) is already processed!)
endif
endef

endif # MCHECK

# supress output of executed build tool, print some pretty message instead, like "CC  source.c"
# target-specific: MF, MCONT
ifdef VERBOSE
ifdef INFOMF
SUP = $(info $(MF)$(MCONT):)
else
SUP:=
endif
else ifdef INFOMF
SUP = @$(info $(MF)$(MCONT):$(COLORIZE))
else
SUP = @$(info $(COLORIZE))
endif

# print in color name of called tool $1
TOOL_IN_COLOR ?= $(subst |,,$(subst \
  |CC|,[01;31mCC[0m,$(subst \
  |AR|,[01;32mAR[0m,$(subst \
  |LD|,[01;33mLD[0m,$(subst \
  |CP|,[00;36mCP[0m,$(subst \
  |CXX|,[01;36mCXX[0m,$(subst \
  |JAR|,[01;33mJAR[0m,$(subst \
  |KCC|,[00;31mKCC[0m,$(subst \
  |KLD|,[00;33mKLD[0m,$(subst \
  |ASM|,[00;37mASM[0m,$(subst \
  |TCC|,[00;32mTCC[0m,$(subst \
  |TLD|,[00;32mTLD[0m,$(subst \
  |GEN|,[01;32mGEN[0m,$(subst \
  |TCXX|,[00;32mTCXX[0m,$(subst \
  |MGEN|,[01;32mMGEN[0m,$(subst \
  |JAVAC|,[01;36mJAVAC[0m,$(subst \
  |SCALAC|,[01;36mSCALAC[0m,$(subst \
  |MKDIR|,[00;36mMKDIR[0m,$(subst \
  |TOUCH|,[00;36mTOUCH[0m,|$1|)))))))))))))))))))

# print in color short name of called tool $1 with argument $2
COLORIZE = $(TOOL_IN_COLOR)$(padto)$2

# define utilities of the OS we are building on
include $(MTOP)/$(BUILD_OS)/make_tools.mk

# helper macro: convert multiline sed script $1 to multiple sed expressions - one expression for each script line
SED_MULTI_EXPR = $(subst $$(space), ,$(foreach s,$(subst $(newline), ,$(subst $(space),$$(space),$1)),-e $(call SED_EXPR,$s)))

# for UNIX: don't change paths when convertig from make internal file path to path accepted by $(BUILD_OS)
ospath ?= $1

# for UNIX: absolute paths are started with /
isrelpath ?= $(filter-out /%,$1)

# get absolute path to current makefile
CURRENT_MAKEFILE := $(abspath $(subst \,/,$(firstword $(MAKEFILE_LIST))))

# check that we are building right sources - $(CURRENT_MAKEFILE) must be under the $(TOP)
ifeq ($(filter $(TOP)/%,$(CURRENT_MAKEFILE)),)
$(error TOP=$(TOP) is not the root directory of current makefile $(CURRENT_MAKEFILE))
endif

# make current makefile path relative to $(TOP)
CURRENT_MAKEFILE := $(CURRENT_MAKEFILE:$(TOP)/%=%)

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), etc...
XTOP ?= $(TOP)

# output directories:
# bin - for executables, dlls, res
# lib - for libraries, shared objects
# obj - for object files
# gen - for generated files (headers, sources, resources, etc)
# NOTE: to allow parallel builds for different combinations of
#  $(OS)/$(KCPU)/$(UCPU)/$(TARGET) create unique directories for each combination
DEF_BIN_DIR := $(XTOP)/bin/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_OBJ_DIR := $(XTOP)/obj/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_LIB_DIR := $(XTOP)/lib/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_GEN_DIR := $(XTOP)/gen/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)

# restore default dirs after tool mode
define SET_DEFAULT_DIRS1
BIN_DIR := $(DEF_BIN_DIR)
OBJ_DIR := $(DEF_OBJ_DIR)
LIB_DIR := $(DEF_LIB_DIR)
GEN_DIR := $(DEF_GEN_DIR)
$(call CLEAN_BUILD_REPLACE_PROTECTED_VARS1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endef
SET_DEFAULT_DIRS := $(SET_DEFAULT_DIRS1)

# $(PROJECT_FEATURES) makefile may forward-reference some of default dirs,
# ensure they are defined when we will use defs from $(PROJECT_FEATURES)
$(eval $(SET_DEFAULT_DIRS))

# needed directories - we will create them in $(MTOP)/make_all.mk
# note: NEEDED_DIRS is never cleared, only appended
NEEDED_DIRS:=

# NOTE: to allow parallel builds for different combinations of
#  $(OS)/$(KCPU)/$(UCPU)/$(TARGET) tool dir must be unique for each such combination
#  (this is true for TOOL_BASE = $(DEF_GEN_DIR))
ifndef TOOL_BASE
TOOL_BASE := $(DEF_GEN_DIR)
endif

# where tools are built, $1 - TOOL_BASE, $2 - TCPU
MK_TOOLS_DIR = $1/TOOL-$2-$(TARGET)/bin

# call with $1 - TOOL_BASE, $2 - TCPU, $3 - tool name(s) to get paths to the tools executables
GET_TOOLS = $(addsuffix $(TOOL_SUFFIX),$(addprefix $(MK_TOOLS_DIR)/,$3))

# get path to a tool $1 for current $(TOOL_BASE) and $(TCPU)
GET_TOOL = $(call GET_TOOLS,$(TOOL_BASE),$(TCPU),$1)

# override dirs in tool mode (when TOOL_MODE has non-empty value)
TOOLS_DIR := $(TOOL_BASE)/TOOL-$(TCPU)-$(TARGET)
define TOOL_OVERRIDE_DIRS1
BIN_DIR := $(TOOLS_DIR)/bin
OBJ_DIR := $(TOOLS_DIR)/obj
LIB_DIR := $(TOOLS_DIR)/lib
GEN_DIR := $(TOOLS_DIR)/gen
$(call CLEAN_BUILD_REPLACE_PROTECTED_VARS1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endef
TOOL_OVERRIDE_DIRS := $(TOOL_OVERRIDE_DIRS1)

# order-only $(TOP)-related makefiles dependencies to add to all leaf prerequisites for the targets
# NOTE: $(FIX_ORDER_DEPS) may change $(ORDER_DEPS) list by appending $(MDEPS)
ORDER_DEPS:=

# code for adding $(MDEPS) - list of makefiles that need to be maked before target makefile to $(ORDER_DEPS),
# overwritten in $(MTOP)/make_parallel.mk
FIX_ORDER_DEPS:=

# standard target-specific variables
# $1       - target file(s) to build (absolute path)
# $2       - directory of target file(s) (absolute path)
# $(MF)    - name of makefile which specifies how to build the target (path relative to $(TOP))
# $(MCONT) - number of section in makefile after a call of $(MAKE_CONTINUE)
# $(TMD)   - T if target is built in TOOL_MODE
# NOTE: $(MAKE_CONT) list is empty or 1 1 1 .. 1 2 (inside MAKE_CONTINUE) or 1 1 1 1... (before MAKE_CONTINUE)
# NOTE: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) changes $(ORDER_DEPS) value
# NOTE: MCONT will be either empty or 2,3,4... - MCONT cannot be 1 some rules may be defined before $(MAKE_CONTINUE)
define STD_TARGET_VARS1
$(FIX_ORDER_DEPS)
$1: MF    := $(CURRENT_MAKEFILE)
$1: MCONT := $(if $(MAKE_CONT),@$(words 1 $(MAKE_CONT)x))
$1: TMD   := $(CB_TOOL_MODE)
$1: | $2 $$(ORDER_DEPS)
$(CURRENT_MAKEFILE)-: $1
NEEDED_DIRS += $2
CLEAN += $1
endef

# standard target-specific variables
# $1 - generated file(s) (absolute paths)
STD_TARGET_VARS = $(call STD_TARGET_VARS1,$1,$(patsubst %/,%,$(sort $(dir $1))))

# compute values of next variables right after +=, not at call time:
# CLEAN          - files/directories list to delete on $(MAKE) clean
# CLEAN_COMMANDS - code to $(eval) to get clean commands to execute on $(MAKE) clean - see $(MTOP)/make_all.mk
# note: CLEAN is never cleared, only appended
CLEAN:=
CLEAN_COMMANDS:=

# get VPREFIX - relative path from $(CURDIR) to directory of makefile $1 (which is related to $(TOP))
GET_VPREFIX = $(call relpath,$(CURDIR),$(dir $(TOP)/$1))

# $(VPREFIX) - relative path from $(CURDIR) to directory of currently processing makefile, either empty or dir/
# note: VPREFIX value is changed by $(MTOP)/make_parallel.mk
VPREFIX := $(call GET_VPREFIX,$(CURRENT_MAKEFILE))

# add $(VPREFIX) (path to directory of currently executing makefile relative to $(CURDIR)) value to non-absolute paths
ADDVPREFIX = $(foreach x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x)

# add $(VPREFIX) (path to directory of currently executing makefile relative to $(CURDIR)) value to non-absolute paths
# then make absolute paths - we need absolute paths to sources to apply generated dependencies in .d files
FIXPATH = $(abspath $(ADDVPREFIX))

# list of all processed makefiles names
# note: PROCESSED_MAKEFILES is never cleared, only appended
# note: default target 'all' depends only on $(PROCESSED_MAKEFILES) list
PROCESSED_MAKEFILES:=

ifdef MDEBUG
# convert list "make1 make2 make3" -> "..."
# $1 - $(CB_INCLUDE_LEVEL)
MAKEFILES_LEVEL = $(subst . ,.,$(foreach x,$1,.))
# show which makefile is expanded now
# note: show debug info only if $1 does not contains @ (used by $(MTOP)/make_parallel.mk)
define DEF_TAIL_CODE_DEBUG
ifeq ($(filter @,$1),)
$$(info $(call MAKEFILES_LEVEL,$(CB_INCLUDE_LEVEL))$(CURRENT_MAKEFILE)$(if $(ORDER_DEPS), | $(ORDER_DEPS:-=)))
endif
endef
endif # MDEBUG

# code to $(eval) at beginning of each makefile
# 1) add $(CURRENT_MAKEFILE) to build
# 2) change bin,lib,obj,gen dirs in TOOL_MODE or restore them to default values in non-TOOL_MODE
# NOTE:
#  $(MAKE_CONTINUE) before expanding $(DEF_HEAD_CODE) adds 2 to $(MAKE_CONT) list (which is normally empty or contains 1 1...)
#  - so we know if $(DEF_HEAD_CODE) was expanded from $(MAKE_CONTINUE) - remove 2 from $(MAKE_CONT) in this case
#  - if $(DEF_HEAD_CODE) was expanded not from $(MAKE_CONTINUE) - no 2 in $(MAKE_CONT) - reset $(MAKE_CONT)
# NOTE: set CB_TOOL_MODE to remember that we are in TOOL_MODE - for $(MAKE_CONTINUE)
# NOTE: $(MTOP)/make_defs.mk may be included before $(MTOP)/make_parallel.mk,
#  to not execute $(DEF_HEAD_CODE) second time in $(MTOP)/make_parallel.mk, define DEF_HEAD_CODE_PROCESSED variable
# NOTE: add $(empty) as first line of $(DEF_HEAD_CODE) - to allow to join it and eval: $(eval $(MY_CODE)$(DEF_HEAD_CODE))
define DEF_HEAD_CODE
$(empty)
$(CLEAN_BUILD_CHECK_AT_HEAD)
ifeq ($(filter 2,$(MAKE_CONT)),)
MAKE_CONT:=
$(CHECK_MAKEFILE_NOT_PROCESSED)
PROCESSED_MAKEFILES += $(CURRENT_MAKEFILE)-
else
MAKE_CONT := $(subst 2,1,$(MAKE_CONT))
endif
CB_TOOL_MODE := $(if $(TOOL_MODE),T)
ifdef CB_TOOL_MODE
$(TOOL_OVERRIDE_DIRS)
else
$(SET_DEFAULT_DIRS)
endif
DEF_HEAD_CODE_PROCESSED := 1
endef

# expand this macro to evaluate default head code
# note: by default it expanded at start of next $(MAKE_CONTINUE) round
DEF_HEAD_CODE_EVAL = $(eval $(DEF_HEAD_CODE))

# code to $(eval) at end of each makefile
# include $(MTOP)/make_all.mk only if $(CB_INCLUDE_LEVEL) is empty and will not call $(MAKE_CONTINUE)
# if called from $(MAKE_CONTINUE), $1 - list of vars to save (may be empty)
# note: $(MAKE_CONTINUE) before expanding $(DEF_TAIL_CODE) adds 2 to $(MAKE_CONT) list
# note: $(MTOP)/make_parallel.mk executes $(eval $(call DEF_TAIL_CODE,@)) to not show debug info second time in $(DEF_TAIL_CODE_DEBUG)
define DEF_TAIL_CODE
$(CLEAN_BUILD_CHECK_AT_TAIL)
$(DEF_TAIL_CODE_DEBUG)
ifeq ($(CB_INCLUDE_LEVEL)$(filter 2,$(MAKE_CONT)),)
include $(MTOP)/make_all.mk
endif
endef

# expand this macro to evaluate default tail code
DEF_TAIL_CODE_EVAL = $(eval $(DEF_TAIL_CODE))

# get target variants list or default variant R
# $1 - EXE,LIB,...
# $2 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
# NOTE: add R to filter pattern to not filter-out default variant R
# NOTE: if filter gives no variants, return default variant R (regular)
GET_VARIANTS = $(patsubst ,R,$(filter R $(call $2,$1),$(wordlist 2,999999,$($1))))

# get target name - firstword, next words - variants
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# code to print targets which makefile is required to build
# $1 - targets to build (EXE,LIB,DLL,...)
# $2 - function to form target file name (FORM_TRG), must be defined at time of $(eval)
# $3 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
ifdef MDEBUG
define DEBUG_TARGETS1
ifneq ($$($t),)
$$(foreach v,$$(call GET_VARIANTS,$t,$3),$$(info $$(if $$(CB_TOOL_MODE),[TOOL]: )$t $$(subst \
  R ,,$$v )= $$(call GET_TARGET_NAME,$t) '$$(patsubst $(TOP)/%,%,$$(call $2,$t,$$v))'))
endif
endef
GET_DEBUG_TARGETS = $(foreach t,$1,$(newline)$(DEBUG_TARGETS1))
endif # MDEBUG

# form name of target objects directory
# $1 - target to build (EXE,LIB,DLL,...)
# $2 - target variant (may be empty for default variant)
# add target-specific suffix(_EXE,_LIB,_DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)_$1

# check that files $1 are generated in $(GEN_DIR), $(BIN_DIR), $(OBJ_DIR) or $(LIB_DIR)
ifdef MCHECK
define CHECK_GENERATED
ifneq ($(filter-out $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1),)
$$(error some files are generated not under $$(GEN_DIR), $$(BIN_DIR), $$(OBJ_DIR) or $$(LIB_DIR): $(filter-out \
  $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1))
endif
endef
endif # MCHECK

# add generated files $1 to build sequence
# note: files must be generated in $(GEN_DIR)
# note: directories for generated files will be auto-created
ADD_GENERATED = $(eval $(CHECK_GENERATED)$(newline)$(STD_TARGET_VARS))

# processed multi-target rules
# note: MULTI_TARGETS is never cleared, only appended
MULTI_TARGETS:=

# to count each call of $(MULTI_TARGET)
# note: MULTI_TARGET_NUM is never cleared, only appended
MULTI_TARGET_NUM:=

# when some tool generates many files, call the tool only once:
# assign to each generated multi-target rule an unique number
# and remember if rule with this number was already executed for one of multi-targets
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# NOTE: touch targets in the order they depend on each other
define MULTI_TARGET_RULE
$(STD_TARGET_VARS)
$1: $(call FIXPATH,$2)
	$$(if $$(filter $(words $(MULTI_TARGET_NUM)),$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS += $(words \
  $(MULTI_TARGET_NUM)))$$(call SUP,MGEN,$$@)$$(subst $$$$(newline),$$(newline),$(subst \
  $$(newline),$$$$(newline),$3$(foreach x,$1,$$(newline)$$(call SUP,TOUCH,$x)$$(call TOUCH,$x)))))
MULTI_TARGET_NUM += 1
endef

# make chain of dependency of multi-targets on each other: 2:1, 3:2, 4:3, ...
# $1 - list of generated files (absolute paths)
MULTI_TARGET_SEQ = $(if $(word 2,$1),$(word 2,$1): $(firstword $1)$(newline)$(call MULTI_TARGET_SEQ,$(wordlist 2,999999,$1)))

# NOTE: must not use $@ in rule because it may have different values (any target from multi-targets list),
#       must not use $(lastword $^) - tail of list of prerequisites may have different values (becase of different $@)
# $3 - rule
ifdef MCHECK
MULTI_TARGET_CHECK = $(if \
  $(filter-out $(words x$3x),$(words x$(subst $$@, ,$3)x)),$(warning \
   do not use $$@ in rule:$(newline)$3))$(if \
  $(filter-out $(words x$(strip $3)x),$(words x$(subst $$(lastword $$^), 1 ,$(strip $3))x)),$(warning \
   do not use $$(lastword $$^) in rule:$(newline)$3))
endif

# when some tool generates many files, call the tool only once
# $1 - list of generated files
# $2 - prerequisites
# $3 - rule
# note: directories for generated files will be auto-created
MULTI_TARGET = $(MULTI_TARGET_CHECK)$(eval $(MULTI_TARGET_SEQ)$(MULTI_TARGET_RULE))

# $(DEFINE_TARGETS_EVAL_NAME) - contains name of macro that when expanded
# evaluates code to define targes (at least, by evaluating $(DEF_TAIL_CODE))
DEFINE_TARGETS_EVAL_NAME := DEF_TAIL_CODE_EVAL

# define targets at end of makefile
# evaluate code in $($(DEFINE_TARGETS_EVAL_NAME)) only once, then reset DEFINE_TARGETS_EVAL to DEF_TAIL_CODE_EVAL
# note: surround $($(DEFINE_TARGETS_EVAL_NAME)) with fake $(if ...) to suppress any text output
# - $(DEFINE_TARGETS) must not expand to any text - to allow calling it via just $(DEFINE_TARGETS) in target makefile
DEFINE_TARGETS = $(if $($(DEFINE_TARGETS_EVAL_NAME))$(eval DEFINE_TARGETS_EVAL_NAME:=DEF_TAIL_CODE_EVAL),)

# may be used to save vars before $(MAKE_CONTINUE) and restore after
SAVE_VARS = $(eval $(foreach v,$1,$(newline)$v_:=$($v)))
RESTORE_VARS = $(eval $(foreach v,$1,$(newline)$v:=$($v_)))

# $(MAKE_CONTINUE_EVAL_NAME) - contains name of macro that when expanded evaluates code to prepare (at least, by evaluating $(DEF_HEAD_CODE))
MAKE_CONTINUE_EVAL_NAME := DEF_HEAD_CODE_EVAL

# increment MAKE_CONT, eval tail code with $(DEFINE_TARGETS)
# and start next circle - simulate including of appropriate $(MTOP)/make_c.mk or $(MTOP)/make_java.mk
# by evaluating head-code $($(MAKE_CONTINUE_EVAL_NAME)) - which must be initally set in $(MTOP)/make_c.mk or $(MTOP)/make_java.mk
# NOTE: evaluated code in $($(MAKE_CONTINUE_EVAL_NAME)) must re-define MAKE_CONTINUE_EVAL_NAME,
# because $(MAKE_CONTINUE) resets it to DEF_HEAD_CODE_EVAL
# NOTE: TOOL_MODE value may be changed in target makefile before $(MAKE_CONTINUE)
define MAKE_CONTINUE_BODY_EVAL
$(eval MAKE_CONT := $(MAKE_CONT) 2)
$(DEFINE_TARGETS)
$(eval MAKE_CONTINUE_EVAL:=$(MAKE_CONTINUE_EVAL_NAME)$(newline)MAKE_CONTINUE_EVAL_NAME:=DEF_HEAD_CODE_EVAL)
$($(MAKE_CONTINUE_EVAL))
endef

# how to join two or more makefiles in one makefile:
# include $(MTOP)/make_c.mk
# LIB = xxx1
# SRC = xxx.c
# $(MAKE_CONTINUE)
# LIB = xxx2
# SRC = xxx.c
# ...
# $(DEFINE_TARGETS)

# note: surround $(MAKE_CONTINUE) with fake $(if...) to suppress any text output
# - to be able to call it with just $(MAKE_CONTINUE) in target makefile
MAKE_CONTINUE = $(if $(if $1,$(SAVE_VARS))$(MAKE_CONTINUE_BODY_EVAL)$(if $1,$(RESTORE_VARS)),)

# helper macro: make DEPS list
# example: $(call FORM_DEPS,src1 src2,dep1 dep2 dep3) -> src1 dep1|dep2|dep3 src2 dep1|dep2|dep3
FORM_DEPS = $(addsuffix $(space)$(call join_with,$2,|),$1)

# get dependencies for source files
# $1 - source files, $2 - deps list of pairs: <source file> <dependency1>|<dependency2>|...
EXTRACT_DEPS = $(subst |, ,$(if $2,$(if $(filter $1,$(firstword $2)),$(word 2,$2) )$(call EXTRACT_DEPS,$1,$(wordlist 3,999999,$2))))

# protect variables from modifications in target makefiles
CLEAN_BUILD_PROTECTED_VARS += CLEAN_BUILD_PROTECTED_VARS MAKE_DEFS_INCLUDED MAKEFLAGS NO_DEPS DEBUG PROJECT_FEATURES \
  SUPPORTED_OSES SUPPORTED_CPUS SUPPORTED_TARGETS OS BUILD_OS CPU UCPU KCPU TCPU TARGET \
  VERBOSE INFOMF MDEBUG MCHECK CLEAN_BUILD_GET_PROTECTED_VALUE CLEAN_BUILD_CHECK_AT_HEAD \
  CLEAN_BUILD_REPLACE_PROTECTED_VARS1 CLEAN_BUILD_REPLACE_PROTECTED_VARS \
  CLEAN_BUILD_APPEND_PROTECTED_VARS1 CLEAN_BUILD_APPEND_PROTECTED_VARS \
  CLEAN_BUILD_CHECK_PROTECTED_VAR CLEAN_BUILD_CHECK_AT_TAIL CHECK_MAKEFILE_NOT_PROCESSED \
  SUP TOOL_IN_COLOR COLORIZE SED_MULTI_EXPR ospath isrelpath \
  DEF_BIN_DIR DEF_OBJ_DIR DEF_LIB_DIR DEF_GEN_DIR SET_DEFAULT_DIRS \
  BIN_DIR OBJ_DIR LIB_DIR GEN_DIR \
  TOOL_BASE MK_TOOLS_DIR GET_TOOLS GET_TOOL TOOLS_DIR TOOL_OVERRIDE_DIRS \
  FIX_ORDER_DEPS STD_TARGET_VARS1 STD_TARGET_VARS GET_VPREFIX ADDVPREFIX FIXPATH MAKEFILES_LEVEL \
  DEF_TAIL_CODE_DEBUG DEF_HEAD_CODE DEF_HEAD_CODE_EVAL DEF_TAIL_CODE DEF_TAIL_CODE_EVAL \
  GET_VARIANTS GET_TARGET_NAME DEBUG_TARGETS1 GET_DEBUG_TARGETS \
  FORM_OBJ_DIR CHECK_GENERATED ADD_GENERATED MULTI_TARGET_RULE MULTI_TARGET_SEQ MULTI_TARGET_CHECK MULTI_TARGET \
  DEFINE_TARGETS SAVE_VARS RESTORE_VARS MAKE_CONTINUE_BODY_EVAL MAKE_CONTINUE FORM_DEPS EXTRACT_DEPS

endif # MAKE_DEFS_INCLUDED

ifndef MAKE_DEFS_INCLUDED_BY
# if $(MTOP)/make_defs.mk is the first one included file in target Makefile,
# define bin/lib/obj/... dirs
$(eval $(DEF_HEAD_CODE))
else
# apply protection from $(DEF_HEAD_CODE) evaluation only once - reset MAKE_DEFS_INCLUDED_BY
MAKE_DEFS_INCLUDED_BY:=
endif
