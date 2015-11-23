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

# project's make_features.mk, if exists, must define something like:
# SUPPORTED_OSES    := WINXX SOLARIS LINUX
# SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc
# SUPPORTED_TARGETS := PROJECT PROJECTD
PROJECT_FEATURES ?= $(TOP)/make/make_features.mk
-include $(PROJECT_FEATURES)

ifndef SUPPORTED_OSES
$(error SUPPORTED_OSES not defined, it may be defined in $(subst $(TOP)/,$$(TOP)/,$(PROJECT_FEATURES)))
endif
ifndef SUPPORTED_CPUS
$(error SUPPORTED_CPUS not defined, it may be defined in $(subst $(TOP)/,$$(TOP)/,$(PROJECT_FEATURES)))
endif
ifndef SUPPORTED_TARGETS
$(error SUPPORTED_TARGETS not defined, it may be defined in $(subst $(TOP)/,$$(TOP)/,$(PROJECT_FEATURES)))
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
MDEBUG := $D
else
MDEBUG:=
endif

# run via $(MAKE) C=1 to check makefiles
ifeq ("$(origin C)","command line")
MCHECK := $C
else
MCHECK:=
endif

# supress output of executed build tool, print some pretty message instead, like "CC  source.c"
# print $(MF) relative to current directory
ifeq ($(VERBOSE),1)
ifdef INFOMF
SUPRESS = $(info $(patsubst $(patsubst $(TOP)/%,%,$(CURDIR))/%,%,$(MF))$(MCONT):)
else
SUPRESS:=
endif
else ifdef INFOMF
SUPRESS = @$(info $(patsubst $(patsubst $(TOP)/%,%,$(CURDIR))/%,%,$(MF))$(MCONT):$(COLORIZE))
else
SUPRESS = @$(info $(COLORIZE))
endif

# standard target-specific variables
# $1       - target file to build (absolute path)
# $(MF)    - name of makefile which specifies how to build the target (path relative to $(TOP))
# $(MCONT) - number of section in makefile after a call of $(MAKE_CONTINUE)
# $(TMD)   - T if target is built in TOOL_MODE
# NOTE: $(MAKE_CONT) list is empty or 1 1 1 1...
define STD_TARGET_VARS
$1: MF    := $(CURRENT_MAKEFILE)
$1: MCONT := $(if $(MAKE_CONT),@$(words $(subst 1x,1 x,$(MAKE_CONT)x)))
$1: TMD   := $(if $(TOOL_MODE),T)
endef

# print in color name of called tool $1
TOOL_IN_COLOR = $(subst |,,$(subst \
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
  |MKDIR|,[00;36mMKDIR[0m,$(subst \
  |TOUCH|,[00;36mTOUCH[0m,|$1|))))))))))))))))))

# print in color short name of called tool $1 with argument $2
COLORIZE = $(TOOL_IN_COLOR)$(padto)$2

# define utilities of the OS we are building on
include $(MTOP)/$(BUILD_OS)/make_tools.mk

# for UNIX: don't change paths when convertig from make internal file path to path accepted by $(BUILD_OS)
ospath ?= $1

# for UNIX: absolute paths are started with /
isrelpath ?= $(filter-out /%,$1)

# make current makefile path relative to $(TOP) directory
CURRENT_MAKEFILE := $(subst \,/,$(firstword $(MAKEFILE_LIST)))
ifeq ($(filter $(TOP)/%,$(CURRENT_MAKEFILE),)
CURRENT_MAKEFILE := $(abspath $(CURDIR)/$(CURRENT_MAKEFILE))
endif
CURRENT_MAKEFILE := $(patsubst $(TOP)/%,%,$(CURRENT_MAKEFILE))

# check that we are building right sources
ifeq ($(call isrelpath,$(CURRENT_MAKEFILE)),)
$(error TOP=$(TOP) is not the root directory of current makefile $(CURRENT_MAKEFILE))
endif

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), etc...
XTOP ?= $(TOP)

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

