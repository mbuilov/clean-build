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
#  their use is discouraged, so unexport and later reset them (before including first target makefile).
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

# list of clean-build supported goals
# note: may be updated if necessary in makefiles
CLEAN_BUILD_GOALS := all conf clean distclean check tests

# initialize PASS_ENV_VARS - list of variables to export to subprocesses
# note: PASS_ENV_VARS may be set either in project makefile or in command line
PASS_ENV_VARS:=

# needed directories - we will create them in $(CLEAN_BUILD_DIR)/core/all.mk
# note: CB_NEEDED_DIRS is never cleared, only appended
CB_NEEDED_DIRS:=

# save configuration to $(CONFIG) file as result of 'conf' goal
# note: if $(CONFIG) file is generated under $(BUILD) directory,
# (for example, CONFIG may be defined in project makefile as 'CONFIG = $(BUILD)/conf.mk'),
# then it will be deleted together with $(BUILD) directory in clean-build implementation of 'distclean' goal
include $(CLEAN_BUILD_DIR)/core/confsup.mk

# protect from modification macros defined in $(CLEAN_BUILD_DIR)/core/functions.mk
# note: here TARGET_MAKEFILE variable is used temporary, it will be properly defined below
$(TARGET_MAKEFILE)

# protect from modification project-specific variables
# NOTE: automatically defined SHELL variable will be protected later
$(call SET_GLOBAL,$(filter-out SHELL,$(PROJECT_VARS_NAMES)))

# BUILD - directory for built files - must be defined either in command line
#  or in project configuration makefile before including this file, for example:
# BUILD := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))/build
BUILD:=

# ensure that BUILD is non-recursive (simple), because it is used to create simple variables DEF_BIN_DIR, DEF_LIB_DIR, etc.
# also normalize path and make it absolute
override BUILD := $(abspath $(BUILD))

ifndef BUILD
$(error BUILD - path to built artifacts is not defined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(BUILD)))
$(error BUILD=$(BUILD), path to built artifacts must not contain spaces)
endif

# list of project-supported target types
# note: normally these defaults are overridden in project configuration makefile
SUPPORTED_TARGETS := DEBUG RELEASE

# what target type to build (DEBUG, RELEASE, TESTS, etc.)
# note: normally TARGET get overridden by specifying it in command line
TARGET := RELEASE

# TARGET must be non-recursive (simple), because it is used to create simple variable TARGET_TRIPLET
override TARGET := $(TARGET)

# do not try to determine OS value if it is already defined (in project configuration makefile or in command line)
ifeq (,$(filter-out undefined environment,$(origin OS)))

# operating system we are building for (WIN7, DEBIAN6, SOLARIS10, etc.)
# note: normally OS get overridden by specifying it in command line
# note: OS value may affect default values of other variables (TCPU, UTILS, etc.)
ifneq (,$(filter /cygdrive/%,$(CURDIR)))
OS := CYGWIN
else ifneq (environment,$(origin OS))
OS := $(call toupper,$(shell uname))
else ifeq (Windows_NT,$(OS))
OS := WINDOWS
else
# unknown, should be defined in project configuration makefile or in command line
# note: use of environment variables to configure the build is discouraged
OS:=
endif

# remember autoconfigured OS value
$(call CONFIG_REMEMBER_VARS,OS)

endif # !OS

# OS must be non-recursive (simple), because it is used to create simple variable TARGET_TRIPLET
override OS := $(OS)

# do not try to determine TCPU value if it is already defined (in project configuration makefile or in command line)
ifeq (,$(filter-out undefined environment,$(origin TCPU)))

# TCPU - processor architecture of build helper tools created while the build
# note: TCPU likely is the native processor architecture of the build toolchain
# note: equivalent of '--build' Gnu Autoconf configure script option
# note: TCPU specification may also encode format of executable files, e.g. TCPU=m68k-coff, it is checked by the C compiler
# note: normally TCPU get overridden by specifying it in command line
ifndef OS
TCPU := x86
else ifeq (,$(filter WIN%,$(OS)))
TCPU := $(shell uname -m)
else ifeq (AMD64,$(if $(filter environment,$(origin PROCESSOR_ARCHITECTURE)),$(PROCESSOR_ARCHITECTURE)))
# win64
TCPU := x86_64
else ifeq (AMD64,$(if $(filter environment,$(origin PROCESSOR_ARCHITEW6432)),$(PROCESSOR_ARCHITEW6432)))
# wow64
TCPU := x86_64
else
# win32
TCPU := x86
endif

# remember autoconfigured TCPU value
$(call CONFIG_REMEMBER_VARS,TCPU)

endif # TCPU

# TCPU variable must be non-recursive (simple), because it is used to create simple variable TOOL_OVERRIDE_DIRS
override TCPU := $(TCPU)

# CPU - processor architecture we are building the package for (x86, sparc64, armv5, mips24k, etc.)
# note: equivalent of '--host' Gnu Autoconf configure script option
# note: CPU specification may also encode format of executable files, e.g. CPU=m68k-coff, it is checked by the C compiler
# note: normally CPU get overridden by specifying it in command line
CPU := $(TCPU)

# CPU must be non-recursive (simple), because it is used to create simple variable TARGET_TRIPLET
override CPU := $(CPU)

# UTILS - flavor of system shell utilities (such as cp, mv, rm, etc.)
# note: $(UTILS) value is used only to form name of standard makefile with definitions of shell utilities
# note: normally UTILS get overridden by specifying it in command line, for example: UTILS:=gnu
UTILS := $(if \
  $(filter WIN%,$(OS)),cmd,$(if \
  $(filter LIN%,$(OS)),gnu,unix))

