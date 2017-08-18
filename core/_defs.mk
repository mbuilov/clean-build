#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules and definitions for building targets

ifeq (,$(MAKE_VERSION))
$(error MAKE_VERSION is not defined, ensure you are using GNU Make of version 3.81 or later)
endif

ifneq (3.80,$(word 1,$(sort $(MAKE_VERSION) 3.80)))
$(error GNU Make of version 3.81 or later is required for the build)
endif

# disable builtin rules and variables, warn about use of undefined variables
# NOTE: Gnu Make will consider changed $(MAKEFLAGS) only after all makefiles are parsed,
#  so it will first define builtin rules/variables, then undefine them,
#  also, it will warn about undefined variables only while executing rules
# - it's better to specify these flags in command line, e.g.:
# $ make -rR --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables

# assume project makefile, which have included this makefile, defines some variables
# - save list of those variables to override them below, after including needed definitions
PROJECT_VARS_NAMES := $(filter-out \
  MAKEFLAGS CURDIR MAKEFILE_LIST .DEFAULT_GOAL,$(foreach \
  v,$(.VARIABLES),$(if $(findstring file,$(origin $v)),$v)))

# For consistent builds, build results should not depend on environment,
#  only on settings specified in configuration files.
# Environment variables are visible as exported makefile variables,
#  their use is discouraged, so unexport and later reset them.
# Also unexport variables specified in command line.
# Note: do not touch only variables needed for executing shell commands:
#  PATH, SHELL and project-specific variables named in $(PASS_ENV_VARS).
unexport $(filter-out PATH SHELL$(if $(filter-out undefined environment,$(origin \
  PASS_ENV_VARS)), $(PASS_ENV_VARS)),$(.VARIABLES))

# Because any variable may be already initialized from environment, in clean-build:
# 1) always initialize variables with default values before using them
# 2) never use ?= operator
# 3) 'ifdef/ifndef' should only be used for previously initialized variables
# 4) reset (together with unprotected variables, in check mode, before including target makefile)
#  all variables passed from environment, except PATH, SHELL and variables named in $(PASS_ENV_VARS).

# clean-build version: major.minor.patch
# note: override value, if it was accidentally set in project makefile
override CLEAN_BUILD_VERSION := 0.9.0

# clean-build root directory (absolute path)
# note: override value, if it was accidentally set in project makefile
override CLEAN_BUILD_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# include functions library
include $(CLEAN_BUILD_DIR)/core/protection.mk
include $(CLEAN_BUILD_DIR)/core/functions.mk

# CLEAN_BUILD_REQUIRED_VERSION - clean-build version required by project makefiles
#  it is normally defined in project configuration makefile like:
# CLEAN_BUILD_REQUIRED_VERSION := 0.3
ifneq (file,$(origin CLEAN_BUILD_REQUIRED_VERSION))
CLEAN_BUILD_REQUIRED_VERSION := 0.0.0
endif

# check required clean-build version
ifeq (,$(call ver_compatible,$(CLEAN_BUILD_VERSION),$(CLEAN_BUILD_REQUIRED_VERSION)))
$(error incompatible clean-build version: $(CLEAN_BUILD_VERSION), project needs: $(CLEAN_BUILD_REQUIRED_VERSION))
endif

# reset Gnu Make internal variable if it's not defined (to avoid use of undefined variable)
ifeq (undefined,$(origin MAKECMDGOALS))
MAKECMDGOALS:=
endif

# drop make's default legacy rules - we'll use custom ones
.SUFFIXES:

# delete target file if failed to execute any of commands to make it
.DELETE_ON_ERROR:

# specify default goal (defined in $(CLEAN_BUILD_DIR)/core/all.mk)
.DEFAULT_GOAL := all

# clean-build always sets default values for variables - to not inherit them from environment
# to override these defaults by ones specified in project configuration makefile, use override directive
$(eval $(foreach v,$(PROJECT_VARS_NAMES),override $(if $(findstring simple,$(flavor \
  $v)),$v:=$$($v),define $v$(newline)$(value $v)$(newline)endef)$(newline)))

# initialize PASS_ENV_VARS - list of variables to export to subprocesses
# note: PASS_ENV_VARS may be set either in project makefile or in command line
PASS_ENV_VARS:=

# needed directories - we will create them in $(CLEAN_BUILD_DIR)/core/all.mk
# note: NEEDED_DIRS is never cleared, only appended
NEEDED_DIRS:=

# save configuration to $(CONFIG) file as result of 'conf' goal
# note: if $(CONFIG) file is generated under $(BUILD) directory,
# (for example, CONFIG may be defined in project makefile as 'CONFIG = $(BUILD)/conf.mk'),
# then it will be deleted together with $(BUILD) directory in clean-build implementation of 'distclean' goal
include $(CLEAN_BUILD_DIR)/core/confsup.mk

# protect from modification macros defined in $(CLEAN_BUILD_DIR)/core/functions.mk
# note: here TARGET_MAKEFILE variable is used temporary, it will be properly defined below
$(TARGET_MAKEFILE)

# protect from modification list of project-specific variables
$(call SET_GLOBAL,$(PROJECT_VARS_NAMES))

# BUILD - directory for built files - must be defined either in command line
#  or in project configuration makefile before including this file, for example:
# BUILD := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))/build
BUILD:=

# ensure that BUILD is non-recursive (simple), also normalize path
override BUILD := $(abspath $(BUILD))

ifndef BUILD
$(error BUILD undefined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(BUILD)))
$(error BUILD=$(BUILD), path to generated files must not contain spaces)
endif

# list of project-supported target types
# note: normally these defaults are overridden in project configuration makefile
SUPPORTED_TARGETS := DEBUG RELEASE

# what target type to build (DEBUG, RELEASE, TESTS, etc.)
# note: normally TARGET get overridden by specifying it in command line
TARGET := RELEASE

# operating system we are building for (LINUX, WINDOWS, SOLARIS, FREEBSD, etc.)
# note: normally OS get overridden by specifying it in command line
ifneq (environment,$(origin OS))
OS := LINUX
else ifeq (Windows_NT,$(OS))
OS := WINDOWS
else
OS:=
endif

