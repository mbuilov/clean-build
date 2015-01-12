ifndef MAKE_DEFS_INCLUDED

# this file included by main make_header.mk
# also this file may be included at beginning of target Makefile
MAKE_DEFS_INCLUDED := 1

# legend:
# $< - name of the first prerequisite
# $^ - names of all prerequisites
# $@ - file name of the target
# $? - prerequisites newer than the target

# standard defines & checks
# NOTE: $(OS), $(SUPPORTED_OSES), $(CPU) or $(UCPU),$(KCPU),$(TCPU), $(SUPPORTED_CPUS), $(TARGET) and $(SUPPORTED_TARGETS) must be defined

# disable builtin rules and variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

include $(MTOP)/make_functions.mk

# make_features.mk must define:
# SUPPORTED_OSES    := WINXX SOLARIS LINUX
# SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc
# SUPPORTED_TARGETS := PROJECT PROJECTD
include $(TOP)/make/make_features.mk

# current makefile path relative from $(TOP) directory
CURRENT_MAKEFILE := $(subst \,/,$(firstword $(MAKEFILE_LIST)))
CURRENT_MAKEFILE := $(patsubst $(TOP)/%,%,$(if $(filter $(TOP)/%,$(CURRENT_MAKEFILE)),$(CURRENT_MAKEFILE),$(call normp,$(CURDIR)/$(CURRENT_MAKEFILE))))

# check that we are building right sources
ifneq ($(filter /%,$(CURRENT_MAKEFILE)),)
$(error TOP=$(TOP) is not the root directory of current makefile $(CURRENT_MAKEFILE))
endif

# directory for built files
XTOP ?= $(TOP)

# target OS
ifndef OS
$(error OS undefined, example: $(SUPPORTED_OSES))
endif
ifeq ($(filter $(OS),$(SUPPORTED_OSES)),)
$(error unknown OS=$(OS), please pick one of: $(SUPPORTED_OSES))
endif

# NOTE: don't use CPU variable in target makefiles, use UCPU or KCPU instead