# $(PROJECT_FEATURES) makefile may forward-reference some of default dirs,
# ensure they are defined when we will use defs from $(PROJECT_FEATURES)
$(eval $(SET_DEFAULT_DIRS))

# needed default dirs
# needed directories - we will create them in $(MTOP)/make_all.mk
NEEDED_DIRS := $(DEF_BIN_DIR) $(DEF_LIB_DIR) $(DEF_BLD_DIR) $(DEF_BLDINC_DIR) $(DEF_BLDSRC_DIR)

# function to add directories to list of needed dirs
ADD_DIR_RULES = $(eval NEEDED_DIRS += $1)

# NOTE: to allow parallel builds for different combinations of
#  $(OS)/$(KCPU)/$(UCPU)/$(TARGET) tool dir must be unique for each such combination
#  (this is true for TOOL_BASE = $(DEF_BLD_DIR))
TOOL_BASE ?= $(DEF_BLD_DIR)
TOOL_BASE := $(TOOL_BASE)

# where tools are built, $1 - TOOL_BASE, $2 - TCPU
MK_TOOLS_DIR = $1/TOOL-$2-$(TARGET)/bin

# call with $1 - TOOL_BASE, $2 - TCPU, $3 - tool name(s) to get paths to the tools executables
# note: it's possible to dynamically define value of $(TOOL_SUFFIX) from tool name $x
GET_TOOLS = $(foreach x,$(addprefix $(MK_TOOLS_DIR)/,$3),$(addsuffix $(TOOL_SUFFIX),$x))

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

# needed tool dirs
NEEDED_DIRS += $(addprefix $(TOOLS_DIR)/,bin obj lib bld bld/include bld/src)

# compute values of next variables right after +=, not at call time:
# CLEAN          - files/directories list to delete on $(MAKE) clean
# CLEAN_COMMANDS - code to $(eval) to get clean commands to execute on $(MAKE) clean - see $(MTOP)/make_all.mk
CLEAN:=
CLEAN_COMMANDS:=

# add $(VPREFIX) (path to directory of currently executing makefile relative to $(CURDIR)) value to non-absolute paths
# then make absolute paths
FIXPATH = $(abspath $(foreach x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x))

# $(ORDER_DEPS)          - order-only dependencies to add to all leaf prerequisites for the targets
# $(VPREFIX)             - relative path from $(CURDIR) to currently processing makefile, either empty or dir/
# $(CURRENT_MAKEFILE_TM) - timestamp of currently processing makefile,
#                          timestamp is updated after all targets of current makefile are successfully built
ORDER_DEPS:=
VPREFIX := $(filter-out ./,$(dir $(patsubst $(CURDIR)/%,%,$(subst \,/,$(firstword $(MAKEFILE_LIST))))))

# list of all processed makefiles names relative to $(TOP) - like $(CURRENT_MAKEFILE)
TOP_MAKEFILES:=

# convert list "make1 make2 make3" -> "..."
ifdef MDEBUG
MAKEFILES_LEVEL = $(if $1,.$(call MAKEFILES_LEVEL,$(wordlist 2,999999,$1)))
endif

# functions to support cross-makefiles dependencies

# add $(VPREFIX) if makefile $1 is not $(TOP)-related, add /Makefile if $1 is a directory
NORM_MAKEFILE = $(if $(filter-out $(TOP)/%,$1),$(VPREFIX))$1$(if $(filter-out %.mk,$1),/Makefile)

# compute VPREFIX to included normalized makefile $1
GET_VPREFIX = $(if $(filter $(TOP)/%,$1),$(call reldir,$(CURDIR),$(dir $1)),$(filter-out ./,$(dir $(call normp,$1))))