# UTILS_MK - makefile with definitions of shell utilities
UTILS_MK := $(CLEAN_BUILD_DIR)/utils/$(UTILS).mk

ifeq (,$(wildcard $(UTILS_MK)))
$(error file $(UTILS_MK) was not found, check value of UTILS_MK variable)
endif

# check that TARGET is correctly defined only if goal is not distclean
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

# define distclean goal - delete all built artifacts, including directories
# note: DELETE_DIRS macro defined in included below $(UTILS_MK) file
distclean:
	$(QUIET)$(call DELETE_DIRS,$(BUILD))

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
$(call dump,CLEAN_BUILD_DIR BUILD CONFIG TARGET OS TCPU CPU UTILS_MK,,)
endif

# absolute path to target makefile
TARGET_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))

# for UNIX: don't change paths when converting from make internal file path to path accepted by $(UTILS_MK)
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own ospath
ospath = $1

# make path not relative: add $1 only to non-absolute paths in $2
# note: path $1 must end with /
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own nonrelpath
nonrelpath = $(patsubst $1/%,/%,$(addprefix $1,$2))

# suffix of built tools executables
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own TOOL_SUFFIX
TOOL_SUFFIX:=

# paths separator char
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own PATHSEP
PATHSEP := :

# name of environment variable to modify in $(RUN_TOOL)
# note: $(DLL_PATH_VAR) should be PATH (for WINDOWS) or LD_LIBRARY_PATH (for UNIX-like OS)
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own DLL_PATH_VAR value (PATH)
DLL_PATH_VAR := LD_LIBRARY_PATH

# show environment variables set for running a tool in modified environment
# $1 - tool to execute (with parameters)
# $2 - additional path(s) separated by $(PATHSEP) to append to $(DLL_PATH_VAR)
# $3 - directory to change to for executing a tool
# $4 - list of names of variables to set in environment (export) for running an executable
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars/show_tool_vars_end
show_tool_vars1 = $(foreach v,$(if $2,$(DLL_PATH_VAR)) $4,$v=$(call SHELL_ESCAPE,$($v))) $1
show_tool_vars = $(info $(if $3,$(call EXECUTE_IN,$3,$(show_tool_vars1)),$(show_tool_vars1)))

# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars_end
show_tool_vars_end:=

# SED - stream editor executable - should be defined in $(UTILS_MK) makefile
# SED_EXPR - also should be defined in $(UTILS_MK) makefile
# helper macro: convert multi-line sed script $1 to multiple sed expressions - one expression for each script line
SED_MULTI_EXPR = $(foreach s,$(subst $(newline), ,$(unspaces)),-e $(call SED_EXPR,$(call tospaces,$s)))