# UTILS - flavor of system shell utilities (such as cp, mv, rm, etc.)
# note: normally UTILS get overridden by specifying it in command line
ifeq (LINUX,$(OS))
UTILS := $(CLEAN_BUILD_DIR)/utils/gnu.mk
else ifeq (WINDOWS,$(OS))
UTILS := $(CLEAN_BUILD_DIR)/utils/cmd.mk
else
UTILS := $(CLEAN_BUILD_DIR)/utils/unix.mk
endif

# CPU - processor architecture we are building applications for (x86, sparc64, armv5, mips24k, etc.)
# note: equivalent of '--host' Gnu Autoconf configure script option
# note: CPU specification may also encode format of executable files, e.g. CPU=m68k-coff, it is checked by the C compiler
# note: normally CPU get overridden by specifying it in command line
ifneq (WINDOWS,$(OS))
CPU := x86
else ifneq (AMD64,$(PROCESSOR_ARCHITECTURE))
CPU := x86
else
CPU := x86_64
endif

# TCPU - processor architecture for build tools (may be different from $(CPU) if cross-compiling)
# note: equivalent of '--build' Gnu Autoconf configure script option
# note: TCPU specification may also encode format of executable files, e.g. CPU=m68k-coff, it is checked by the C compiler
# note: normally TCPU get overridden by specifying it in command line
TCPU := $(CPU)

# fix variables - make them non-recursive (simple)
# note: these variables are used to create simple variables
override TARGET := $(TARGET)
override OS     := $(OS)
override CPU    := $(CPU)
override TCPU   := $(TCPU)
override UTILS  := $(UTILS)

# check that needed variables are correctly defined

# UTILS - flavor of system shell utilities
ifndef UTILS
$(error UTILS variable is not defined)
endif

ifeq (,$(wildcard $(UTILS)))
$(error file $(UTILS) was not found, check value of UTILS variable)
endif

# check other variables only if goal is not distclean
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

# what target type to build
ifeq (,$(filter $(TARGET),$(SUPPORTED_TARGETS)))
$(error unknown TARGET=$(TARGET), please pick one of: $(SUPPORTED_TARGETS))
endif

else # distclean

ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error distclean goal must be specified alone, current goals: $(MAKECMDGOALS))
endif

# provide default definition of distclean goal
NO_CLEAN_BUILD_DISTCLEAN_TARGET:=

ifndef NO_CLEAN_BUILD_DISTCLEAN_TARGET

# define distclean goal
# note: RM macro must be defined below in included $(UTILS) file
distclean:
	$(call RM,$(BUILD))

# fake target - delete all built artifacts, including directories
.PHONY: distclean

endif # !NO_CLEAN_BUILD_DISTCLEAN_TARGET

endif # distclean

# to simplify target makefiles, define DEBUG variable:
# $(DEBUG) is non-empty for debugging targets like "PROJECTD" or "DEBUG"
DEBUG := $(filter DEBUG %D,$(TARGET))

# run via $(MAKE) V=1 for commands echoing and verbose output
ifeq (command line,$(origin V))
VERBOSE := $(V:0=)
else
# don't echo executed commands by default
VERBOSE:=
endif

# @ in non-verbose build
QUIET := $(if $(VERBOSE),,@)

# run via $(MAKE) M=1 to print makefile name the target comes from
ifeq (command line,$(origin M))
INFOMF := $(M:0=)
else
# don't print makefile names by default
INFOMF:=
endif

# run via $(MAKE) D=1 to debug makefiles
ifeq (command line,$(origin D))
MDEBUG := $(D:0=)
else
# don't debug makefiles by default
MDEBUG:=
endif

ifdef MDEBUG
$(call dump,CLEAN_BUILD_DIR BUILD CONFIG TARGET OS UTILS CPU TCPU,,)
endif

# absolute path to target makefile
TARGET_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))

# for UNIX: don't change paths when converting from make internal file path to path accepted by $(UTILS)
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own ospath
ospath = $1

# add $1 only to non-absolute paths in $2
# note: $1 must end with /
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own nonrelpath
nonrelpath = $(patsubst $1/%,/%,$(addprefix $1,$2))

# suffix of built tools executables
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own TOOL_SUFFIX
TOOL_SUFFIX:=

# paths separator char
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own PATHSEP
PATHSEP := :

# name of environment variable to modify in $(RUN_WITH_DLL_PATH)
# note: $(DLL_PATH_VAR) should be PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS)
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own DLL_PATH_VAR
DLL_PATH_VAR := LD_LIBRARY_PATH

# show modified $(DLL_PATH_VAR) environment variable with running command
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_with_dll_path
show_with_dll_path = $(info $(if $2,$(DLL_PATH_VAR)="$($(DLL_PATH_VAR))" )$(foreach \
  v,$3,$(foreach n,$(firstword $(subst =, ,$v)),$n="$($n)")) $1)

# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_dll_path_end
show_dll_path_end:=

# SED - stream editor executable - should be defined in $(UTILS) makefile
# SED_EXPR - also should be defined in $(UTILS) makefile
# helper macro: convert multi-line sed script $1 to multiple sed expressions - one expression for each script line
SED_MULTI_EXPR = $(foreach s,$(subst $(newline), ,$(subst $(tab),$$(tab),$(subst $(space),$$(space),$(subst \
  $$,$$$$,$1)))),-e $(call SED_EXPR,$(eval SED_MULTI_EXPR_:=$(subst $(comment),$$(comment),$s))$(SED_MULTI_EXPR_)))