# make $(TOP)-relative path to included makefile $1, $2 - VPREFIX for included makefile
MAKE_TOP_MAKEFILE1 = $(call normp,$(patsubst $(TOP)/%,%,$(CURDIR)/)$2$(notdir $1))
MAKE_TOP_MAKEFILE2 = $(call MAKE_TOP_MAKEFILE1,$1,$(call GET_VPREFIX,$1))
MAKE_TOP_MAKEFILE = $(call MAKE_TOP_MAKEFILE2,$(call NORM_MAKEFILE,$1))

# convert list of makefiles to list of $(TOP)-related makefile names
GET_MAKEFILE_DEPS = $(foreach x,$1,$(call MAKE_TOP_MAKEFILE,$x))

# code to $(eval) at beginning of each makefile
# 1) add $(CURRENT_MAKEFILE) to build
# 2) change bin,lib/obj dirs in TOOL_MODE or restore them to default values in non-TOOL_MODE
# NOTE:
#  $(MAKE_CONTINUE) always adds 2 to $(MAKE_CONT) before expanding $(DEF_HEAD_CODE)
#  - so we know if $(DEF_HEAD_CODE) was expanded from $(MAKE_CONTINUE) - remove 2 from $(MAKE_CONT) in this case
#  - if $(DEF_HEAD_CODE) was expanded not from $(MAKE_CONTINUE) - reset $(MAKE_CONT)
# NOTE: $(MTOP)/make_defs.mk may be included before $(MTOP)/make_parallel.mk,
#  to not execute $(DEF_HEAD_CODE) second time in $(MTOP)/make_parallel.mk, define DEF_HEAD_CODE_PROCESSED variable
define DEF_HEAD_CODE
ifeq ($(filter 2,$(MAKE_CONT)),)
MAKE_CONT:=
ifdef MDEBUG
$$(info $(call MAKEFILES_LEVEL,$(SUB_LEVEL)) $(CURRENT_MAKEFILE)$(if $(ORDER_DEPS), | $(patsubst $(TOP)/%,$$$$(TOP)/%,$(ORDER_DEPS))))
endif
ifneq ($(filter $(CURRENT_MAKEFILE),$(TOP_MAKEFILES)),)
$$(info Warning: makefile $(CURRENT_MAKEFILE) is already processed!)
else
TOP_MAKEFILES += $(CURRENT_MAKEFILE)
endif
else
MAKE_CONT := $(filter-out 2,$(MAKE_CONT))
endif
ifdef TOOL_MODE
$(TOOL_OVERRIDE_DIRS)
else
$(SET_DEFAULT_DIRS)
endif
DEF_HEAD_CODE_PROCESSED := 1
ifdef DEP_MAKEFILES
ORDER_DEPS := $(sort $(ORDER_DEPS) $(call GET_MAKEFILE_DEPS,$(DEP_MAKEFILES)))
DEP_MAKEFILES:=
endif
endef

# code to $(eval) at end of each makefile
# include $(MTOP)/make_all.mk only if SUB_LEVEL is empty and will not call $(MAKE_CONTINUE)
# if called from $(MAKE_CONTINUE), $1 - list of vars to save - check if needed to save TOOL_MODE
DEF_TAIL_CODE = $(eval $(if $(SUB_LEVEL)$(filter 2,$(MAKE_CONT)),$(if \
  $(filter TOOL_MODE,$1),,TOOL_MODE:=$(newline))DEF_HEAD_CODE_PROCESSED:=,include $(MTOP)/make_all.mk))

# get target variants list or default variant R
# $1 - EXE,LIB,...
# $2 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
# NOTE: add R to filter pattern to not filter-out default variant R
GET_VARIANTS = $(patsubst ,R,$(filter R $(call $2,$1),$(wordlist 2,999999,$($1))))

