#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules and definitions for building targets

ifeq (,$(MAKE_VERSION))
$(error MAKE_VERSION not defined, ensure you are using GNU Make of version 3.81 or later)
endif

ifneq (3.80,$(word 1,$(sort $(MAKE_VERSION) 3.80)))
$(error required GNU Make of version 3.81 or later)
endif

# assume project makefile, which has included this makefile,
# defines some variables - save list of those variables
PROJECT_VARS_NAMES := $(filter-out \
  MAKEFLAGS CURDIR SHELL MAKEFILE_LIST .DEFAULT_GOAL,$(foreach \
  v,$(.VARIABLES),$(if $(filter file,$(origin $v)),$v)))

# clean-build version: major.minor.patch
override CLEAN_BUILD_VERSION := 0.6.3

# disable builtin rules and variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables

# reset if not defined
ifndef MAKECMDGOALS
MAKECMDGOALS:=
endif

# drop make's default legacy rules - we'll use custom ones
.SUFFIXES:

# delete target file if failed to execute any of commands to make it
.DELETE_ON_ERROR:

# clean-build root directory (absolute path)
CLEAN_BUILD_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# include functions library
include $(CLEAN_BUILD_DIR)/protection.mk
include $(CLEAN_BUILD_DIR)/functions.mk

# CLEAN_BUILD_REQUIRED_VERSION - clean-build version required by project makefiles
# it is normally defined in project configuration makefile like:
# CLEAN_BUILD_REQUIRED_VERSION := 0.3
# note: dot not take CLEAN_BUILD_REQUIRED_VERSION value from environment
ifeq (environment,$(origin CLEAN_BUILD_REQUIRED_VERSION))
CLEAN_BUILD_REQUIRED_VERSION := 0.0.0
endif

# check required clean-build version
ifeq (,$(call ver_compatible,$(CLEAN_BUILD_VERSION),$(CLEAN_BUILD_REQUIRED_VERSION)))
$(error incompatible clean-build version: $(CLEAN_BUILD_VERSION), project needs: $(CLEAN_BUILD_REQUIRED_VERSION))
endif

# clean-build always sets default values for variables - to not inherit them from environment
# to override these defaults by project-defined ones, use override directive
define OVERRIDE_VAR_TEMPLATE

override define $v
$(value $v)
$(endef)
$(if $(filter simple,$(flavor $v)),override $v:=$$(value $v))

endef
$(eval $(foreach v,$(PROJECT_VARS_NAMES),$(OVERRIDE_VAR_TEMPLATE)))

# needed directories - we will create them in $(CLEAN_BUILD_DIR)/all.mk
# note: NEEDED_DIRS is never cleared, only appended
NEEDED_DIRS:=

# save configuration as result of 'conf' goal, if $(CONFIG_FILE) is defined
# note: if CONFIG_FILE is defined in project configuration makefile under $(BUILD) directory as:
# override CONFIG_FILE := $(BUILD)/conf.mk
# then it will be deleted together with $(BUILD) directory in clean-build implementation of 'distclean' goal
include $(CLEAN_BUILD_DIR)/confsup.mk

# BUILD - directory for built files - must be defined either in command line
# or in project configuration file before including this file, via:
# override BUILD := /my_project/build
ifeq (environment,$(origin BUILD))
$(error BUILD must not be taken from environment,\
 please define BUILD either in command line or in project configuration\
 makefile (via override directive) before including this file)
endif

# do not inherit BUILD from environment
BUILD:=

# ensure that BUILD is non-recursive (simple)
override BUILD := $(abspath $(BUILD))

ifndef BUILD
$(error BUILD undefined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(BUILD)))
$(error BUILD=$(BUILD), path to generated files must not contain spaces)
endif

# by default, do not build kernel modules and drivers
# note: DRIVERS_SUPPORT may be overridden either in command line
# or in project configuration file before including this file, via:
# override DRIVERS_SUPPORT := 1
DRIVERS_SUPPORT:=

# ensure DRIVERS_SUPPORT is non-recursive (simple)
override DRIVERS_SUPPORT := $(DRIVERS_SUPPORT:0=)

# standard variables that may be overridden:
# TARGET                - one of $(SUPPORTED_TARGETS)
# OS                    - one of $(SUPPORTED_OSES),
# CPU or UCPU,KCPU,TCPU - one of $(SUPPORTED_CPUS),

# what target type to build
# note: do not take TARGET value from environment
# note: TARGET may be overridden either in command line or in project configuration makefile
TARGET := RELEASE

# operating system we are building for (and we are building on)
# note: do not take OS value from environment
# note: OS must be overridden either in command line or in project configuration makefile
ifndef OS
OS:=
else ifeq (Windows_NT,$(OS))
OS := WINXX
else
OS:=
endif

# CPU processor architecture we are building for 
# note: do not take CPU value from environment
# note: CPU may be overridden either in command line or in project configuration makefile
CPU := x86

# UCPU - processor architecture for user-level applications
# KCPU - processor architecture for kernel modules
# TCPU - processor architecture for build tools (may be different from $(UCPU) if cross-compiling)
# note: do not take UCPU, KCPU and TCPU values from environment
# note: UCPU, KCPU and TCPU may be overridden either in command line or in project configuration makefile
UCPU := $(CPU)
KCPU := $(CPU)
TCPU := $(UCPU)