# CPU for user-level
ifndef UCPU
ifndef CPU
$(error UCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
UCPU := $(CPU)
endif
endif
# CPU for kernel-level
ifndef KCPU
ifndef CPU
$(error KCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
KCPU := $(CPU)
endif
endif
# CPU for build-tools
ifndef TCPU
ifndef CPU
$(error TCPU or CPU undefined, example: $(SUPPORTED_CPUS))
else
TCPU := $(CPU)
endif
endif

ifeq ($(filter $(UCPU),$(SUPPORTED_CPUS)),)
$(error unknown $(if $(UCPU),U)CPU=$(UCPU), please pick one of: $(SUPPORTED_CPUS))
endif
ifeq ($(filter $(KCPU),$(SUPPORTED_CPUS)),)
$(error unknown $(if $(KCPU),K)CPU=$(KCPU), please pick one of: $(SUPPORTED_CPUS))
endif
ifeq ($(filter $(TCPU),$(SUPPORTED_CPUS)),)
$(error unknown $(if $(TCPU),T)CPU=$(TCPU), please pick one of: $(SUPPORTED_CPUS))
endif

# what to build
# to check for DEBUG, use $(filter %D,$(TARGET))
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
ifndef VERBOSE
VERBOSE := 0
endif

# run via $(MAKE) M=1 to print makefile name the target comes from
ifeq ("$(origin M)","command line")
INFOMF := $M
else
INFOMF:=
endif

# run via $(MAKE) D=1 to debug makefiles
ifeq ("$(origin D)","command line")
DEBUG := $D
else
DEBUG:=
endif

# supress output of executed build tool, print some message instead like "CC  source.c"
ifeq ($(VERBOSE),1)
ifdef INFOMF
SUPRESS = $(info $(patsubst $(patsubst $(TOP)/%,%,$(CURDIR))/%,%,$(MF))$(if $(MCONT),@$(words $(MCONT))):)
else
SUPRESS:=
endif
else ifdef INFOMF
SUPRESS = @$(info $(patsubst $(patsubst $(TOP)/%,%,$(CURDIR))/%,%,$(MF))$(if $(MCONT),@$(words $(MCONT))):$(COLORIZE))
else
SUPRESS = @$(info $(COLORIZE))
endif

# standard target-specific variables
# $1       - target file to build
# $(MF)    - name of makefile which specifies how to build the target
# $(MCONT) - number of section in makefile which includes make_continue.mk
# $(TMD)   - T if target is built in TOOL_MODE
define STD_TARGET_VARS
$1: MF    := $(CURRENT_MAKEFILE)
$1: MCONT := $(MAKE_CONT)
$1: TMD   := $(if $(TOOL_MODE),T)
endef

# print in color called tool
COLORIZE1 = $(if\
  $(filter CC,$1),[01;31mCC[0m     $2,$(if\
  $(filter CXX,$1),[01;36mCXX[0m    $2,$(if\
  $(filter JAVAC,$1),[01;36mJAVAC[0m   $2,$(if\
  $(filter AR,$1),[01;32mAR[0m     $2,$(if\
  $(filter LD,$1),[01;33mLD[0m     $2,$(if\
  $(filter JAR,$1),[01;33mJAR[0m    $2,$(if\
  $(filter KCC,$1),[00;31mKCC[0m    $2,$(if\
  $(filter KLD,$1),[00;33mKLD[0m    $2,$(if\
  $(filter ASM,$1),[00;37mASM[0m    $2,$(if\
  $(filter MKDIR,$1),[00;36mMKDIR[0m  $2,$(if\
  $(filter TOUCH,$1),[00;36mTOUCH[0m  $2,$(if\
  $(filter CP,$1),[00;36mCP[0m     $2,$(if\
  $(filter TCXX,$1),[00;32mTCXX[0m   $2,$(if\
  $(filter TCC,$1),[00;32mTCC[0m    $2,$(if\
  $(filter TLD,$1),[00;32mTLD[0m    $2,$(if\
  $(filter GEN,$1),[01;32mGEN[0m    $2,$(if\
  $(filter MGEN,$1),[01;32mMGEN[0m   $2,$3)))))))))))))))))
COLORIZE = $(call COLORIZE1,$(firstword $1),$(wordlist 2,9999,$1),$1)

include $(MTOP)/$(OS)/make_tools.mk

# output directories:
# bin - for executables, dlls, res
# lib - for libraries, shared objects
# obj - for object files
# bld - for generated files (headers, sources, resources, etc)
# NOTE: to allow parallel builds for different combinations of
#  $(OS)/$(KCPU)/$(UCPU)/$(TARGET) create unique directories for each combination
DEF_BIN_DIR := $(XTOP)/bin/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_OBJ_DIR := $(XTOP)/obj/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_LIB_DIR := $(XTOP)/lib/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_BLD_DIR := $(XTOP)/bld/$(OS)-$(KCPU)-$(UCPU)-$(TARGET)
DEF_BLDINC_DIR := $(DEF_BLD_DIR)/include
DEF_BLDSRC_DIR := $(DEF_BLD_DIR)/src

# directory for makefiles timestamps
BLD_MAKEFILES_TIMESTAMPS_DIR := $(DEF_BLD_DIR)/mk_stm
$(BLD_MAKEFILES_TIMESTAMPS_DIR):
	$(call SUPRESS,MKDIR  $@)$(call MKDIR,$@)

# make makefile timestamp file name
# $1 - $(CURRENT_MAKEFILE)
MAKE_MAKEFILE_TIMESTAMP = $(BLD_MAKEFILES_TIMESTAMPS_DIR)/$(subst /,-,$1).m

# restore default dirs after tool mode
define SET_DEFAULT_DIRS1
BIN_DIR := $(DEF_BIN_DIR)
OBJ_DIR := $(DEF_OBJ_DIR)
LIB_DIR := $(DEF_LIB_DIR)
BLD_DIR := $(DEF_BLD_DIR)
BLDINC_DIR := $(DEF_BLDINC_DIR)
BLDSRC_DIR := $(DEF_BLDSRC_DIR)
endef
SET_DEFAULT_DIRS := $(SET_DEFAULT_DIRS1)

# make_features.mk may forward-reference some of default dirs,
# ensure they are defined when we will use defs from make_features.mk
$(eval $(SET_DEFAULT_DIRS))

# add rules to create directories $1
DIR_RULES:=
define ADD_DIR_RULES_TEMPL
DIR_RULES += $1
$1:
	$$(call SUPRESS,MKDIR  $$@)$$(call MKDIR,$$@)
endef
ADD_DIR_RULES_TEMPL1 = $(if $1,$(ADD_DIR_RULES_TEMPL))

ADD_UNIQ_DIR_RULES_TEMPLATE = $(if $(filter $(BLD_MAKEFILES_TIMESTAMPS_DIR),$1),$(error \
  $(BLD_MAKEFILES_TIMESTAMPS_DIR) is reserved directory for makefiles timestamps))$(call \
  ADD_DIR_RULES_TEMPL1,$(filter-out $(DIR_RULES),$1))

ADD_UNIQ_DIR_RULES = $(eval $(ADD_UNIQ_DIR_RULES_TEMPLATE))
ADD_DIR_RULES = $(call ADD_UNIQ_DIR_RULES,$(sort $1))

$(call ADD_UNIQ_DIR_RULES,$(DEF_BIN_DIR) $(DEF_LIB_DIR) $(DEF_BLD_DIR) $(DEF_BLDINC_DIR) $(DEF_BLDSRC_DIR))

# NOTE: to allow parallel builds for different combinations of
#  $(OS)/$(KCPU)/$(UCPU)/$(TARGET) tool dir must be unique for each such combination
#  (this is true for TOOL_BASE = $(DEF_BLD_DIR))
TOOL_BASE ?= $(DEF_BLD_DIR)
TOOL_BASE := $(TOOL_BASE)

# where tools are built, $1 - TOOL_BASE, $2 - TCPU
MK_TOOLS_DIR = $1/TOOL-$2-$(TARGET)/bin

# call with $1 - TOOL_BASE, $2 - TCPU, $3 - tool name(s) to get path to the tools executables
GET_TOOLS = $(addsuffix $(TOOL_SUFFIX),$(addprefix $(MK_TOOLS_DIR)/,$3))

# get path to a tool $1 for current $(TOOL_BASE) and $(TCPU)
GET_TOOL = $(call GET_TOOLS,$(TOOL_BASE),$(TCPU),$1)

# override dirs in tool mode
TOOLS_DIR := $(TOOL_BASE)/TOOL-$(TCPU)-$(TARGET)
define TOOL_OVERRIDE_DIRS1
BIN_DIR := $(TOOLS_DIR)/bin
OBJ_DIR := $(TOOLS_DIR)/obj
LIB_DIR := $(TOOLS_DIR)/lib
BLD_DIR := $(TOOLS_DIR)/bld
BLDINC_DIR := $(TOOLS_DIR)/bld/include
BLDSRC_DIR := $(TOOLS_DIR)/bld/src
endef
TOOL_OVERRIDE_DIRS := $(TOOL_OVERRIDE_DIRS1)

$(call ADD_UNIQ_DIR_RULES,$(addprefix $(TOOLS_DIR)/,bin obj lib bld bld/include bld/src))

# compute values of next variables right after +=, not at call time:
# CLEAN          - files/directories list to delete on $(MAKE) clean
# CLEAN_COMMANDS - code to $(eval) to get clean commands to execute on $(MAKE) clean
CLEAN:=
CLEAN_COMMANDS:=

# add $(VPREFIX) (path to directory of currently executing makefile relative to $(CURDIR)) value to non-absolute paths
FIXPATH = $(foreach x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x)

# $(CURRENT_DEPS)        - dependencies to add to all leaf sources for the targets
# $(VPREFIX)             - relative path from $(CURDIR) to currently processing makefile, either empty or dir/
# $(CURRENT_MAKEFILE_TM) - timestamp of currently processing makefile,
#                          timestamp is updated after all targets of current makefile are successfully built
CURRENT_DEPS:=
VPREFIX := $(filter-out ./,$(dir $(patsubst $(CURDIR)/%,%,$(subst \,/,$(firstword $(MAKEFILE_LIST))))))
CURRENT_MAKEFILE_TM := $(call MAKE_MAKEFILE_TIMESTAMP,$(CURRENT_MAKEFILE))

# list of all processed makefiles
PROCESSED_MAKEFILES:=

# code to $(eval) at beginning of each makefile
# 1) add $(CURRENT_MAKEFILE_TM) to build
# 2) change bin,lib/obj dirs in TOOL_MODE or restore them to default values in non-TOOL_MODE
# NOTE:
#  make_continue.mk always adds 2 to $(MAKE_CONT) before including $(MAKE_CONTINUE_HEADER)
#  - so we know if this file was processed from make_continue.mk, remove 2 from $(MAKE_CONT)
#  - if next time this file will be processed not from make_continue.mk, clean $(MAKE_CONT)
# NOTE: make_defs.mk may be included before make_parallel.mk,
#  to not execute $(DEF_HEAD_CODE) there define DEF_HEAD_CODE_PROCESSED
define DEF_HEAD_CODE
ifeq ($(filter 2,$(MAKE_CONT)),)
MAKE_CONT:=
ifneq ($(filter $(CURRENT_MAKEFILE_TM),$(PROCESSED_MAKEFILES)),)
$$(info Warning: makefile $(CURRENT_MAKEFILE) is already processed!)
else
PROCESSED_MAKEFILES += $(CURRENT_MAKEFILE_TM)
endif
else
MAKE_CONT := $(filter-out 2,$(MAKE_CONT))
endif
ifdef DEBUG
$$(info $(subst 1,.,$(subst 1 ,.,$(SUB_LEVEL))) $(CURRENT_MAKEFILE)$(if $(MAKE_CONT),+$(words $(MAKE_CONT)))$(if $(CURRENT_DEPS), : $(patsubst $(TOP)/%,%,$(CURRENT_DEPS))))
endif
ifdef TOOL_MODE
$(TOOL_OVERRIDE_DIRS)
else
$(SET_DEFAULT_DIRS)
endif
DEF_HEAD_CODE_PROCESSED := 1
endef

# code to $(eval) at end of each makefile
define DEF_TAIL_CODE1
$(if $(SUB_LEVEL),TOOL_MODE:=$(newline)DEF_HEAD_CODE_PROCESSED:=,include $(MTOP)/make_all.mk)
endef
DEF_TAIL_CODE = $(eval $(DEF_TAIL_CODE1))

# get target variants list or default variant R
# $1 - EXE,LIB,...
# $2 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
# NOTE: add R to filter to not filter-out default variant R
GET_VARIANTS = $(patsubst ,R,$(filter R $(call $2,$1),$(wordlist 2,999999,$($1))))

# get target name
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# code to print targets which makefile is required to build
# $1 - targets to build (value of $(BLD_TARGETS))
# $2 - function to form target file name (FORM_TRG), must be defined at time of $(eval)
# $3 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
ifdef DEBUG
define DEBUG_TARGETS1
ifneq ($$($t),)
$$(foreach v,$$(call GET_VARIANTS,$t,$3),$$(info $$(if $$(TOOL_MODE),[TOOL]: )$t $$(subst \
  R ,,$$v ):= $$(call GET_TARGET_NAME,$t) ($$(patsubst $(TOP)/%,%,$$(call $2,$t,$$v)))))
endif
endef
GET_DEBUG_TARGETS = $(foreach t,$1,$(newline)$(DEBUG_TARGETS1))
endif

# form name of target objects directory
# $1 - target to build (value of $(BLD_TARGETS))
# $2 - target variant (may be empty for default variant)
# add target-specific prefix (EXE_,LIB_,DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$1_$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)

# add generated files to build sequence
define ADD_GENERATED1
$(STD_TARGET_VARS)
$(CURRENT_MAKEFILE_TM): $1
CLEAN += $1
$1: $(CURRENT_DEPS) | $2
$(call ADD_UNIQ_DIR_RULES_TEMPLATE,$2)
endef
ADD_GENERATED = $(eval $(call ADD_GENERATED1,$1,$(patsubst %/,%,$(sort $(dir $1)))))

MULTI_TARGETS :=
MULTI_TARGET_NUM :=
# when some tool generates many files, call the tool only once
# $1 - list of generated files
# $2 - prerequisites
# $3 - rule
define MULTI_TARGET_RULE
$1: $2 $(CURRENT_DEPS)
	$$(subst $$$$(newline),$$(newline),$$(if $$(filter $(words $(MULTI_TARGET_NUM)),$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS += $(words \
  $(MULTI_TARGET_NUM)))$$(call SUPRESS,MGEN   $$@)$(subst $$(newline),$$$$(newline),$3$(foreach x,$1,$$(newline)$$(call SUPRESS,TOUCH  $x)$$(call TOUCH,$x)))))
MULTI_TARGET_NUM += 1
endef
MULTI_TARGET_SEQ = $(if $(word 2,$1),$(word 2,$1): $(firstword $1)$(newline)$(call MULTI_TARGET_SEQ,$(wordlist 2,999999,$1)))
# NOTE: don't use $@ in rule because it may have different values,
#       don't use $(lastword $^) - tail of list of prerequisites may have different values
MULTI_TARGET_CHECK = $(if $(filter-out $(words x$3x),$(words x$(subst $$@, ,$3)x)),$(info Warning: don't use $$@ in rule:$(newline)$3))$(if \
  $(filter-out $(words x$(strip $3)x),$(words x$(subst $$(lastword $$^), 1 ,$(strip $3))x)),$(info Warning: don't use $$(lastword $$^) in rule:$(newline)$3))
MULTI_TARGET = $(MULTI_TARGET_CHECK)$(eval $(MULTI_TARGET_SEQ)$(MULTI_TARGET_RULE))

endif # MAKE_DEFS_INCLUDED

ifndef MAKE_DEFS_INCLUDED_BY
# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))
else
MAKE_DEFS_INCLUDED_BY:=
endif