# utilities colors
GEN_COLOR   := [1;32m
MGEN_COLOR  := [1;32m
CP_COLOR    := [1;36m
RM_COLOR    := [1;31m
DEL_COLOR   := [1;31m
LN_COLOR    := [36m
MKDIR_COLOR := [36m
TOUCH_COLOR := [36m
CAT_COLOR   := [32m
SED_COLOR   := [32m

# colorize printed percents
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk redefines: PRINT_PERCENTS = [$1]
PRINT_PERCENTS = [34m[[1;34m$1[34m][m

# print in color short name of called tool $1 with argument $2
# $1 - tool
# $2 - argument
# $3 - if empty, then colorize argument
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk redefines: COLORIZE = $1$(padto)$2
COLORIZE = $($1_COLOR)$1[m$(padto)$(if $3,$2,$(join $(dir $2),$(addsuffix [m,$(addprefix $($1_COLOR),$(notdir $2)))))

# SUP: suppress output of executed build tool, print some pretty message instead, like "CC  source.c"
# target-specific: MF, MCONT
# $1 - tool
# $2 - tool arguments
# $3 - if empty, then colorize argument of called tool
# $4 - if empty, then try to update percents of executed makefiles
# note: ADD_SHOWN_PERCENTS is checked in $(CLEAN_BUILD_DIR)/core/all.mk, so must always be defined
ifeq (,$(filter distclean clean,$(MAKECMDGOALS)))
ifdef QUIET
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
# note: TARGET_MAKEFILES_COUNT and TARGET_MAKEFILES_COUNT1 are defined in $(CLEAN_BUILD_DIR)/core/all.mk
ADD_SHOWN_PERCENTS = $(if $(word $(TARGET_MAKEFILES_COUNT),$1),+ $(call \
  ADD_SHOWN_PERCENTS,$(wordlist $(TARGET_MAKEFILES_COUNT1),999999,$1)),$(eval SHOWN_REMAINDER:=$$1))
# remember new value of SHOWN_REMAINDER
ifdef SET_GLOBAL
$(eval ADD_SHOWN_PERCENTS = $(value ADD_SHOWN_PERCENTS)$$(call SET_GLOBAL,SHOWN_REMAINDER))
endif
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
# don't update percents if $(MF) has been already shown
# else remember makefile $(MF), then try to increment total percents count
define REM_MAKEFILE
$$(MF):=1
SHOWN_PERCENTS += $(call ADD_SHOWN_PERCENTS,$(SHOWN_REMAINDER) \
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 \
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)
endef
# remember new value of SHOWN_PERCENTS, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,REM_MAKEFILE,$(newline)$(call SET_GLOBAL1,SHOWN_PERCENTS,0))
endif
ifdef INFOMF
SUP = $(info $(call PRINT_PERCENTS,$(if $4,,$(if $(findstring undefined,$(origin \
  $(MF))),$(eval $(REM_MAKEFILE))))$(FORMAT_PERCENTS))$(MF)$(MCONT):$(COLORIZE))@
else
SUP = $(info $(call PRINT_PERCENTS,$(if $4,,$(if $(findstring undefined,$(origin \
  $(MF))),$(eval $(REM_MAKEFILE))))$(FORMAT_PERCENTS))$(COLORIZE))@
endif
else # !QUIET
ADD_SHOWN_PERCENTS:=
ifdef INFOMF
SUP = $(info $(MF)$(MCONT):)
else
SUP:=
endif
endif # !QUIET
else  # distclean || clean
ADD_SHOWN_PERCENTS:=
endif # distclean || clean

# base part of created directories of built artifacts, e.g. DEBUG-LINUX-x86
TARGET_TRIPLET := $(TARGET)-$(OS)-$(CPU)

# output directories:
# bin - for executables, dlls
# lib - for libraries, shared objects
# obj - for object files
# gen - for generated files (headers, sources, resources, etc)
DEF_BIN_DIR := $(BUILD)/bin-$(TARGET_TRIPLET)
DEF_OBJ_DIR := $(BUILD)/obj-$(TARGET_TRIPLET)
DEF_LIB_DIR := $(BUILD)/lib-$(TARGET_TRIPLET)
DEF_GEN_DIR := $(BUILD)/gen-$(TARGET_TRIPLET)

# code to eval to restore default directories after tool mode
define SET_DEFAULT_DIRS
BIN_DIR:=$(DEF_BIN_DIR)
OBJ_DIR:=$(DEF_OBJ_DIR)
LIB_DIR:=$(DEF_LIB_DIR)
GEN_DIR:=$(DEF_GEN_DIR)
endef
SET_DEFAULT_DIRS := $(SET_DEFAULT_DIRS)

# remember new values of standard directories
ifdef SET_GLOBAL1
SET_DEFAULT_DIRS := $(SET_DEFAULT_DIRS)$(newline)$(call SET_GLOBAL1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endif

# define BIN_DIR/OBJ_DIR/LIB_DIR/GEN_DIR
$(eval $(SET_DEFAULT_DIRS))

# base directory of build tools
TOOL_BASE := $(BUILD)/tools

# TOOL_BASE should be non-recursive (simple) - it is used in TOOL_OVERRIDE_DIRS
override TOOL_BASE := $(TOOL_BASE)

# ensure $(TOOL_BASE) is under $(BUILD)
ifeq (,$(filter $(BUILD)/%,$(TOOL_BASE)))
$(error TOOL_BASE=$(TOOL_BASE) is not a subdirectory of BUILD=$(BUILD))
endif

# where tools are built
# $1 - $(TOOL_BASE)
# $2 - $(TCPU)
MK_TOOLS_DIR = $1/bin-TOOL-$2-$(TARGET)

# get absolute paths to the tools executables
# $1 - $(TOOL_BASE)
# $2 - $(TCPU)
# $3 - tool name(s)
GET_TOOLS = $(addprefix $(MK_TOOLS_DIR)/,$(addsuffix $(TOOL_SUFFIX),$3))

# get path to a tool $1 for current TOOL_BASE and TCPU
GET_TOOL = $(call GET_TOOLS,$(TOOL_BASE),$(TCPU),$1)

# code to eval to override default directories in tool mode (when TOOL_MODE has non-empty value)
define TOOL_OVERRIDE_DIRS
BIN_DIR:=$(TOOL_BASE)/bin-TOOL-$(TCPU)-$(TARGET)
OBJ_DIR:=$(TOOL_BASE)/obj-TOOL-$(TCPU)-$(TARGET)
LIB_DIR:=$(TOOL_BASE)/lib-TOOL-$(TCPU)-$(TARGET)
GEN_DIR:=$(TOOL_BASE)/gen-TOOL-$(TCPU)-$(TARGET)
endef
TOOL_OVERRIDE_DIRS := $(TOOL_OVERRIDE_DIRS)

# remember new values of standard directories
ifdef SET_GLOBAL1
TOOL_OVERRIDE_DIRS := $(TOOL_OVERRIDE_DIRS)$(newline)$(call SET_GLOBAL1,BIN_DIR OBJ_DIR LIB_DIR GEN_DIR)
endif

# CLEAN - list of files/directories to delete on $(MAKE) clean
# note: CLEAN list is never cleared, only appended via TOCLEAN macro
# note: should not be directly accessed/modified in target makefiles
CLEAN:=

# TOCLEAN - function to add values to CLEAN list
# note: do not add values to CLEAN variable if not cleaning up
ifeq (,$(filter clean,$(MAKECMDGOALS)))
TOCLEAN:=
else ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error clean goal must be specified alone, current goals: $(MAKECMDGOALS))
else ifdef MCHECK
# remember new value of CLEAN, without tracing calls to it because it is incremented
TOCLEAN = $(eval CLEAN+=$$1$(newline)$(call SET_GLOBAL1,CLEAN,0))
else
TOCLEAN = $(eval CLEAN+=$$1)
endif

# append makefiles (really PHONY targets created from them) to ORDER_DEPS list
# note: this function is useful to specify dependency on all target files built by makefiles (a tree of makefiles)
# note: argument - list of makefiles (or directories, where Makefile is searched)
# note: overridden in $(CLEAN_BUILD_DIR)/core/_parallel.mk
ADD_MDEPS:=

# same as ADD_MDEPS, but accepts aliases of makefiles
# note: alias names are created via CREATE_MAKEFILE_ALIAS macro
# note: overridden in $(CLEAN_BUILD_DIR)/core/_parallel.mk
ADD_ADEPS:=

ifndef TOCLEAN

# create a PHONY target aliasing current makefile
# $1 - arbitrary alias name
CREATE_MAKEFILE_ALIAS = $(eval .PHONY: $1_MAKEFILE_ALIAS-$(newline)$1_MAKEFILE_ALIAS-: $(TARGET_MAKEFILE)-)

# order-only dependencies of all leaf makefile targets
# note: ORDER_DEPS should not be directly modified in target makefiles,
#  use ADD_ORDER_DEPS/ADD_MDEPS/ADD_ADEPS to append value(s) to ORDER_DEPS
ORDER_DEPS:=

# append value(s) to ORDER_DEPS list
ifdef MCHECK
# remember new value of ORDER_DEPS, without tracing calls to it because it is incremented
ADD_ORDER_DEPS = $(eval ORDER_DEPS+=$$1$(newline)$(call SET_GLOBAL1,ORDER_DEPS,0))
else
ADD_ORDER_DEPS = $(eval ORDER_DEPS+=$$1)
endif

# define a PHONY target which will depend on main makefile targets (registered via STD_TARGET_VARS macro)
.PHONY: $(TARGET_MAKEFILE)-

# default goal 'all' - depends only on the root makefile
all: $(TARGET_MAKEFILE)-

# register targets as main ones built by current makefile, add standard target-specific variables
# $1     - target file(s) to build (absolute paths)
# $2     - directories of target file(s) (absolute paths)
# $(TMD) - T if target is built in TOOL_MODE
# note: postpone expansion of $(ORDER_DEPS) to optimize parsing
# note: PHONY target $(TARGET_MAKEFILE)- will depend on built files
define STD_TARGET_VARS1
$1:TMD:=$(TMD)
$1:| $2 $$(ORDER_DEPS)
$(TARGET_MAKEFILE)-:$1
NEEDED_DIRS+=$2
endef

# remember new value of NEEDED_DIRS, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,STD_TARGET_VARS1,$(newline)$(call SET_GLOBAL1,NEEDED_DIRS,0))
endif

# print what makefile builds
ifdef MDEBUG
$(call define_append,STD_TARGET_VARS1,$$(info $$(if \
  $$(TMD),[T]: )$$(patsubst $$(BUILD)/%,%,$$1)$$(if $$(ORDER_DEPS), | $$(ORDER_DEPS))))
endif

# register targets as main ones built by current makefile, add standard target-specific variables
# $1 - generated file(s) (absolute paths)
STD_TARGET_VARS = $(call STD_TARGET_VARS1,$1,$(patsubst %/,%,$(sort $(dir $1))))

# SET_MAKEFILE_INFO - for given target $1, define target-specific variables for printing makefile info:
# $(MF)    - makefile which specifies how to build the target
# $(MCONT) - number of section in makefile after a call to $(MAKE_CONTINUE)
# note: $(MAKE_CONT) list is empty or 1 1 1 .. 1 2 (inside MAKE_CONTINUE) or 1 1 1 1... (before MAKE_CONTINUE):
# MAKE_CONTINUE is equivalent of: ... MAKE_CONT+=2 $(TAIL) MAKE_CONT=$(subst 2,1,$(MAKE_CONT)) $(HEAD) ...
ifdef INFOMF
define MAKEFILE_INFO_TEMPL
$1:MF:=$(TARGET_MAKEFILE)
$1:MCONT:=$(subst +0,,+$(words $(subst 2,,$(MAKE_CONT))))
endef
SET_MAKEFILE_INFO = $(eval $(MAKEFILE_INFO_TEMPL))
else ifdef QUIET
# remember $(TARGET_MAKEFILE) to properly update percents
MAKEFILE_INFO_TEMPL = $1:MF:=$(TARGET_MAKEFILE)
SET_MAKEFILE_INFO = $(eval $(MAKEFILE_INFO_TEMPL))
else # verbose
SET_MAKEFILE_INFO:=
endif

# define target-specific variables MF and MCONT for the target(s) $1
ifdef SET_MAKEFILE_INFO
$(call define_prepend,STD_TARGET_VARS1,$(value MAKEFILE_INFO_TEMPL)$(newline))
endif

else # clean

# just cleanup target file(s) $1 (absolute paths)
$(eval STD_TARGET_VARS = $(value TOCLEAN))

# do nothing
CREATE_MAKEFILE_ALIAS:=
ADD_ORDER_DEPS:=
SET_MAKEFILE_INFO:=

endif # clean

# add absolute path to directory of target makefile to given non-absolute paths
# - we need absolute paths to sources to work with generated dependencies in .d files
fixpath = $(abspath $(call nonrelpath,$(dir $(TARGET_MAKEFILE)),$1))

# get target name - first word, next words - variants (e.g. LIB := my_lib R P D S)
# note: target file name (generated by FORM_TRG) may be different, depending on target variant
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# function returning list of supported by selected toolchain non-regular variants of given target type
# $1 - target type: LIB,EXE,DLL,...
# example:
#  EXE_NON_REGULAR_VARIANTS := P
#  LIB_NON_REGULAR_VARIANTS := P D
#  ...
NON_REGULAR_VARIANTS = $($1_NON_REGULAR_VARIANTS)

# filter-out unsupported variants of the target and return only supported ones (at least R)
# $1 - target: EXE,LIB,...
# $2 - list of specified variants of the target (may be empty)
# $3 - optional name of function which returns list of supported by selected toolchain non-regular variants of given target type
#  (NON_REGULAR_VARIANTS by default), function must be defined at time of $(eval)
# note: add R to filter pattern to not filter-out default variant R, if it was specified for the target
# note: if $(filter ...) gives no variants, return default variant R (regular), which is always supported
FILTER_VARIANTS_LIST = $(patsubst ,R,$(filter R $($(firstword $3 NON_REGULAR_VARIANTS)),$2))

# if target may be specified with variants, like LIB := my_lib R S
#  then get variants of the target supported by selected toolchain
# note: returns non-empty variants list, containing at least R (regular) variant
# $1 - target: EXE,LIB,...
# $2 - optional name of function which returns list of supported by selected toolchain non-regular variants of given target type
#  (NON_REGULAR_VARIANTS by default), function must be defined at time of $(eval)
GET_VARIANTS = $(call FILTER_VARIANTS_LIST,$1,$(wordlist 2,999999,$($1)),$2)

# determine target name suffix (in case if building multiple variants of the target, each variant must have unique file name)
# $1 - target: EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# note: no suffix if building R (regular) variant or variant is not specified (then assume R variant)
# example:
#  LIB_VARIANT_SUFFIX = _$2
#  note: $2 - non-empty, not R
VARIANT_SUFFIX = $(if $(filter-out R,$2),$($1_VARIANT_SUFFIX))

# get absolute path to target file - call appropriate .._FORM_TRG macro
# $1 - EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# example:
#  EXE_FORM_TRG = $(GET_TARGET_NAME:%=$(BIN_DIR)/%$(VARIANT_SUFFIX)$(EXE_SUFFIX))
#  LIB_FORM_TRG = $(GET_TARGET_NAME:%=$(LIB_DIR)/$(LIB_PREFIX)%$(VARIANT_SUFFIX)$(LIB_SUFFIX))
#  ...
#  note: use $(patsubst...) to return empty value if $($1) is empty
FORM_TRG = $($1_FORM_TRG)

# get filenames of all variants of the target
# $1 - EXE,LIB,DLL,...
ALL_TRG = $(foreach v,$(call GET_VARIANTS,$1),$(call FORM_TRG,$1,$v))

# get suffix of dependent library for given variant of the target
# $1 - target: EXE,DLL,...
# $2 - variant of target EXE,DLL,...: R,P,S,... (if empty, assume R)
# $3 - dependency type: LIB,DLL,...
# example:
#  use the same variant (R or P) of static library as target EXE (for example for P-EXE use P-LIB)
#  always use D-variant of static library for DLL
#  LIB_DEPENDENCY_MAP = $(if $(filter DLL,$1),D,$2)
DEPENDENCY_SUFFIX = $(call VARIANT_SUFFIX,$3,$($3_DEPENDENCY_MAP))

# form name of target objects directory
# $1 - target to build (EXE,LIB,DLL,...)
# $2 - target variant (may be empty for regular variant R)
# add target-specific suffix (_EXE,_LIB,_DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)_$1

# add generated files $1 to build sequence
# note: files must be generated in $(GEN_DIR),$(BIN_DIR),$(OBJ_DIR) or $(LIB_DIR)
# note: directories for generated files will be auto-created
ADD_GENERATED = $(eval $(STD_TARGET_VARS))

ifdef MCHECK

# check that files $1 are generated in $(GEN_DIR), $(BIN_DIR), $(OBJ_DIR) or $(LIB_DIR)
CHECK_GENERATED = $(if $(filter-out $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1),$(error \
  these files are generated not under $$(GEN_DIR), $$(BIN_DIR), $$(OBJ_DIR) or $$(LIB_DIR): $(filter-out \
  $(GEN_DIR)/% $(BIN_DIR)/% $(OBJ_DIR)/% $(LIB_DIR)/%,$1)))

$(eval ADD_GENERATED = $$(CHECK_GENERATED)$(value ADD_GENERATED))

endif # MCHECK

# add generated files $1 to build sequence and return $1
# note: files must be generated in $(GEN_DIR),$(BIN_DIR),$(OBJ_DIR) or $(LIB_DIR)
# note: directories for generated files will be auto-created
ADD_GENERATED_RET = $(ADD_GENERATED)$1

# list of processed multi-target rules
# note: MULTI_TARGETS is never cleared, only appended (in rules execution phase)
MULTI_TARGETS:=

# used to count each call of $(MULTI_TARGET)
# note: MULTI_TARGET_NUM is never cleared, only appended (in makefiles parsing phase)
MULTI_TARGET_NUM:=

# when some tool (e.g. bison) generates many files, call the tool only once:
#  assign to each generated multi-target rule an unique number
#  and remember if rule with this number was already executed for one of multi-targets
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# $4 - $(words $(MULTI_TARGET_NUM))
define MULTI_TARGET_RULE
$(STD_TARGET_VARS)
$1: $(call fixpath,$2)
	$$(if $$(filter $4,$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS+=$4)$$(call SUP,MGEN,$1)$3)
MULTI_TARGET_NUM+=1
endef

# remember new value of MULTI_TARGET_NUM, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,MULTI_TARGET_RULE,$(newline)$(call SET_GLOBAL1,MULTI_TARGET_NUM,0))
endif

# if some tool generates multiple files at one call, it is needed to call
#  the tool only once if any of generated files needs to be updated
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# note: directories for generated files will be auto-created
# note: rule must update all targets
MULTI_TARGET = $(eval $(call MULTI_TARGET_RULE,$1,$2,$3,$(words $(MULTI_TARGET_NUM))))

ifdef MCHECK

# must not use $@ in multi-target rule because it may have different values
#  (any target from multi-targets list), and rule must update all targets at once.
# $1 - list of generated files (absolute paths)
# $3 - rule
CHECK_MULTI_RULE = $(CHECK_GENERATED)$(if $(findstring $$@,$(subst \
  $$$$,,$3)),$(error $$@ cannot be used in multi-target rule:$(newline)$3))

$(eval MULTI_TARGET = $$(CHECK_MULTI_RULE)$(value MULTI_TARGET))

endif # MCHECK

# create a chain of order-only dependent targets, so their rules will be executed after each other
# $1 - NON_PARALEL_GROUP_$(group_name)
# $2 - target
define NON_PARALLEL_EXECUTE_RULE
ifneq (undefined,$(origin $1))
$2:| $($1)
endif
$1:=$2
endef

# remember new value of NON_PARALEL_GROUP_$(group_name)
ifdef SET_GLOBAL1
$(call define_append,NON_PARALLEL_EXECUTE_RULE,$(newline)$(call SET_GLOBAL1,$$1))
endif

# create a chain of order-only dependent targets, so their rules will be executed after each other
# for example:
# $(call NON_PARALLEL_EXECUTE,my_group,target1)
# $(call NON_PARALLEL_EXECUTE,my_group,target2)
# $(call NON_PARALLEL_EXECUTE,my_group,target3)
# ...
# $1 - group name
# $2 - target
# note: standard .NOTPARALLEL target, if defined, globally disables parallel execution of all rules,
#  NON_PARALLEL_EXECUTE macro allows to define a group of targets those rules must not be executed in parallel
NON_PARALLEL_EXECUTE = $(eval $(call NON_PARALLEL_EXECUTE_RULE,$1_NON_PARALEL_GROUP,$2))

# helper macro: make source dependencies list
# $1 - sources
# $2 - their dependencies
# example: $(call FORM_SDEPS,s1 s2,d1 d2 d3) -> s1|d1|d2|d3 s2|d1|d2|d3
FORM_SDEPS = $(addsuffix |$(call join_with,$2,|),$1)

# get dependencies for source file(s)
# $1 - source file(s)
# $2 - source dependencies list
# example: $(call EXTRACT_SDEPS,s1 s2,s1|d1|d2|d3 s2|d1|d2|d3) -> d1 d2 d3 d1 d2 d3
EXTRACT_SDEPS = $(foreach d,$(filter $(addsuffix |%,$1),$2),$(wordlist 2,999999,$(subst |, ,$d)))

# fix source dependencies paths: add absolute path to directory of currently processing makefile to non-absolute paths
# $1 - source dependencies list
# example: $(call FIX_SDEPS,s1|d1|d2 s2|d1|d2) -> /pr/s1|/pr/d1|/pr/d2 /pr/s2|/pr/d1|/pr/d2
FIX_SDEPS = $(subst | ,|,$(call fixpath,$(subst |,| ,$1)))

# run executable with modified $(DLL_PATH_VAR) environment variable
# $1 - command to run (with parameters)
# $2 - additional paths to append to $(DLL_PATH_VAR)
# $3 - environment variables to set to run executable, in form VAR=value
# note: this function should be used for rule body, where automatic variable $@ is defined
RUN_WITH_DLL_PATH = $(if $2$3,$(if $2,$(eval \
  $$@:export $(DLL_PATH_VAR):=$(addsuffix $(PATHSEP),$($(DLL_PATH_VAR)))$$2))$(foreach \
  v,$3,$(foreach g,$(firstword $(subst =, ,$v)),$(eval \
  $$@:export $$g:=$(patsubst $g=%,%,$v))))$(if $(VERBOSE),$(show_with_dll_path)@))$1$(if \
  $2$3,$(if $(VERBOSE),$(show_dll_path_end)))

# current value of $(TOOL_MODE)
# reset: $(SET_DEFAULT_DIRS) has already been evaluated
TMD:=

# TOOL_MODE may be set to non-empty value at beginning of target makefile (before including this file)
# reset TOOL_MODE if it's not set in target makefile
ifneq (file,$(origin TOOL_MODE))
TOOL_MODE:=
endif

# variable used to track makefiles include level
CB_INCLUDE_LEVEL:=

# expand this macro to evaluate default head code (called from $(CLEAN_BUILD_DIR)/defs.mk)
# note: by default it is expanded at start of next $(MAKE_CONTINUE) round
DEF_HEAD_CODE_EVAL = $(eval $(DEF_HEAD_CODE))

# expand this macro to evaluate default tail code
# note: arguments list must be empty - only $(CLEAN_BUILD_DIR)/core/_parallel.mk
#  calls DEF_TAIL_CODE with @ for the checks in CLEAN_BUILD_CHECK_AT_TAIL macro
DEF_TAIL_CODE_EVAL = $(eval $(DEF_TAIL_CODE))

# $(MAKE_CONTINUE_EVAL_NAME) - contains name of macro (DEF_HEAD_CODE_EVAL by default),
#  that when expanded, evaluates some code for resetting variables and
#  preparing to define more targets (at least, by evaluating $(DEF_HEAD_CODE)),
# example: MY_PREPARE = $(DEF_HEAD_CODE_EVAL)$(eval $(MY_PREPARE_CODE))
#MAKE_CONTINUE_EVAL_NAME - will be defined while evaluating $(DEF_HEAD_CODE)

# $(DEFINE_TARGETS_EVAL_NAME) - contains name of macro (DEF_TAIL_CODE_EVAL by default),
#  that when expanded, evaluates some code that defines rules for the targets,
# example: MY_DEFINE = $(eval $(MY_RULES_CODE))$(DEF_TAIL_CODE_EVAL)
# check that $(DEF_HEAD_CODE) was evaluated before expanding $(DEFINE_TARGETS)
DEFINE_TARGETS_EVAL_NAME = $(error $$(DEF_HEAD_CODE) was not evaluated at head of makefile!)

# list of all processed target makefiles (absolute paths)
# note: PROCESSED_MAKEFILES is never cleared, only appended (in DEF_HEAD_CODE)
ifneq (,$(MCHECK)$(value ADD_SHOWN_PERCENTS))
PROCESSED_MAKEFILES:=
endif

# ***********************************************
# code to $(eval) at beginning of each makefile
# NOTE: $(MAKE_CONTINUE) before expanding $(DEF_HEAD_CODE) adds 2 to $(MAKE_CONT) list (which is normally empty or contains 1 1...)
#  - so we know if $(DEF_HEAD_CODE) was expanded from $(MAKE_CONTINUE) - remove 2 from $(MAKE_CONT) in that case
#  - if $(DEF_HEAD_CODE) was expanded not from $(MAKE_CONTINUE) - no 2 in $(MAKE_CONT) - reset MAKE_CONT
# NOTE: set TMD to remember if we are in tool mode - TOOL_MODE variable may be changed before calling $(MAKE_CONTINUE)
define DEF_HEAD_CODE
ifneq (,$(findstring 2,$(MAKE_CONT)))
MAKE_CONT:=$$(subst 2,1,$$(MAKE_CONT))
else
MAKE_CONT:=
MAKE_CONTINUE_EVAL_NAME:=DEF_HEAD_CODE_EVAL
DEFINE_TARGETS_EVAL_NAME:=DEF_TAIL_CODE_EVAL
endif
$(if $(TOOL_MODE),$(if \
  $(TMD),,$(TOOL_OVERRIDE_DIRS)$(newline)TMD:=T),$(if \
  $(TMD),$(SET_DEFAULT_DIRS)$(newline)TMD:=))
endef

# show debug info prior defining targets
# note: $(MAKE_CONT) contains 2 if inside $(MAKE_CONTINUE)
ifdef MDEBUG
$(call define_prepend,DEF_HEAD_CODE,$$(info $$(subst \
  $$(space),,$$(CB_INCLUDE_LEVEL))$$(TARGET_MAKEFILE)$$(if $$(findstring 2,$$(MAKE_CONT)),+$$(words $$(MAKE_CONT)))))
endif

# prepend DEF_HEAD_CODE with $(CLEAN_BUILD_CHECK_AT_HEAD), if it is defined in $(CLEAN_BUILD_DIR)/core/protection.mk
ifdef CLEAN_BUILD_CHECK_AT_HEAD
$(call define_prepend,DEF_HEAD_CODE,$$(CLEAN_BUILD_CHECK_AT_HEAD)$(newline))
endif

# remember new value of PROCESSED_MAKEFILES variables, without tracing calls to it because it is incremented
ifdef MCHECK
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  else,else$(newline)$(call SET_GLOBAL1,PROCESSED_MAKEFILES,0),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# add $(TARGET_MAKEFILE) to list of processed target makefiles (note: before first $(MAKE_CONTINUE))
ifneq (,$(MCHECK)$(value ADD_SHOWN_PERCENTS))
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  else,else$(newline)PROCESSED_MAKEFILES+=$$(TARGET_MAKEFILE),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# check that $(TARGET_MAKEFILE) was not already processed (note: before first $(MAKE_CONTINUE))
ifdef MCHECK
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  else,else$(newline)$$$$(if $$$$(filter $$$$(TARGET_MAKEFILE),$$$$(PROCESSED_MAKEFILES),$$$$(error \
  makefile $$$$(TARGET_MAKEFILE) was already processed!))),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# remember new values of TMD, MAKE_CONTINUE_EVAL_NAME and DEFINE_TARGETS_EVAL_NAME
ifdef SET_GLOBAL1
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  TMD:=T,TMD:=T$$(newline)$$(call SET_GLOBAL1,TMD),$(subst \
  TMD:=$(close_brace),TMD:=$(close_brace)$$(newline)$$(call SET_GLOBAL1,TMD),$(subst \
  endif,$(call SET_GLOBAL1,MAKE_CONTINUE_EVAL_NAME DEFINE_TARGETS_EVAL_NAME)$(newline)endif,$(value DEF_HEAD_CODE))))$(newline)endef)
endif

# ***********************************************
# code to $(eval) at end of each makefile
# include $(CLEAN_BUILD_DIR)/core/all.mk only if $(CB_INCLUDE_LEVEL) is empty and not inside the call of $(MAKE_CONTINUE)
# note: $(MAKE_CONTINUE) before expanding $(DEF_TAIL_CODE) adds 2 to $(MAKE_CONT) list
# note: $(CLEAN_BUILD_DIR)/core/_parallel.mk calls DEF_TAIL_CODE with @ as first argument - for the checks in $(CLEAN_BUILD_CHECK_AT_TAIL)
DEF_TAIL_CODE = $(if $(CB_INCLUDE_LEVEL)$(findstring 2,$(MAKE_CONT)),,include $(CLEAN_BUILD_DIR)/core/all.mk)

# prepend DEF_TAIL_CODE with $(CLEAN_BUILD_CHECK_AT_TAIL), if it is defined in $(CLEAN_BUILD_DIR)/core/protection.mk
ifdef CLEAN_BUILD_CHECK_AT_TAIL
$(call define_prepend,DEF_TAIL_CODE,$$(CLEAN_BUILD_CHECK_AT_TAIL)$(newline))
endif

# define targets at end of makefile
# evaluate code $($(DEFINE_TARGETS_EVAL_NAME)) only once, DEF_HEAD_CODE will reset DEFINE_TARGETS_EVAL_NAME
# note: surround $($(DEFINE_TARGETS_EVAL_NAME)) with fake $(if ...) to suppress any text output of $(DEFINE_TARGETS_EVAL_NAME)
# - $(DEFINE_TARGETS) must not expand to any text - to allow calling it via just $(DEFINE_TARGETS) in target makefiles
# note: call $(DEFINE_TARGETS_EVAL_NAME) with empty arguments list - to not pass to any arguments of MAKE_CONTINUE to it
DEFINE_TARGETS = $(if $(call $(DEFINE_TARGETS_EVAL_NAME)),)

# before $(MAKE_CONTINUE): save variables to restore them after (via RESTORE_VARS macro)
SAVE_VARS = $(eval $(foreach v,$1,$(newline)$(if $(findstring \
  simple,$(flavor $v)),$v^saved:=$$($v)$(newline),define $v^saved$(newline)$(value $v)$(newline)endef)))

# after $(MAKE_CONTINUE): restore variables saved before (via SAVE_VARS macro)
RESTORE_VARS = $(eval $(foreach v,$1,$(newline)$(if $(findstring \
  simple,$(flavor $v^saved)),$v:=$$($v^saved)$(newline),define $v$(newline)$(value $v^saved)$(newline)endef)))

# initially reset variable, it is checked in DEF_HEAD_CODE
MAKE_CONT:=

# use $(MAKE_CONTINUE) to define more than one targets in single makefile
# note: all targets are built using the same set of compilers (c, java, python, etc.)
# example:
#
# include $(CLEAN_BUILD_DIR)/c.mk
# LIB = xxx1
# SRC = xxx.c
# $(MAKE_CONTINUE)
# LIB = xxx2
# SRC = xxx.c
# ...
# $(DEFINE_TARGETS)

# MAKE_CONTINUE is equivalent of: ... MAKE_CONT+=2 $(TAIL) MAKE_CONT=$(subst 2,1,$(MAKE_CONT)) $(HEAD) ...
# 1) increment MAKE_CONT
# 2) evaluate tail code with $(DEFINE_TARGETS)
# 3) start next round - simulate including of appropriate $(CLEAN_BUILD_DIR)/c.mk or $(CLEAN_BUILD_DIR)/java.mk or whatever
#  by evaluating head-code $($(MAKE_CONTINUE_EVAL_NAME)) - which must be defined by the first included
#  $(CLEAN_BUILD_DIR)/c.mk or $(CLEAN_BUILD_DIR)/java.mk or whatever
# note: call $(MAKE_CONTINUE_EVAL_NAME) with empty arguments list to not pass any to DEF_HEAD_CODE
# note: surround $(MAKE_CONTINUE) with fake $(if...) to suppress any text output of $(MAKE_CONTINUE_EVAL_NAME)
#  - to be able to call it with just $(MAKE_CONTINUE) in target makefile
MAKE_CONTINUE = $(if $(if $1,$(SAVE_VARS))$(eval MAKE_CONT+=2)$(DEFINE_TARGETS)$(call \
  $(MAKE_CONTINUE_EVAL_NAME))$(if $1,$(RESTORE_VARS)),)

# define shell utilities
include $(UTILS)

# if $(CONFIG) was included, show it
ifndef VERBOSE
ifneq (,$(filter $(CONFIG),$(abspath $(MAKEFILE_LIST))))
CONF_COLOR := [1;32m
$(info $(call PRINT_PERCENTS,use)$(call COLORIZE,CONF,$(CONFIG)))
endif
endif

# product version in form major.minor or major.minor.patch
# note: this is also default version for any built module (exe, dll or driver)
PRODUCT_VER := 0.0.1

# NO_DEPS - if defined, then do not generate auto-dependencies or process previously generated auto-dependencies
# note: do not process dependencies when cleaning up
NO_DEPS := $(filter clean,$(MAKECMDGOALS))

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, passed to environment of called tools or modified via operator +=
$(call SET_GLOBAL,MAKEFLAGS $(PASS_ENV_VARS) PATH SHELL NEEDED_DIRS \
  NO_CLEAN_BUILD_DISTCLEAN_TARGET DEBUG VERBOSE QUIET INFOMF MDEBUG SHOWN_PERCENTS CLEAN \
  ORDER_DEPS MULTI_TARGETS MULTI_TARGET_NUM CB_INCLUDE_LEVEL PROCESSED_MAKEFILES MAKE_CONT NO_DEPS,0)

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,PROJECT_VARS_NAMES PASS_ENV_VARS \
  CLEAN_BUILD_VERSION CLEAN_BUILD_DIR CLEAN_BUILD_REQUIRED_VERSION \
  BUILD SUPPORTED_TARGETS TARGET OS UTILS CPU TCPU TARGET_MAKEFILE \
  ospath nonrelpath TOOL_SUFFIX PATHSEP DLL_PATH_VAR show_with_dll_path show_dll_path_end SED_MULTI_EXPR \
  GEN_COLOR MGEN_COLOR CP_COLOR RM_COLOR DEL_COLOR LN_COLOR MKDIR_COLOR TOUCH_COLOR CAT_COLOR SED_COLOR \
  PRINT_PERCENTS COLORIZE SHOWN_REMAINDER ADD_SHOWN_PERCENTS==SHOWN_REMAINDER \
  FORMAT_PERCENTS=SHOWN_PERCENTS REM_MAKEFILE=SHOWN_PERCENTS=SHOWN_PERCENTS SUP \
  TARGET_TRIPLET DEF_BIN_DIR DEF_OBJ_DIR DEF_LIB_DIR DEF_GEN_DIR SET_DEFAULT_DIRS \
  TOOL_BASE MK_TOOLS_DIR GET_TOOLS GET_TOOL TOOL_OVERRIDE_DIRS \
  ADD_MDEPS ADD_ADEPS CREATE_MAKEFILE_ALIAS ADD_ORDER_DEPS=ORDER_DEPS=ORDER_DEPS \
  STD_TARGET_VARS1 STD_TARGET_VARS MAKEFILE_INFO_TEMPL SET_MAKEFILE_INFO fixpath \
  GET_TARGET_NAME NON_REGULAR_VARIANTS FILTER_VARIANTS_LIST GET_VARIANTS VARIANT_SUFFIX FORM_TRG ALL_TRG DEPENDENCY_SUFFIX \
  FORM_OBJ_DIR ADD_GENERATED CHECK_GENERATED ADD_GENERATED_RET \
  MULTI_TARGET_RULE=MULTI_TARGET_NUM=MULTI_TARGET_NUM MULTI_TARGET CHECK_MULTI_RULE \
  NON_PARALLEL_EXECUTE_RULE NON_PARALLEL_EXECUTE FORM_SDEPS EXTRACT_SDEPS FIX_SDEPS RUN_WITH_DLL_PATH TMD TOOL_MODE \
  DEF_HEAD_CODE_EVAL DEF_TAIL_CODE_EVAL MAKE_CONTINUE_EVAL_NAME DEFINE_TARGETS_EVAL_NAME \
  DEF_HEAD_CODE DEF_TAIL_CODE DEFINE_TARGETS SAVE_VARS RESTORE_VARS MAKE_CONTINUE CONF_COLOR PRODUCT_VER)

# if TOCLEAN value is non-empty, allow tracing calls to it,
# else - just protect TOCLEAN from changes, do not make it's value non-empty - because TOCLEAN is checked in ifdefs
$(call SET_GLOBAL,TOCLEAN,$(if $(value TOCLEAN),,0))