# set defaults
# note: these defaults may be overridden either in command line or in project configuration makefile
SUPPORTED_TARGETS := DEBUG RELEASE
SUPPORTED_OSES    := WINXX SOLARIS LINUX
SUPPORTED_CPUS    := x86 x86_64 sparc sparc64 armv5 mips24k ppc

# directory of $(OS)-specific definitions, such as FREEBSD/{tools.mk,c.mk,java.mk} and so on
OSDIR := $(CLEAN_BUILD_DIR)

# CPU variable must not be used in target makefiles
override CPU = $(error please use UCPU, KCPU or TCPU instead)

# fix variables - make them non-recursive (simple)
# note: these variables are used to create simple variables
override TARGET := $(TARGET)
override OS     := $(OS)
override UCPU   := $(UCPU)
override KCPU   := $(KCPU)
override TCPU   := $(TCPU)
override OSDIR  := $(OSDIR)

# OS - operating system we are building for (and we are building on)
ifeq (,$(OS))
$(error OS undefined, please pick one of build OS types: $(SUPPORTED_OSES))
endif

ifeq (,$(filter $(OS),$(SUPPORTED_OSES)))
$(error unknown OS=$(OS), please pick one of build OS types: $(SUPPORTED_OSES))
endif

# check $(CPU) and $(TARGET) only if goal is not distclean
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

# CPU for user-level
ifeq (,$(filter $(UCPU),$(SUPPORTED_CPUS)))
$(error unknown UCPU=$(UCPU), please pick one of target CPU types: $(SUPPORTED_CPUS))
endif

ifdef DRIVERS_SUPPORT
# CPU for kernel-level
ifeq (,$(filter $(KCPU),$(SUPPORTED_CPUS)))
$(error unknown KCPU=$(KCPU), please pick one of target CPU types: $(SUPPORTED_CPUS))
endif
endif

# CPU for build-tools
ifeq (,$(filter $(TCPU),$(SUPPORTED_CPUS)))
$(error unknown TCPU=$(TCPU), please pick one of build CPU types: $(SUPPORTED_CPUS))
endif

# what to build
ifeq (,$(filter $(TARGET),$(SUPPORTED_TARGETS)))
$(error unknown TARGET=$(TARGET), please pick one of: $(SUPPORTED_TARGETS))
endif

else # distclean

ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error distclean goal must be specified alone, current goals: $(MAKECMDGOALS))
endif

# define distclean target by default
NO_CLEAN_BUILD_DISTCLEAN_TARGET:=

ifndef NO_CLEAN_BUILD_DISTCLEAN_TARGET

# define distclean target
# note: RM macro must be defined below in $(OSDIR)/$(OS)/tools.mk
distclean:
	$(call RM,$(BUILD))

# fake target - delete all built artifacts, including directories
.PHONY: distclean

endif # !NO_CLEAN_BUILD_DISTCLEAN_TARGET

endif # distclean

# $(DEBUG) is non-empty for DEBUG targets like "PROJECTD" or "DEBUG"
DEBUG := $(filter DEBUG %D,$(TARGET))

# run via $(MAKE) V=1 for verbose output
ifeq ("$(origin V)","command line")
VERBOSE := $(V:0=)
else
# don't print executing commands by default
VERBOSE:=
endif

# @ in non-verbose build
QUIET := $(if $(VERBOSE),,@)

# run via $(MAKE) M=1 to print makefile name the target comes from
ifeq ("$(origin M)","command line")
INFOMF := $(M:0=)
else
# don't print makefile names by default
INFOMF:=
endif

# run via $(MAKE) D=1 to debug makefiles
ifeq ("$(origin D)","command line")
MDEBUG := $(D:0=)
else
# don't debug makefiles by default
MDEBUG:=
endif

ifdef MDEBUG
$(call dump,CLEAN_BUILD_DIR OSDIR BUILD CONFIG_FILE TARGET OS UCPU KCPU TCPU,,)
endif

# get absolute path to current makefile
CURRENT_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))

# list of all processed makefiles names
# note: PROCESSED_MAKEFILES is never cleared, only appended
# note: default target 'all' depends only on $(PROCESSED_MAKEFILES) list
PROCESSED_MAKEFILES:=

ifdef MCHECK

# check that $(CURRENT_MAKEFILE) is not already processed
CHECK_MAKEFILE_NOT_PROCESSED = $(if $(filter \
  $(CURRENT_MAKEFILE)-,$(PROCESSED_MAKEFILES)),$$(error makefile $(CURRENT_MAKEFILE) is already processed!))

else # !MCHECK

# reset
CHECK_MAKEFILE_NOT_PROCESSED:=

endif # MCHECK

# for UNIX: don't change paths when converting from make internal file path to path accepted by $(OS)
# NOTE: WINXX/tools.mk defines own ospath
ospath = $1

# add $1 only to non-absolute paths in $2
# note: $1 must end with /
# NOTE: WINXX/tools.mk defines own nonrelpath
nonrelpath = $(patsubst $1/%,/%,$(addprefix $1,$2))

# suffix of built tool executables
# NOTE: WINXX/tools.mk defines own TOOL_SUFFIX
TOOL_SUFFIX:=