# get target name
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# code to print targets which makefile is required to build
# $1 - targets to build (value of $(BLD_TARGETS))
# $2 - function to form target file name (FORM_TRG), must be defined at time of $(eval)
# $3 - variants filter function (VARIANTS_FILTER), must be defined at time of $(eval)
ifdef MDEBUG
define DEBUG_TARGETS1
ifneq ($$($t),)
$$(foreach v,$$(call GET_VARIANTS,$t,$3),$$(info $$(if $$(TOOL_MODE),[TOOL]: )$t $$(subst \
  R ,,$$v )= $$(call GET_TARGET_NAME,$t) '$$(patsubst $(TOP)/%,%,$$(call $2,$t,$$v))'))
endif
endef
GET_DEBUG_TARGETS = $(foreach t,$1,$(newline)$(DEBUG_TARGETS1))
endif

# form name of target objects directory
# $1 - target to build (value of $(BLD_TARGETS))
# $2 - target variant (may be empty for default variant)
# add target-specific prefix (EXE_,LIB_,DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$1_$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)

# add generated files $1 to build sequence, $2 - directories of generated files
define ADD_GENERATED1
$(STD_TARGET_VARS)
$(CURRENT_MAKEFILE): $1
CLEAN += $1
$1: | $2 $(ORDER_DEPS)
NEEDED_DIRS += $2
endef
ADD_GENERATED = $(eval $(call ADD_GENERATED1,$1,$(patsubst %/,%,$(dir $1))))

# processed multi-target rules
MULTI_TARGETS:=

# to count each call of $(MULTI_TARGET)
MULTI_TARGET_NUM:=

# when some tool generates many files, call the tool only once
# $1 - list of generated files
# $2 - prerequisites
# $3 - rule
define MULTI_TARGET_RULE
$1: $2 | $(ORDER_DEPS)
	$$(if $$(filter $(words $(MULTI_TARGET_NUM)),$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS += $(words \
  $(MULTI_TARGET_NUM)))$$(call SUPRESS,MGEN,$$@)$$(subst $$$$(newline),$$(newline),$(subst \
  $$(newline),$$$$(newline),$3$(foreach x,$1,$$(newline)$$(call SUPRESS,TOUCH,$x)$$(call TOUCH,$x)))))
MULTI_TARGET_NUM += 1
endef

MULTI_TARGET_SEQ = $(if $(word 2,$1),$(word 2,$1): $(firstword $1)$(newline)$(call MULTI_TARGET_SEQ,$(wordlist 2,999999,$1)))

# NOTE: don't use $@ in rule because it may have different values,
#       don't use $(lastword $^) - tail of list of prerequisites may have different values
MULTI_TARGET_CHECK = $(if $(filter-out $(words x$3x),$(words x$(subst $$@, ,$3)x)),$(info Warning: don't use $$@ in rule:$(newline)$3))$(if \
  $(filter-out $(words x$(strip $3)x),$(words x$(subst $$(lastword $$^), 1 ,$(strip $3))x)),$(info Warning: don't use $$(lastword $$^) in rule:$(newline)$3))

# when some tool generates many files, call the tool only once
# $1 - list of generated files
# $2 - prerequisites
# $3 - rule
MULTI_TARGET = $(MULTI_TARGET_CHECK)$(eval $(MULTI_TARGET_SEQ)$(MULTI_TARGET_RULE))

# may be used to save vars before $(MAKE_CONTINUE) and restore after
SAVE_VARS = $(eval $(foreach v,$1,$(newline)$v_:=$($v)))
RESTORE_VARS = $(eval $(foreach v,$1,$(newline)$v:=$($v_)))

endif # MAKE_DEFS_INCLUDED

ifndef MAKE_DEFS_INCLUDED_BY
# if $(MTOP)/make_defs.mk is the first included file in target Makefile,
# define bin/lib/obj/etc... dirs
$(eval $(DEF_HEAD_CODE))
else
# don't evaluate $(DEF_HEAD_CODE) only once, then reset MAKE_DEFS_INCLUDED_BY
MAKE_DEFS_INCLUDED_BY:=
endif