# utilities colors
GEN_COLOR   := [1;32m
MGEN_COLOR  := [1;32m
CP_COLOR    := [1;36m
RM_COLOR    := [1;31m
RMDIR_COLOR := [1;31m
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
  ADD_SHOWN_PERCENTS,$(wordlist $(TARGET_MAKEFILES_COUNT1),999999,$1)),$(newline)SHOWN_REMAINDER:=$1)
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

# code to eval to restore default directories after "tool mode"
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

# code to eval to override default directories in "tool mode"
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

# append makefiles (really .PHONY goals created from them) to ORDER_DEPS list
# note: this function is useful to specify dependency on all targets built by makefiles (a tree of makefiles)
# note: argument - list of makefiles (or directories, where Makefile is searched)
# note: overridden in $(CLEAN_BUILD_DIR)/core/_parallel.mk
ADD_MDEPS:=

# same as ADD_MDEPS, but accepts aliases of makefiles created via CREATE_MAKEFILE_ALIAS macro
# note: overridden in $(CLEAN_BUILD_DIR)/core/_parallel.mk
ADD_ADEPS:=

# fix template to print what makefile builds
# $1 - template name
# $2 - expression that gives target file(s) the template builds
# $3 - optional expression that gives order-only dependencies
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating expansion result
ADD_WHAT_MAKEFILE_BUILDS:=

ifndef TOCLEAN

# create a .PHONY goal aliasing current makefile
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

# define a .PHONY goal which will depend on main makefile targets (registered via STD_TARGET_VARS macro)
.PHONY: $(TARGET_MAKEFILE)-

# default goal 'all' - depends only on the root makefile
all: $(TARGET_MAKEFILE)-

# add directories $1 to list of auto-created ones
# note: these directories are will be auto-deleted while cleaning up
ifndef MCHECK
NEED_GEN_DIRS = $(eval CB_NEEDED_DIRS+=$$1)
else
# remember new value of CB_NEEDED_DIRS, without tracing calls to it because it is incremented
NEED_GEN_DIRS = $(eval CB_NEEDED_DIRS+=$$1$(newline)$(call SET_GLOBAL1,CB_NEEDED_DIRS,0))
endif

# register targets as main ones built by current makefile, add standard target-specific variables
# $1 - target file(s) to build (absolute paths)
# $2 - directories of target file(s) (absolute paths)
# note: postpone expansion of $(ORDER_DEPS) to optimize parsing
# note: .PHONY goal $(TARGET_MAKEFILE)- will depend on built files
define STD_TARGET_VARS1
$1:| $2 $$(ORDER_DEPS)
$(TARGET_MAKEFILE)-:$1
CB_NEEDED_DIRS+=$2
endef

# remember new value of CB_NEEDED_DIRS, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,STD_TARGET_VARS1,$(newline)$$(call SET_GLOBAL1,CB_NEEDED_DIRS,0))
endif

ifdef MDEBUG

# fix template to print (while evaluating the template) what makefile builds
# $1 - template name
# $2 - expression that gives target file(s) the template builds
# $3 - optional expression that gives order-only dependencies
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating expansion result
ADD_WHAT_MAKEFILE_BUILDS = $(call define_append,$1,$$(info \
  $$(if $$(TMD),[T]: )$$(patsubst $$(BUILD)/%,%,$2)$(if $3,$$(if $3, | $3))))

# print what makefile builds
$(call ADD_WHAT_MAKEFILE_BUILDS,STD_TARGET_VARS1,$$1,$$(ORDER_DEPS))

endif

# register targets as main ones built by current makefile, add standard target-specific variables
# $1 - generated file(s) (absolute paths)
STD_TARGET_VARS = $(call STD_TARGET_VARS1,$1,$(patsubst %/,%,$(sort $(dir $1))))

# MAKEFILE_INFO_TEMPL - for given target(s) $1, define target-specific variables for printing makefile info:
# $(MF)    - makefile which specifies how to build the target
# $(MCONT) - number of section in makefile after a call to $(MAKE_CONTINUE)
# note: $(MAKE_CONT) list is empty or 1 1 1 .. 1 2 (inside MAKE_CONTINUE) or 1 1 1 1... (before MAKE_CONTINUE):
# MAKE_CONTINUE is equivalent of: ... MAKE_CONT+=2 $(TAIL) MAKE_CONT=$(subst 2,1,$(MAKE_CONT)) $(HEAD) ...
ifdef INFOMF
define MAKEFILE_INFO_TEMPL
$1:MF:=$(TARGET_MAKEFILE)
$1:MCONT:=$(subst +0,,+$(words $(subst 2,,$(MAKE_CONT))))
endef
else ifdef QUIET
# remember $(TARGET_MAKEFILE) to properly update percents
MAKEFILE_INFO_TEMPL = $1:MF:=$(TARGET_MAKEFILE)
else # verbose
MAKEFILE_INFO_TEMPL:=
endif

# define target-specific variables MF and MCONT for the target(s) $1
ifdef MAKEFILE_INFO_TEMPL
$(call define_prepend,STD_TARGET_VARS1,$(value MAKEFILE_INFO_TEMPL)$(newline))
endif

else # clean

# just cleanup target files or directories $1 (absolute paths)
ifndef MCHECK
STD_TARGET_VARS = CLEAN+=$1
else
# callers of STD_TARGET_VARS may assume that it will protect new value of CB_NEEDED_DIRS
STD_TARGET_VARS = CLEAN+=$1$(newline)$(call SET_GLOBAL1,CLEAN CB_NEEDED_DIRS,0)
endif

# cleanup generated directories
ifndef MCHECK
NEED_GEN_DIRS = $(eval CLEAN+=$$1)
else
# callers of NEED_GEN_DIRS may assume that it will protect new value of CB_NEEDED_DIRS
NEED_GEN_DIRS = $(eval CLEAN+=$$1$(newline)$$(call SET_GLOBAL1,CLEAN CB_NEEDED_DIRS,0))
endif

# do nothing if cleaning up
CREATE_MAKEFILE_ALIAS:=
ADD_ORDER_DEPS:=
MAKEFILE_INFO_TEMPL:=

endif # clean

# SET_MAKEFILE_INFO - for given target(s) $1, define target-specific variables needed for printing makefile info
ifdef MAKEFILE_INFO_TEMPL
SET_MAKEFILE_INFO = $(eval $(MAKEFILE_INFO_TEMPL))
else
SET_MAKEFILE_INFO:=
endif

# add absolute path to directory of target makefile to given non-absolute paths
# - we need absolute paths to sources to work with generated dependencies in .d files
fixpath = $(abspath $(call nonrelpath,$(dir $(TARGET_MAKEFILE)),$1))

# get target name - first word, next words - variants (e.g. LIB := my_lib R P D S)
# note: target file name (generated by FORM_TRG) may be different, depending on target variant
# $1 - EXE,LIB,...
GET_TARGET_NAME = $(firstword $($1))

# list of supported by selected toolchain non-regular variants of given target type
# $1 - target type: LIB,EXE,DLL,...
# example:
#  EXE_SUPPORTED_VARIANTS := P
#  LIB_SUPPORTED_VARIANTS := P D
#  ...
SUPPORTED_VARIANTS = $($1_SUPPORTED_VARIANTS)

# filter-out unsupported variants of the target and return only supported ones (at least R)
# $1 - target type: EXE,LIB,...
# $2 - list of specified variants of the target (may be empty)
FILTER_VARIANTS_LIST = $(call FILTER_VARIANTS_LIST_F,$1,$2,SUPPORTED_VARIANTS)

# extended version of FILTER_VARIANTS_LIST
# $1 - target type: EXE,LIB,...
# $2 - list of specified variants of the target (may be empty)
# $3 - name of function which returns list of supported by selected toolchain non-regular variants
#  of given target type, function must be defined at time of $(eval)
# note: add R to filter pattern to not filter-out default variant R, if it was specified for the target
# note: if $(filter ...) gives no variants, return default variant R (regular), which is always supported
FILTER_VARIANTS_LIST_F = $(patsubst ,R,$(filter R $($3),$2))

# if target may be specified with variants, like LIB := my_lib R S
#  then get variants of the target supported by selected toolchain
# note: returns non-empty variants list, containing at least R (regular) variant
# $1 - target type: EXE,LIB,...
GET_VARIANTS = $(call GET_VARIANTS_F,$1,SUPPORTED_VARIANTS)

# extended version of GET_VARIANTS
# $1 - target type: EXE,LIB,...
# $2 - name of function which returns list of supported by selected toolchain non-regular variants
#  of given target type, function must be defined at time of $(eval)
GET_VARIANTS_F = $(call FILTER_VARIANTS_LIST_F,$1,$(wordlist 2,999999,$($1)),$2)

# determine target name suffix (in case if building multiple variants of the target, each variant must have unique file name)
# $1 - target type: EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# note: no suffix if building R (regular) variant or variant is not specified (then assume R variant)
# example:
#  LIB_VARIANT_SUFFIX = _$1
#  where: argument $1 - non-empty, not R
VARIANT_SUFFIX = $(if $(filter-out R,$2),$(call $1_VARIANT_SUFFIX,$2))

# get absolute path to target file - call appropriate .._FORM_TRG macro
# $1 - EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# example:
#  $1 - target name, e.g. my_exe, may be empty
#  $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
#  EXE_FORM_TRG = $(1:%=$(BIN_DIR)/%$(call VARIANT_SUFFIX,EXE,$2)$(EXE_SUFFIX))
#  LIB_FORM_TRG = $(1:%=$(LIB_DIR)/$(LIB_PREFIX)%$(call VARIANT_SUFFIX,LIB,$2)$(LIB_SUFFIX))
#  ...
#  note: use $(patsubst...) to return empty value if $1 is empty
FORM_TRG = $(call $1_FORM_TRG,$(GET_TARGET_NAME),$2)

# get filenames of all built variants of the target
# $1 - EXE,LIB,DLL,...
ALL_TARGETS = $(foreach v,$(GET_VARIANTS),$(call FORM_TRG,$1,$v))

# form name of target objects directory
# $1 - EXE,LIB,...
# $2 - target variant: R,P,D,S... (one of variants supported by selected toolchain - result of $(GET_VARIANTS), may be empty)
# add target-specific suffix (_EXE,_LIB,_DLL,...) to distinguish objects for the targets with equal names
FORM_OBJ_DIR = $(OBJ_DIR)/$(GET_TARGET_NAME)$(if $(filter-out R,$2),_$2)_$1

# construct full path to the target
# $1 - target type: EXE,LIB,...
# $2 - target name, e.g. my_exe
# $3 - target variant, e.g. S
# note: unsupported variant $3 will be substituted with variant R (regular)
MAKE_TRG_PATH = $(call $1_FORM_TRG,$2,$(call FILTER_VARIANTS_LIST,$1,$3))

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

ifndef TOCLEAN

# create a chain of order-only dependent targets, so their rules will be executed after each other
# $1 - NON_PARALEL_GROUP_$(group_name)
# $2 - target
define NON_PARALLEL_EXECUTE_RULE
ifneq (undefined,$(origin $1))
$2:| $($1)
endif
$1:=$2
endef

# reset NON_PARALEL_GROUP_$(group_name) variable before rule execution second phase
ifdef MCHECK
$(eval define NON_PARALLEL_EXECUTE_RULE$(newline)$(subst \
  endif,else$(newline)CLEAN_BUILD_FIRST_PHASE_VARS+=$$1$(newline)endif,$(value NON_PARALLEL_EXECUTE_RULE))$(newline)endef)
endif

# remember new value of NON_PARALEL_GROUP_$(group_name)
ifdef SET_GLOBAL1
$(call define_append,NON_PARALLEL_EXECUTE_RULE,$(newline)$$(call SET_GLOBAL1,$$1))
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

# list of processed multi-target rules
# note: MULTI_TARGETS is never cleared, only appended (in rule execution second phase)
MULTI_TARGETS:=

# used to count each call of $(MULTI_TARGET)
# note: MULTI_TARGET_NUM is never cleared, only appended (in makefile parsing first phase)
MULTI_TARGET_NUM:=

# make a chain of dependencies of multi-targets on each other: 1 2 3 4 -> 2:| 1; 3:| 2; 4:| 3;
# $1 - list of generated files (absolute paths without spaces)
# note: because all multi-target files are generated at once - when need to update one of them
#  and target file timestamp is updated only after executing a rule, rule execution must be
#  delayed until files are really generated.
MULTI_TARGET_SEQ = $(subst |,:| ,$(subst $(space),$(newline),$(filter-out \
  ||%,$(join $(addsuffix |,$(wordlist 2,999999,$1) |),$1))))

# when some tool (e.g. bison) generates many files, call the tool only once:
#  assign to each generated multi-target rule an unique number
#  and remember if rule with this number was already executed for one of multi-targets
#
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# $4 - $(words $(MULTI_TARGET_NUM))
#
# note: all generated files must depend on prerequisites, making a chain of
#  order-only dependencies between generated files is not enough - a target
#  that depends on existing generated file will be rebuilt as result of changes
#  in prerequisites only if generated file also depends on prerequisites, e.g.
#
#     [good]                     [bad]
#   gen1:| gen2                gen1:| gen2
#   gen1 gen2: prereq     vs   gen2: prereq
#       touch gen1 gen2            touch gen1 gen2
#   trg1: gen1                 trg1: gen1
#   trg2: gen2                 trg2: gen2
#
# note: do not delete some of generated files manually, do 'make clean' to delete them all,
#  otherwise, missing files will be generated correctly, but as side effect up-to-date files are
#  also will be re-generated, this may lead to unexpected rebuilds on second make invocation.
#
define MULTI_TARGET_RULE
$(MULTI_TARGET_SEQ)
$(STD_TARGET_VARS)
$1: $(call fixpath,$2)
	$$(if $$(filter $4,$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS+=$4)$$(call SUP,MGEN,$1)$3)
MULTI_TARGET_NUM+=1
endef

# remember new value of MULTI_TARGET_NUM, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,MULTI_TARGET_RULE,$(newline)$$(call SET_GLOBAL1,MULTI_TARGET_NUM,0))
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

else # clean

# just delete files on 'clean'
NON_PARALLEL_EXECUTE:=
MULTI_TARGET = $(eval $(STD_TARGET_VARS))

endif # clean

# helper macro: make source dependencies list
# $1 - source(s), may be empty
# $2 - dependencies of the source(s), must be non-empty
# example: $(call FORM_SDEPS,s1 s2,d1 d2 d3/d4) -> s1/|d1|d2|d3/d4 s2/|d1|d2|d3/d4
FORM_SDEPS = $(addsuffix /|$(subst $(space),|,$(strip $2)),$1)

# get dependencies of all sources
# $1 - dependencies list (result of FORM_SDEPS)
# example: $(call ALL_SDEPS,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
ALL_SDEPS = $(filter-out %/,$(subst |, ,$1))

# filter dependencies list - get dependencies for given source(s)
# $1 - source(s)
# $2 - dependencies list (result of FORM_SDEPS)
FILTER_SDEPS = $(filter $(addsuffix /|%,$1),$2)

# get dependencies of the source(s)
# $1 - source(s)
# $2 - dependencies list (result of FORM_SDEPS)
# example: $(call EXTRACT_SDEPS,s8 s2,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
EXTRACT_SDEPS = $(call ALL_SDEPS,$(FILTER_SDEPS))

# fix source dependencies paths: add absolute path to directory of currently processing makefile to non-absolute paths
# $1 - source dependencies list (result of FORM_SDEPS)
# example: $(call FIX_SDEPS,s8/|d1|d8 s2/|d1|d2|d3/d4) -> /pr/s8/|/pr/d1|/pr/d8 /pr/s2/|/pr/d1|/pr/d2|/pr/d3/d4
FIX_SDEPS = $(subst | ,|,$(call fixpath,$(subst |,| ,$1)))

# reverse-filter dependencies list - get sources that depend on given dependencies
# $1 - dependencies to search in $2
# $2 - dependencies list (result of FORM_SDEPS)
R_FILTER_SDEPS1 = $(if $(filter $(wordlist 2,999999,$2),$1),$(firstword $2))
R_FILTER_SDEPS = $(patsubst %/,%,$(foreach d,$2,$(call R_FILTER_SDEPS1,$1,$(subst |, ,$d))))

# run executable in modified environment
# $1 - tool to execute (with parameters)
# $2 - additional path(s) separated by $(PATHSEP) to append to $(DLL_PATH_VAR)
# $3 - directory to change to for executing a tool
# $4 - list of names of variables to set in environment (export) for running an executable
# note: this function should be used in rule body, where automatic variable $@ is defined
# note: calling a tool _must_ not produce any output to stdout,
#  tool's stdout must be redirected either to file or to stderr, e.g. './my_tool >file' or './my_tool >&2'
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars/show_tool_vars_end
RUN_TOOL = $(if $2$4,$(if $2,$(eval \
  $$@:export $(DLL_PATH_VAR):=$$($(DLL_PATH_VAR))$$(if $$($(DLL_PATH_VAR)),$$(if $2,$(PATHSEP)))$2))$(foreach v,$4,$(eval \
  $$@:export $v:=$$($v)))$(if $(VERBOSE),$(show_tool_vars)@))$(if $3,$(call EXECUTE_IN,$3,$1),$1)$(if \
  $2$4,$(if $(VERBOSE),$(show_tool_vars_end)))

# define BIN_DIR/OBJ_DIR/LIB_DIR/GEN_DIR assuming that we are not in tool-mode
$(eval $(SET_DEFAULT_DIRS))

# T in "tool mode" - TOOL_MODE variable was set to non-empty value prior evaluating $(DEF_HEAD_CODE), empty in normal mode.
# note: $(TOOL_MODE) should not be used in rule templates - use $(TMD) instead, because TOOL_MODE may be set to another
#  value anywhere before $(MAKE_CONTINUE), and so before rule templates evaluation.
# reset value: we are currently not in tool mode, $(DEF_HEAD_CODE) was not evaluated yet, but $(SET_DEFAULT_DIRS)
#  has been already evaluated to set non-tool mode values of BIN_DIR/OBJ_DIR/LIB_DIR/GEN_DIR
TMD:=

# TOOL_MODE may be set to non-empty value at beginning of target makefile
#  (before including this file and so before evaluating $(DEF_HEAD_CODE))
# reset TOOL_MODE if it was not set in target makefile
ifneq (file,$(origin TOOL_MODE))
ifdef MCHECK
# do not allow to read TOOL_MODE in target makefiles, only to set it
TOOL_MODE_ERROR = $(error please use TMD variable to check for the tool mode)
TOOL_MODE = $(TOOL_MODE_ERROR)
else
TOOL_MODE:=
endif
endif # !file

# variable used to track makefiles include level
CB_INCLUDE_LEVEL:=

# list of all processed target makefiles (absolute paths)
# note: PROCESSED_MAKEFILES is never cleared, only appended (in DEF_HEAD_CODE)
ifneq (,$(MCHECK)$(value ADD_SHOWN_PERCENTS))
PROCESSED_MAKEFILES:=
endif

# $(DEF_HEAD_CODE) is not evaluated yet
HEAD_CODE_EVAL:=

# ***********************************************
# code to $(eval ...) at beginning of each makefile
# NOTE: $(MAKE_CONTINUE) before expanding $(DEF_HEAD_CODE) adds 2 to $(MAKE_CONT) list (which is normally empty or contains 1 1...)
#  - so we know if $(DEF_HEAD_CODE) was expanded from $(MAKE_CONTINUE) - remove 2 from $(MAKE_CONT) in that case
#  - if $(DEF_HEAD_CODE) was expanded not from $(MAKE_CONTINUE) - no 2 in $(MAKE_CONT) - reset MAKE_CONT
# NOTE: set TMD to remember if we are in tool mode - TOOL_MODE variable may be set to another value before calling $(MAKE_CONTINUE)
define DEF_HEAD_CODE
ifneq (,$(findstring 2,$(MAKE_CONT)))
MAKE_CONT:=$$(subst 2,1,$$(MAKE_CONT))
else
MAKE_CONT:=
HEAD_CODE_EVAL=$$(eval $$(DEF_HEAD_CODE))
DEFINE_TARGETS=$$(eval $$(DEF_TAIL_CODE))
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

# remember new value of PROCESSED_MAKEFILES variables, without tracing calls to it because it's incremented
# note: assume result of $(call SET_GLOBAL1,...,0) will give an empty line at end of expansion
ifdef MCHECK
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  MAKE_CONT:=$(newline),$$(call SET_GLOBAL1,PROCESSED_MAKEFILES,0)MAKE_CONT:=$(newline),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# add $(TARGET_MAKEFILE) to list of processed target makefiles (note: before first $(MAKE_CONTINUE))
ifneq (,$(MCHECK)$(value ADD_SHOWN_PERCENTS))
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  else,else$(newline)PROCESSED_MAKEFILES+=$$(TARGET_MAKEFILE),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# check that $(TARGET_MAKEFILE) was not already processed (note: check only before first $(MAKE_CONTINUE))
ifdef MCHECK
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  else,else$(newline)$$$$(if $$$$(filter $$$$(TARGET_MAKEFILE),$$$$(PROCESSED_MAKEFILES)),$$$$(error \
  makefile $$$$(TARGET_MAKEFILE) was already processed!)),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# remember new values of TMD, HEAD_CODE_EVAL and DEFINE_TARGETS
# remember TOOL_MODE to not reset it in $(CLEAN_BUILD_CHECK_AT_HEAD)
ifdef SET_GLOBAL1
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  TMD:=T,TMD:=T$$(newline)$$(call SET_GLOBAL1,TMD),$(subst \
  TMD:=$(close_brace),TMD:=$$(newline)$$(call SET_GLOBAL1,TMD)$(close_brace),$(subst \
  endif,$$(call SET_GLOBAL1,HEAD_CODE_EVAL DEFINE_TARGETS)$(newline)endif,$(value DEF_HEAD_CODE))))$(newline)endef)
$(call define_prepend,DEF_HEAD_CODE,$$(call SET_GLOBAL1,TOOL_MODE)$(newline))
endif

# use TOOL_MODE only to set value of TMD variable, forbid reading $(TOOL_MODE) in target makefiles
ifdef MCHECK
$(call define_append,DEF_HEAD_CODE,$(newline)TOOL_MODE=$$$$(TOOL_MODE_ERROR))
$(call define_prepend,DEF_HEAD_CODE,$$(if $$(findstring $$$$(TOOL_MODE_ERROR),$$(value TOOL_MODE)),$$(eval TOOL_MODE:=$$(TMD))))
endif

# remember new value of MAKE_CONT (without tracing calls to it)
# note: assume $(call SET_GLOBAL1,MAKE_CONT,0) will give empty line at end after expansion
ifdef MCHECK
$(eval define DEF_HEAD_CODE$(newline)$(subst \
  endif$(newline),endif$(newline)$$(call SET_GLOBAL1,MAKE_CONT,0),$(value DEF_HEAD_CODE))$(newline)endef)
endif

# ***********************************************
# code to $(eval ...) at end of each makefile
# include $(CLEAN_BUILD_DIR)/core/all.mk only if $(CB_INCLUDE_LEVEL) is empty and not inside the call of $(MAKE_CONTINUE)
# note: $(MAKE_CONTINUE) before expanding $(DEF_TAIL_CODE) adds 2 to $(MAKE_CONT) list
# note: $(CLEAN_BUILD_DIR)/core/_parallel.mk calls DEF_TAIL_CODE with @ as first argument - for the checks in $(CLEAN_BUILD_CHECK_AT_TAIL)
DEF_TAIL_CODE = $(if $(findstring 2,$(MAKE_CONT)),,$(if $(CB_INCLUDE_LEVEL),HEAD_CODE_EVAL:=,include $(CLEAN_BUILD_DIR)/core/all.mk))

# prepend DEF_TAIL_CODE with $(CLEAN_BUILD_CHECK_AT_TAIL), if it's defined in $(CLEAN_BUILD_DIR)/core/protection.mk
# note: if tracing, do not show value of $(CLEAN_BUILD_CHECK_AT_TAIL) - it's too noisy
ifdef CLEAN_BUILD_CHECK_AT_TAIL
ifdef TRACE
$(call define_prepend,DEF_TAIL_CODE,$$(eval $$(CLEAN_BUILD_CHECK_AT_TAIL)))
else
$(call define_prepend,DEF_TAIL_CODE,$$(CLEAN_BUILD_CHECK_AT_TAIL)$(newline))
endif
endif

# redefine DEFINE_TARGETS macro to produce an error if $(DEF_HEAD_CODE) was not evaluated prior expanding DEFINE_TARGETS
ifdef MCHECK
$(eval define DEF_TAIL_CODE$(newline)$(subst :=,:=$$(newline)DEFINE_TARGETS=$$(error \
  $$$$(DEF_HEAD_CODE) was not evaluated at head of makefile!),$(value DEF_TAIL_CODE))$(newline)endef)
endif

# remember new values of HEAD_CODE_EVAL and DEFINE_TARGETS
ifdef SET_GLOBAL1
$(eval define DEF_TAIL_CODE$(newline)$(subst $(comma)include,$$(newline)$$(call \
  SET_GLOBAL1,HEAD_CODE_EVAL$(if $(MCHECK), DEFINE_TARGETS))$(comma)include,$(value DEF_TAIL_CODE))$(newline)endef)
endif

# define targets at end of makefile - just expand DEFINE_TARGETS: $(DEFINE_TARGETS)
# note: DEF_HEAD_CODE will reset DEFINE_TARGETS to default value - to just evaluate $(DEF_TAIL_CODE)
# note: $(DEFINE_TARGETS) must not expand to any text - to allow calling it via just $(DEFINE_TARGETS) in target makefiles
DEFINE_TARGETS = $(error $$(DEF_HEAD_CODE) was not evaluated at head of makefile!)

# prepare target type (C, JAVA, etc.) for building (initialize its variables):
# init1->init2...->initN <set variables of target types> rulesN->...->rules2->rules1
# $1 - the name of the macro, the expansion of which gives the code for the initialization of target type variables
# $2 - the name of the macro, the expansion of which gives the code for defining target type rules
# NOTE: if $1 is empty, just evaluate $(DEF_HEAD_CODE), if it wasn't evaluated yet
# NOTE: if $1 is non-empty, expand it via $(call $1) to not pass any arguments into the expansion
CB_PREPARE_TARGET_TYPE = $(if $(value HEAD_CODE_EVAL),,$(eval $(DEF_HEAD_CODE)))$(if $1,$(eval \
  HEAD_CODE_EVAL=$(value HEAD_CODE_EVAL)$$(eval $$($1)))$(eval DEFINE_TARGETS=$$(eval $$($2))$(value DEFINE_TARGETS))$(eval $(call $1)))

# remember new values of HEAD_CODE_EVAL and DEFINE_TARGETS
ifdef SET_GLOBAL
$(eval CB_PREPARE_TARGET_TYPE = $(subst $$$(open_brace)eval $$$(open_brace)call $$1,$$(call \
  SET_GLOBAL,HEAD_CODE_EVAL DEFINE_TARGETS)$$$(open_brace)eval $$$(open_brace)call $$1,$(value CB_PREPARE_TARGET_TYPE)))
endif

# before $(MAKE_CONTINUE): save variables to restore them after (via RESTORE_VARS macro)
SAVE_VARS = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v)),$v.^s:=$$($v),define $v.^s$(newline)$(value $v)$(newline)endef)$(newline)))