# paths separator char
# NOTE: WINXX/tools.mk defines own PATHSEP
PATHSEP := :

# name of environment variable to modify in $(RUN_WITH_DLL_PATH)
# note: $(DLL_PATH_VAR) should be PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS)
# NOTE: WINXX/tools.mk defines own DLL_PATH_VAR
DLL_PATH_VAR := LD_LIBRARY_PATH

# show modified $(DLL_PATH_VAR) environment variable with running command
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
# NOTE: WINXX/tools.mk defines own show_with_dll_path
show_with_dll_path = $(info $(if $2,$(DLL_PATH_VAR)="$($(DLL_PATH_VAR))" )$(foreach \
  v,$3,$(foreach n,$(firstword $(subst =, ,$v)),$n="$($n)")) $1)

# NOTE: WINXX/tools.mk defines own show_dll_path_end
show_dll_path_end:=

# tools colors
GEN_COLOR   := [01;32m
MGEN_COLOR  := [01;32m
CP_COLOR    := [00;36m
RM_COLOR    := [01;31m
DEL_COLOR   := [01;31m
LN_COLOR    := [00;36m
MKDIR_COLOR := [00;36m
TOUCH_COLOR := [00;36m
CAT_COLOR   := [00;32m

# colorize percents
# NOTE: WINXX/tools.mk redefines: PRINT_PERCENTS = [$1]
PRINT_PERCENTS = [00;34m[[01;34m$1[00;34m][0m

# print in color short name of called tool $1 with argument $2
# $1 - tool
# $2 - argument
# $3 - empty, then colorize argument
# NOTE: WINXX/tools.mk redefines: COLORIZE = $1$(padto)$2
COLORIZE = $($1_COLOR)$1[0m$(padto)$(if $3,$2,$(join $(dir $2),$(addsuffix [0m,$(addprefix $($1_COLOR),$(notdir $2)))))

# SUP: suppress output of executed build tool, print some pretty message instead, like "CC  source.c"
# target-specific: MF, MCONT
# $1 - tool
# $2 - tool arguments
# $3 - if empty, then colorize argument of called tool
# $4 - if empty, then try to update percents of executed makefiles
ifeq (,$(filter distclean clean,$(MAKECMDGOALS)))
ifdef QUIET
SHOWN_MAKEFILES:=
SHOWN_PERCENTS:=
SHOWN_REMAINDER:=
# general formula: percents = current*100/total
# but we need percents value incrementally: 0*100/total, 1*100/total, 2*100/total, ...
# so just remember previous percent value and remainder of prev*100/total:
# 1) current = 0, percents0 = 0, remainder0 = 0
# 2) current = 1, percents1 = int(100/total), remainder1 = rem(100/total)
# 3) current = 2, percents2 = percents1 + int((remainder1 + 100)/total), remainder2 = rem((remainder1 + 100)/total)
# 4) current = 3, percents3 = percents2 + int((remainder2 + 100)/total), remainder3 = rem((remainder2 + 100)/total)
# ...
ADD_SHOWN_PERCENTS = $(eval ADD_SHOWN_PERCENTS=$$(if $$(word $(TARGET_MAKEFILES_COUNT),$$1),+ $$(call \
  ADD_SHOWN_PERCENTS,$$(wordlist $(TARGET_MAKEFILES_COUNT1),999999,$$1)),$$(eval SHOWN_REMAINDER:=$$1)))$(ADD_SHOWN_PERCENTS)
# remember shown makefile $(MF), try to increment total percents count
define REM_SHOWN_MAKEFILE
SHOWN_MAKEFILES += $(MF)
SHOWN_PERCENTS += $(call ADD_SHOWN_PERCENTS,$(SHOWN_REMAINDER) \
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 \
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
endef
# prepare for printing percents of processed makefiles
FORMAT_PERCENTS = $(subst |,,$(subst \
  |0%,00%,$(subst \
  |1%,01%,$(subst \
  |2%,02%,$(subst \
  |3%,03%,$(subst \
  |4%,04%,$(subst \
  |5%,05%,$(subst \
  |6%,06%,$(subst \
  |7%,07%,$(subst \
  |8%,08%,$(subst \
  |9%,09%,$(subst \
  |100%,FIN,|$(words $(SHOWN_PERCENTS))%))))))))))))
# don't update percents if $(MF) was already shown
TRY_REM_MAKEFILE = $(if $(filter $(MF),$(SHOWN_MAKEFILES)),,$(eval $(REM_SHOWN_MAKEFILE)))
ifdef INFOMF
SUP = $(info $(call PRINT_PERCENTS,$(if $4,,$(TRY_REM_MAKEFILE))$(FORMAT_PERCENTS))$(MF)$(MCONT):$(COLORIZE))@
else
SUP = $(info $(call PRINT_PERCENTS,$(if $4,,$(TRY_REM_MAKEFILE))$(FORMAT_PERCENTS))$(COLORIZE))@
endif
# used to remember number of intermediate makefiles which include other makefiles
INTERMEDIATE_MAKEFILES:=
else # !QUIET
REM_SHOWN_MAKEFILE:=
ifdef INFOMF
SUP = $(info $(MF)$(MCONT):)
else
SUP:=
endif
endif # !QUIET
endif # !distclean && !clean

# SED - stream editor executable - should be defined in $(OSDIR)/$(OS)/tools.mk
# helper macro: convert multi-line sed script $1 to multiple sed expressions - one expression for each script line
SED_MULTI_EXPR = $(subst $$(space), ,$(foreach s,$(subst $(newline), ,$(subst $(space),$$(space),$1)),-e $(call SED_EXPR,$s)))

# to allow parallel builds for different combinations
# of $(OS)/$(KCPU)/$(UCPU)/$(TARGET) - create unique directories for each combination
ifdef DRIVERS_SUPPORT
TARGET_TRIPLET := $(OS)-$(KCPU)-$(UCPU)-$(TARGET)
else
TARGET_TRIPLET := $(OS)-$(UCPU)-$(TARGET)
endif

# output directories:
# bin - for executables, dlls, res
# lib - for libraries, shared objects
# obj - for object files
# gen - for generated files (headers, sources, resources, etc)
DEF_BIN_DIR := $(BUILD)/bin-$(TARGET_TRIPLET)
DEF_OBJ_DIR := $(BUILD)/obj-$(TARGET_TRIPLET)
DEF_LIB_DIR := $(BUILD)/lib-$(TARGET_TRIPLET)
DEF_GEN_DIR := $(BUILD)/gen-$(TARGET_TRIPLET)

# restore default dirs after tool mode
define SET_DEFAULT_DIRS
BIN_DIR := $(DEF_BIN_DIR)
OBJ_DIR := $(DEF_OBJ_DIR)
LIB_DIR := $(DEF_LIB_DIR)
GEN_DIR := $(DEF_GEN_DIR)
$(call CLEAN_BUILD_PROTECT_VARS1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endef
SET_DEFAULT_DIRS := $(SET_DEFAULT_DIRS)

# define BIN_DIR/OBJ_DIR/LIB_DIR/GEN_DIR
$(eval $(SET_DEFAULT_DIRS))

# to allow parallel builds for different combinations
# of $(OS)/$(KCPU)/$(UCPU)/$(TARGET) - tool dir must be unique for each such combination
# (this is true for TOOL_BASE = $(DEF_GEN_DIR))
TOOL_BASE := $(DEF_GEN_DIR)

# TOOL_BASE should be non-recursive (simple) - it is used in TOOL_OVERRIDE_DIRS 
override TOOL_BASE := $(TOOL_BASE)

ifeq (,$(filter $(BUILD)/%,$(TOOL_BASE)))
$(error TOOL_BASE=$(TOOL_BASE) is not a subdirectory of BUILD=$(BUILD))
endif

# where tools are built
# $1 - TOOL_BASE
# $2 - TCPU
MK_TOOLS_DIR = $1/bin-TOOL-$2-$(TARGET)

# call with
# $1 - TOOL_BASE
# $2 - TCPU
# $3 - tool name(s) to get paths to the tools executables
GET_TOOLS = $(addsuffix $(TOOL_SUFFIX),$(addprefix $(MK_TOOLS_DIR)/,$3))

# get path to a tool $1 for current $(TOOL_BASE) and $(TCPU)
GET_TOOL = $(call GET_TOOLS,$(TOOL_BASE),$(TCPU),$1)

# override default dirs in tool mode (when TOOL_MODE has non-empty value)
define TOOL_OVERRIDE_DIRS
BIN_DIR := $(TOOL_BASE)/bin-TOOL-$(TCPU)-$(TARGET)
OBJ_DIR := $(TOOL_BASE)/obj-TOOL-$(TCPU)-$(TARGET)
LIB_DIR := $(TOOL_BASE)/lib-TOOL-$(TCPU)-$(TARGET)
GEN_DIR := $(TOOL_BASE)/gen-TOOL-$(TCPU)-$(TARGET)
$(call CLEAN_BUILD_PROTECT_VARS1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endef
TOOL_OVERRIDE_DIRS := $(TOOL_OVERRIDE_DIRS)

# CLEAN - files/directories list to delete on $(MAKE) clean
# note: CLEAN is never cleared, only appended
CLEAN:=

# TOCLEAN - function to add values to CLEAN variable
# - don't add values to CLEAN variable if not cleaning up
ifeq (,$(filter clean,$(MAKECMDGOALS)))
TOCLEAN:=
else ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error clean goal must be specified alone, current goals: $(MAKECMDGOALS))
else
TOCLEAN = $(eval CLEAN+=$1)
endif

# order-only makefiles dependencies (absolute paths) to add to all leaf prerequisites for the targets
# NOTE: $(FIX_ORDER_DEPS) may change $(ORDER_DEPS) list by appending $(MDEPS)
ORDER_DEPS:=

# code for adding $(MDEPS) - list of makefiles that need to be maked before target makefile to $(ORDER_DEPS),
# overwritten in $(CLEAN_BUILD_DIR)/parallel.mk
FIX_ORDER_DEPS:=

ifdef TOCLEAN

# just cleanup target file(s) $1 (absolute paths)
$(eval STD_TARGET_VARS = $(value TOCLEAN))

else # !clean

# standard target-specific variables
# $1     - target file(s) to build (absolute paths)
# $2     - directories of target file(s) (absolute paths)
# $(TMD) - T if target is built in TOOL_MODE
# NOTE: postpone expansion of ORDER_DEPS - $(FIX_ORDER_DEPS) changes $(ORDER_DEPS) value
define STD_TARGET_VARS1
$(FIX_ORDER_DEPS)
$1:TMD:=$(CB_TOOL_MODE)
$1:| $2 $$(ORDER_DEPS)
$(CURRENT_MAKEFILE)-:$1
NEEDED_DIRS+=$2
endef

# standard target-specific variables
# $1 - generated file(s) (absolute paths)
STD_TARGET_VARS = $(call STD_TARGET_VARS1,$1,$(patsubst %/,%,$(sort $(dir $1))))

endif # !clean

# for given target $1
# define target-specific variables for printing makefile info
# $(MF)    - makefile which specifies how to build the target
# $(MCONT) - number of section in makefile after a call of $(MAKE_CONTINUE)
# NOTE: $(MAKE_CONT) list is empty or 1 1 1 .. 1 2 (inside MAKE_CONTINUE) or 1 1 1 1... (before MAKE_CONTINUE)
# NOTE: MCONT will be either empty or 2,3,4... - MCONT cannot be 1 - some rules may be defined before calling $(MAKE_CONTINUE)
ifdef INFOMF
define MAKEFILE_INFO_TEMPL
$1:MF:=$(CURRENT_MAKEFILE)
$1:MCONT:=$(subst +0,,+$(words $(subst 2,,$(MAKE_CONT))))
endef
SET_MAKEFILE_INFO = $(eval $(MAKEFILE_INFO_TEMPL))
else ifdef QUIET
# remember $(CURRENT_MAKEFILE) to properly update percents
MAKEFILE_INFO_TEMPL = $1:MF:=$(CURRENT_MAKEFILE)
SET_MAKEFILE_INFO = $(eval $(MAKEFILE_INFO_TEMPL))
else
SET_MAKEFILE_INFO:=
endif

# define target-specific variables MF and MCONT for the target(s) $1
ifndef TOCLEAN
ifdef SET_MAKEFILE_INFO
$(eval define STD_TARGET_VARS1$(newline)$(value MAKEFILE_INFO_TEMPL)$(newline)$(value STD_TARGET_VARS1)$(newline)endef)
endif
endif

# add absolute path to directory of currently processing makefile to non-absolute paths
# - we need absolute paths to sources to work with generated dependencies in .d files
fixpath = $(abspath $(call nonrelpath,$(dir $(CURRENT_MAKEFILE)),$1))

ifdef MDEBUG

# info about which makefile is expanded now and order dependencies for it
MAKEFILE_DEBUG_INFO = $(subst $(space),,$(CB_INCLUDE_LEVEL))$(CURRENT_MAKEFILE)$(if $(ORDER_DEPS), | $(ORDER_DEPS:-=))

# note: show debug info only if $1 does not contain @ (used by $(CLEAN_BUILD_DIR)/parallel.mk)
DEF_TAIL_CODE_DEBUG = $(if $(filter @,$1),,$$(info $(MAKEFILE_DEBUG_INFO)))

else # !MDEBUG

# reset
MAKEFILE_DEBUG_INFO:=
DEF_TAIL_CODE_DEBUG:=

endif # !MDEBUG

# get target variants list or default variant R
# $1 - EXE,LIB,...
# $2 - variants list (may be empty)
# $3 - variants filter function (VARIANTS_FILTER by default), must be defined at time of $(eval)
# NOTE: add R to filter pattern to not filter-out default variant R
# NOTE: if filter gives no variants, return default variant R (regular)
FILTER_VARIANTS_LIST = $(patsubst ,R,$(filter R $($(firstword $3 VARIANTS_FILTER)),$2))

# get target variants list or default variant R
# $1 - EXE,LIB,...
# $2 - variants filter function (VARIANTS_FILTER by default), must be defined at time of $(eval)
GET_VARIANTS = $(call FILTER_VARIANTS_LIST,$1,$(wordlist 2,999999,$($1)),$2)

# get target name - first word, next words - variants
# Note: target file name (generated by FORM_TRG) may be different, depending on target variant
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

ifdef MDEBUG

# code to print makefile targets, used by $(CLEAN_BUILD_DIR)/c.mk and may be in other places in the future
# $1 - targets to build (EXE,LIB,DLL,...)
# $2 - function to form target file name (FORM_TRG), must be defined at time of $(eval)
# $3 - variants filter function (VARIANTS_FILTER by default), must be defined at time of $(eval)
DEBUG_TARGETS = $(foreach t,$1,$(if $($t),$(newline)$(foreach \
  v,$(call GET_VARIANTS,$t,$3),$(info $(if $(CB_TOOL_MODE),[TOOL]: )$t $(subst \
  R ,,$v )= $(call GET_TARGET_NAME,$t) '$(patsubst $(BUILD)/%,%,$(call $2,$t,$v))'))))

else # !MDEBUG

# reset
DEBUG_TARGETS:=

endif # !MDEBUG

# form name of target objects directory
# $1 - target to build (EXE,LIB,DLL,...)
# $2 - target variant (may be empty for default variant)
# add target-specific suffix (_EXE,_LIB,_DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)_$1

# add generated files $1 to build sequence
# note: files must be generated in $(GEN_DIR),$(BIN_DIR),$(OBJ_DIR) or $(LIB_DIR)
# note: directories for generated files will be auto-created
ADD_GENERATED = $(eval $(STD_TARGET_VARS))

ifdef MCHECK

# check that files $1 are generated in $(GEN_DIR), $(BIN_DIR), $(OBJ_DIR) or $(LIB_DIR)
CHECK_GENERATED = $(if $(filter-out $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1),$(error \
  some files are generated not under $$(GEN_DIR), $$(BIN_DIR), $$(OBJ_DIR) or $$(LIB_DIR): $(filter-out \
  $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1)))

$(eval ADD_GENERATED = $$(CHECK_GENERATED)$(value ADD_GENERATED))

endif # MCHECK

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
# $4 - $(words $(MULTI_TARGET_NUM))
define MULTI_TARGET_RULE
$(STD_TARGET_VARS)
$1: $(call fixpath,$2)
	$$(if $$(filter $4,$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS += $4)$$(call SUP,MGEN,$1)$3)
MULTI_TARGET_NUM+=1
endef

# make chain of dependencies of multi-targets on each other: 1 2 3 4 -> 2:| 1; 3:| 2; 4:| 3;
# $1 - list of generated files (absolute paths without spaces)
MULTI_TARGET_SEQ = $(subst ||,| ,$(subst $(space),$(newline),$(filter-out \
  --%,$(join $(addsuffix :||,$(wordlist 2,999999,$1) --),$1))))$(newline)

# if some tool generates multiple files at one call, it is needed to call
#  the tool only once if any of generated files needs to be updated
# $1 - list of generated files (absolute paths)
# $2 - prerequisites
# $3 - rule
# note: directories for generated files will be auto-created
# note: rule must update all targets
MULTI_TARGET = $(eval $(MULTI_TARGET_SEQ)$(call MULTI_TARGET_RULE,$1,$2,$3,$(words $(MULTI_TARGET_NUM))))

ifdef MCHECK

# must not use $@ in multi-target rule because it may have different values (any target from multi-targets list)
# must not use $| in multi-target rule because it may have different values (some targets from multi-targets list)
# $1 - list of generated files (absolute paths)
# $3 - rule
CHECK_MULTI_RULE = $(CHECK_GENERATED)$(if \
  $(findstring $$@,$3),$(warning please do not use $$@ in multi-target rule:$(newline)$3))$(if \
  $(findstring $$|,$3),$(warning please do not use $$| in multi-target rule:$(newline)$3))

$(eval MULTI_TARGET = $$(CHECK_MULTI_RULE)$(value MULTI_TARGET))

endif # MCHECK

# helper macro: make SDEPS list
# example: $(call FORM_SDEPS,src1 src2,dep1 dep2 dep3) -> src1|dep1|dep2|dep3 src2|dep1|dep2|dep3
FORM_SDEPS = $(addsuffix |$(call join_with,$2,|),$1)

# get dependencies for source files
# $1 - source files
# $2 - sdeps list: <source file1>|<dependency1>|<dependency2>|... <source file2>|<dependency1>|<dependency2>|...
EXTRACT_SDEPS = $(foreach d,$(filter $(addsuffix |%,$1),$2),$(wordlist 2,999999,$(subst |, ,$d)))

# fix sdeps paths: add absolute path to directory of currently processing makefile to non-absolute paths
# $1 - sdeps list: <source file1>|<dependency1>|<dependency2>|... <source file2>|<dependency1>|<dependency2>|...
FIX_SDEPS = $(subst | ,|,$(call fixpath,$(subst |,| ,$1)))

# run executable with modified $(DLL_PATH_VAR) environment variable
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
# note: this function should be used for rule body, where automatic variable $@ is defined
# note: WINXX/tools.mk defines own show_dll_path_end
RUN_WITH_DLL_PATH = $(if $2$3,$(if $2,$(eval $@:$(DLL_PATH_VAR):=$(addsuffix $(PATHSEP),$($(DLL_PATH_VAR)))$2))$(foreach \
  v,$3,$(foreach g,$(firstword $(subst =, ,$v)),$(eval $@:$g:=$(patsubst $g=%,%,$v))))$(if $(VERBOSE),$(show_with_dll_path)@))$1$(if \
  $2$3,$(if $(VERBOSE),$(show_dll_path_end)))

# reset
CB_TOOL_MODE:=

# TOOL_MODE should be specified in target makefile before including this file
# reset TOOL_MODE if it's not set in target makefile
ifneq (file,$(origin TOOL_MODE))
TOOL_MODE:=
endif

# used to remember makefiles include level
CB_INCLUDE_LEVEL:=

# expand this macro to evaluate default head code (called from $(CLEAN_BUILD_DIR)/defs.mk)
# note: by default it expanded at start of next $(MAKE_CONTINUE) round
DEF_HEAD_CODE_EVAL = $(eval $(DEF_HEAD_CODE))

# expand this macro to evaluate default tail code
DEF_TAIL_CODE_EVAL = $(eval $(call DEF_TAIL_CODE,))

# code to $(eval) at beginning of each makefile
# 1) add $(CURRENT_MAKEFILE) to build
# 2) change bin,lib,obj,gen dirs in TOOL_MODE or restore them to default values in non-TOOL_MODE
# 3) reset DEFINE_TARGETS_EVAL_NAME to DEF_TAIL_CODE_EVAL - so $(DEFINE_TARGETS) will eval $(DEF_TAIL_CODE) by default
# NOTE:
#  $(MAKE_CONTINUE) before expanding $(DEF_HEAD_CODE) adds 2 to $(MAKE_CONT) list (which is normally empty or contains 1 1...)
#  - so we know if $(DEF_HEAD_CODE) was expanded from $(MAKE_CONTINUE) - remove 2 from $(MAKE_CONT) in this case
#  - if $(DEF_HEAD_CODE) was expanded not from $(MAKE_CONTINUE) - no 2 in $(MAKE_CONT) - reset $(MAKE_CONT)
# NOTE: set CB_TOOL_MODE to remember if we are in tool mode - TOOL_MODE variable may be changed before calling $(MAKE_CONTINUE)
# NOTE: append $(empty) at end of $(DEF_HEAD_CODE) - to allow to join it and eval: $(eval $(DEF_HEAD_CODE)$(MY_PREPARE_CODE))
define DEF_HEAD_CODE
$(if $(findstring 2,$(MAKE_CONT)),MAKE_CONT:=$(subst 2,1,$(MAKE_CONT)),MAKE_CONT:=\
  $(newline)$(CHECK_MAKEFILE_NOT_PROCESSED)\
  $(newline)PROCESSED_MAKEFILES+=$(CURRENT_MAKEFILE)-)
CB_TOOL_MODE:=$(if $(TOOL_MODE),T)
$(if $(TOOL_MODE),$(if $(CB_TOOL_MODE),,$(TOOL_OVERRIDE_DIRS)),$(if $(CB_TOOL_MODE),$(SET_DEFAULT_DIRS)))
DEFINE_TARGETS_EVAL_NAME:=DEF_TAIL_CODE_EVAL
$(empty)
endef

# prepend DEF_HEAD_CODE with $(CLEAN_BUILD_CHECK_AT_HEAD), if it's defined in $(CLEAN_BUILD_DIR)/protection.mk
ifdef CLEAN_BUILD_CHECK_AT_HEAD
$(eval define DEF_HEAD_CODE$(newline)$$(CLEAN_BUILD_CHECK_AT_HEAD)$(newline)$(value DEF_HEAD_CODE)$(newline)endef)
endif

# code to $(eval) at end of each makefile
# include $(CLEAN_BUILD_DIR)/all.mk only if $(CB_INCLUDE_LEVEL) is empty and will not call $(MAKE_CONTINUE)
# if called from $(MAKE_CONTINUE), $1 - list of vars to save (may be empty)
# note: $(MAKE_CONTINUE) before expanding $(DEF_TAIL_CODE) adds 2 to $(MAKE_CONT) list
# note: $(CLEAN_BUILD_DIR)/parallel.mk executes $(eval $(call DEF_TAIL_CODE,@)) to not show debug info second time in $(DEF_TAIL_CODE_DEBUG)
define DEF_TAIL_CODE
$(if $(CB_INCLUDE_LEVEL)$(findstring 2,$(MAKE_CONT)),,include $(CLEAN_BUILD_DIR)/all.mk)
endef

# prepend DEF_TAIL_CODE with $(DEF_TAIL_CODE_DEBUG), if it's defined above
ifdef DEF_TAIL_CODE_DEBUG
$(eval define DEF_TAIL_CODE$(newline)$$(DEF_TAIL_CODE_DEBUG)$(newline)$(value DEF_TAIL_CODE)$(newline)endef)
endif

# prepend DEF_TAIL_CODE with $(CLEAN_BUILD_CHECK_AT_TAIL), if it's defined in $(CLEAN_BUILD_DIR)/protection.mk
ifdef CLEAN_BUILD_CHECK_AT_TAIL
$(eval define DEF_TAIL_CODE$(newline)$$(CLEAN_BUILD_CHECK_AT_TAIL)$(newline)$(value DEF_TAIL_CODE)$(newline)endef)
endif

# define targets at end of makefile
# evaluate code in $($(DEFINE_TARGETS_EVAL_NAME)) only once, then reset DEFINE_TARGETS_EVAL_NAME
# note: surround $($(DEFINE_TARGETS_EVAL_NAME)) with fake $(if ...) to suppress any text output
# - $(DEFINE_TARGETS) must not expand to any text - to allow calling it via just $(DEFINE_TARGETS) in target makefile
DEFINE_TARGETS = $(if $($(DEFINE_TARGETS_EVAL_NAME)),)

# may be used to save vars before $(MAKE_CONTINUE) and restore after
SAVE_VARS = $(eval $(foreach v,$1,$v_=$(if $(filter simple,$(flavor $v)),:=$(subst $$,$$$$,$(value $v)),=$(value $v))$(newline)))
RESTORE_VARS = $(eval $(foreach v,$1,$v$(value $v_)$(newline)))

# $(MAKE_CONTINUE_EVAL_NAME) - contains name of macro that when expanded
# evaluates code to prepare to define more targets (at least, by evaluating $(DEF_HEAD_CODE))
MAKE_CONTINUE_EVAL_NAME := DEF_HEAD_CODE_EVAL

# reset
MAKE_CONT:=

# reset MAKE_CONTINUE_EVAL_NAME to DEF_HEAD_CODE_EVAL and evaluate code in $1
MAKE_CONTINUE_BODY_EVAL = $(eval MAKE_CONTINUE_EVAL_NAME:=DEF_HEAD_CODE_EVAL)$($1)

# how to join two or more makefiles in one makefile:
# include $(CLEAN_BUILD_DIR)/c.mk
# LIB = xxx1
# SRC = xxx.c
# $(MAKE_CONTINUE)
# LIB = xxx2
# SRC = xxx.c
# ...
# $(DEFINE_TARGETS)

# increment MAKE_CONT, evaluate tail code with $(DEFINE_TARGETS)
# and start next circle - simulate including of appropriate $(CLEAN_BUILD_DIR)/c.mk or $(CLEAN_BUILD_DIR)/java.mk
# by evaluating head-code $($(MAKE_CONTINUE_EVAL_NAME)) - which must be
# initially set in $(CLEAN_BUILD_DIR)/c.mk or $(CLEAN_BUILD_DIR)/java.mk
# NOTE: evaluated code in $($(MAKE_CONTINUE_EVAL_NAME)) must re-define MAKE_CONTINUE_EVAL_NAME,
# because $(MAKE_CONTINUE) resets it to DEF_HEAD_CODE_EVAL
# NOTE: TOOL_MODE value may be changed in target makefile before $(MAKE_CONTINUE)
# note: surround $(MAKE_CONTINUE) with fake $(if...) to suppress any text output
# - to be able to call it with just $(MAKE_CONTINUE) in target makefile
MAKE_CONTINUE = $(if $(if $1,$(SAVE_VARS))$(eval MAKE_CONT+=2)$(DEFINE_TARGETS)$(call \
  MAKE_CONTINUE_BODY_EVAL,$(MAKE_CONTINUE_EVAL_NAME))$(if $1,$(RESTORE_VARS)),)

# check that $(OSDIR)/$(OS)/tools.mk exists
ifeq (,$(wildcard $(OSDIR)/$(OS)/tools.mk))
$(error file $(OSDIR)/$(OS)/tools.mk does not exists)
endif

# define utilities of the OS we are building on
# define OSTYPE variable
include $(OSDIR)/$(OS)/tools.mk

# if $(CONFIG_FILE) was included, show it
ifndef VERBOSE
ifneq (,$(filter $(CONFIG_FILE),$(abspath $(MAKEFILE_LIST))))
CONF_COLOR := [01;32m
$(info $(call PRINT_PERCENTS,use)$(call COLORIZE,CONF,$(CONFIG_FILE)))
endif
endif

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,MAKEFLAGS CLEAN_BUILD_VERSION CLEAN_BUILD_DIR CLEAN_BUILD_REQUIRED_VERSION \
  BUILD DRIVERS_SUPPORT DEBUG NO_CLEAN_BUILD_DISTCLEAN_TARGET \
  SUPPORTED_OSES SUPPORTED_CPUS SUPPORTED_TARGETS OS CPU UCPU KCPU TCPU TARGET \
  OSTYPE VERBOSE QUIET INFOMF MDEBUG OSDIR CHECK_MAKEFILE_NOT_PROCESSED \
  PRINT_PERCENTS SUP ADD_SHOWN_PERCENTS REM_SHOWN_MAKEFILE FORMAT_PERCENTS \
  GEN_COLOR MGEN_COLOR CP_COLOR RM_COLOR DEL_COLOR LN_COLOR MKDIR_COLOR TOUCH_COLOR \
  COLORIZE TRY_REM_MAKEFILE SED_MULTI_EXPR ospath nonrelpath TOOL_SUFFIX PATHSEP \
  TARGET_TRIPLET DEF_BIN_DIR DEF_OBJ_DIR DEF_LIB_DIR DEF_GEN_DIR SET_DEFAULT_DIRS \
  TOOL_BASE MK_TOOLS_DIR GET_TOOLS GET_TOOL TOOL_OVERRIDE_DIRS FIX_ORDER_DEPS \
  STD_TARGET_VARS1 STD_TARGET_VARS MAKEFILE_INFO_TEMPL SET_MAKEFILE_INFO TOCLEAN fixpath MAKEFILE_DEBUG_INFO \
  DEF_TAIL_CODE_DEBUG DEF_HEAD_CODE DEF_HEAD_CODE_EVAL DEF_TAIL_CODE DEF_TAIL_CODE_EVAL \
  FILTER_VARIANTS_LIST GET_VARIANTS GET_TARGET_NAME DEBUG_TARGETS FORM_OBJ_DIR \
  CHECK_GENERATED ADD_GENERATED MULTI_TARGET_RULE CHECK_MULTI_RULE MULTI_TARGET_SEQ MULTI_TARGET \
  DEFINE_TARGETS SAVE_VARS RESTORE_VARS MAKE_CONTINUE_BODY_EVAL MAKE_CONTINUE FORM_SDEPS EXTRACT_SDEPS FIX_SDEPS \
  DLL_PATH_VAR show_with_dll_path show_dll_path_end RUN_WITH_DLL_PATH CONF_COLOR)