# after $(MAKE_CONTINUE): restore variables saved before (via SAVE_VARS macro)
RESTORE_VARS = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v.^s)),$v:=$$($v.^s),define $v$(newline)$(value $v.^s)$(newline)endef)$(newline)))

# reset %.^s variables
ifdef CLEAN_BUILD_RESET_SAVED_VARS
$(eval RESTORE_VARS = $(subst \
  $(close_brace)$(close_brace)$(close_brace),$(close_brace)$(close_brace)$$(CLEAN_BUILD_RESET_SAVED_VARS)$(close_brace),$(value \
  RESTORE_VARS)))
endif

# initially reset variable, it is checked in DEF_HEAD_CODE
MAKE_CONT:=

# use $(MAKE_CONTINUE) to define more than one targets in single makefile
# note: all targets are built using the same set of compilers (c, java, python, etc.)
# example:
#
# include $(TOP)/make/c.mk
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
# 3) start next round - simulate including of appropriate $(TOP)/make/c.mk or $(TOP)/make/java.mk or whatever by evaluating
#    head-code $(HEAD_CODE_EVAL) - which is likely adjusted by $(TOP)/make/c.mk or $(TOP)/make/java.mk or whatever
# note: $(call DEFINE_TARGETS) with empty arguments list to not pass any to DEF_TAIL_CODE
# note: $(call HEAD_CODE_EVAL) with empty arguments list to not pass any to DEF_HEAD_CODE
# note: $(MAKE_CONTINUE) must not expand to any text - to be able to call it with just $(MAKE_CONTINUE) in target makefile
MAKE_CONTINUE = $(if $1,$(SAVE_VARS))$(eval MAKE_CONT+=2)$(call DEFINE_TARGETS)$(call HEAD_CODE_EVAL)$(if $1,$(RESTORE_VARS))

# remember new value of MAKE_CONT (without tracing calls to it)
ifdef MCHECK
$(eval MAKE_CONTINUE = $(subst $$(call DEFINE_TARGETS),$$(call SET_GLOBAL,MAKE_CONT,0)$$(call DEFINE_TARGETS),$(value MAKE_CONTINUE)))
endif

# define shell utilities
include $(UTILS_MK)

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

# BIN_DIR/OBJ_DIR/LIB_DIR/GEN_DIR change their values depending on the value of TOOL_MODE set
#  in last parsed makefile, so clear these variables before rule execution second phase
CLEAN_BUILD_FIRST_PHASE_VARS += BIN_DIR OBJ_DIR LIB_DIR GEN_DIR

# makefile parsing first phase variables
CLEAN_BUILD_FIRST_PHASE_VARS += CLEAN_BUILD_GOALS CB_NEEDED_DIRS ORDER_DEPS MULTI_TARGET_NUM CB_INCLUDE_LEVEL \
  PROCESSED_MAKEFILES MAKE_CONT SET_DEFAULT_DIRS TOOL_OVERRIDE_DIRS ADD_MDEPS ADD_ADEPS ADD_WHAT_MAKEFILE_BUILDS \
  CREATE_MAKEFILE_ALIAS ADD_ORDER_DEPS NEED_GEN_DIRS STD_TARGET_VARS1 STD_TARGET_VARS MAKEFILE_INFO_TEMPL \
  SET_MAKEFILE_INFO GET_TARGET_NAME GET_VARIANTS_F GET_VARIANTS FORM_TRG ALL_TARGETS FORM_OBJ_DIR ADD_GENERATED CHECK_GENERATED \
  ADD_GENERATED_RET NON_PARALLEL_EXECUTE_RULE NON_PARALLEL_EXECUTE MULTI_TARGET_SEQ MULTI_TARGET_RULE MULTI_TARGET \
  CHECK_MULTI_RULE TMD TOOL_MODE_ERROR TOOL_MODE DEF_HEAD_CODE DEF_TAIL_CODE DEFINE_TARGETS SAVE_VARS RESTORE_VARS MAKE_CONTINUE TOCLEAN

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, passed to environment of called tools or modified via operator +=
$(call SET_GLOBAL,MAKEFLAGS CLEAN_BUILD_GOALS $(PASS_ENV_VARS) PATH SHELL CLEAN_BUILD_FIRST_PHASE_VARS \
  CB_NEEDED_DIRS NO_CLEAN_BUILD_DISTCLEAN_TARGET DEBUG VERBOSE QUIET INFOMF MDEBUG SHOWN_PERCENTS CLEAN \
  ORDER_DEPS MULTI_TARGETS MULTI_TARGET_NUM CB_INCLUDE_LEVEL PROCESSED_MAKEFILES MAKE_CONT NO_DEPS,0)

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,PROJECT_VARS_NAMES PASS_ENV_VARS \
  CLEAN_BUILD_VERSION CLEAN_BUILD_DIR CLEAN_BUILD_REQUIRED_VERSION \
  BUILD SUPPORTED_TARGETS TARGET OS TCPU CPU UTILS UTILS_MK TARGET_MAKEFILE \
  ospath nonrelpath TOOL_SUFFIX PATHSEP DLL_PATH_VAR show_tool_vars1 show_tool_vars show_tool_vars_end SED_MULTI_EXPR \
  GEN_COLOR MGEN_COLOR CP_COLOR RM_COLOR RMDIR_COLOR MKDIR_COLOR TOUCH_COLOR CAT_COLOR SED_COLOR \
  PRINT_PERCENTS COLORIZE SHOWN_REMAINDER ADD_SHOWN_PERCENTS==SHOWN_REMAINDER \
  FORMAT_PERCENTS=SHOWN_PERCENTS REM_MAKEFILE=SHOWN_PERCENTS=SHOWN_PERCENTS SUP \
  TARGET_TRIPLET DEF_BIN_DIR DEF_OBJ_DIR DEF_LIB_DIR DEF_GEN_DIR SET_DEFAULT_DIRS \
  TOOL_BASE MK_TOOLS_DIR GET_TOOLS GET_TOOL TOOL_OVERRIDE_DIRS \
  ADD_MDEPS ADD_ADEPS ADD_WHAT_MAKEFILE_BUILDS CREATE_MAKEFILE_ALIAS ADD_ORDER_DEPS=ORDER_DEPS=ORDER_DEPS \
  NEED_GEN_DIRS STD_TARGET_VARS1 STD_TARGET_VARS MAKEFILE_INFO_TEMPL SET_MAKEFILE_INFO fixpath GET_TARGET_NAME \
  SUPPORTED_VARIANTS FILTER_VARIANTS_LIST FILTER_VARIANTS_LIST_F GET_VARIANTS GET_VARIANTS_F VARIANT_SUFFIX \
  FORM_TRG ALL_TARGETS FORM_OBJ_DIR MAKE_TRG_PATH ADD_GENERATED CHECK_GENERATED ADD_GENERATED_RET \
  NON_PARALLEL_EXECUTE_RULE NON_PARALLEL_EXECUTE \
  MULTI_TARGET_SEQ MULTI_TARGET_RULE=MULTI_TARGET_NUM=MULTI_TARGET_NUM MULTI_TARGET CHECK_MULTI_RULE \
  FORM_SDEPS ALL_SDEPS FILTER_SDEPS EXTRACT_SDEPS FIX_SDEPS R_FILTER_SDEPS1 R_FILTER_SDEPS RUN_TOOL TMD TOOL_MODE_ERROR \
  DEF_HEAD_CODE DEF_TAIL_CODE CB_PREPARE_TARGET_TYPE DEFINE_TARGETS SAVE_VARS RESTORE_VARS MAKE_CONTINUE CONF_COLOR PRODUCT_VER)

# if TOCLEAN value is non-empty, allow tracing calls to it,
# else - just protect TOCLEAN from changes, do not make it's value non-empty - because TOCLEAN is checked in ifdefs
$(call SET_GLOBAL,TOCLEAN,$(if $(value TOCLEAN),,0))
