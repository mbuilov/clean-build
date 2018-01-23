#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules and definitions for building targets,
#  defines constants, such as: CBLD_TARGET, CBLD_OS, CBLD_TCPU, CBLD_CPU
#  different core macros, e.g.: 'toclean', 'add_generated', 'is_tool_mode', 'define_targets', 'make_continue', 'ospath', 'fixpath'
#  and many more.

# Note.
#  Any variable defined in the environment or command line by default is exported to sub-processes spawned by make.
#  Because it's not known in advance which variables are defined in the environment, it is possible to accidentally
#   change the values of the environment variables due to collisions of the variable names in makefiles.
#  To reduce the probability of collisions of the names, use the unique variable names in makefiles whenever possible.

# Conventions:
#  1) variables in lower case are always initialized with default values and _never_ taken from the environment,
#  2) clean-build internal core macros are prefixed with 'cb_' (except some common names, possibly redefined for the project),
#  3) user variables and parameters for build templates should also be in lower case,
#  4) variables in UPPER case _may_ be taken from the environment or command line,
#  5) clean-build specific variables that may be taken from the environment are in UPPER case and prefixed with 'CBLD_',
#  6) default values for variables from the environment should be set via operator ?= - to not override values passed to sub-processes,
#  7) ifdef/ifndef should only be used with previously initialized (possibly by empty values) variables.

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

# drop make's default legacy rules - we'll use custom ones
.SUFFIXES:

# delete target file if failed to execute any of commands to make it
.DELETE_ON_ERROR:

# reset Gnu Make internal variable if it's not defined (to avoid use of undefined variable)
ifeq (undefined,$(origin MAKECMDGOALS))
MAKECMDGOALS:=
endif

# specify default goal (defined in $(cb_dir)/core/all.mk)
.DEFAULT_GOAL := all

# assume project configuration makefile, which have included this makefile, defines some variables
#  - save list of those variables to redefine them below with the 'override' keyword
# note: SHELL, CBLD_CONFIG and CBLD_BUILD variables are not reset by the clean-build, so don't override them
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
cb_project_vars := $(strip $(foreach =,$(filter-out SHELL MAKEFLAGS CURDIR MAKEFILE_LIST MAKECMDGOALS .DEFAULT_GOAL \
  %.^e CBLD_CONFIG CBLD_BUILD,$(.VARIABLES)),$(if $(findstring file,$(origin $=)),$=)))

# clean-build version: major.minor.patch
clean_build_version := 0.9.1

# clean-build root directory (absolute path)
# note: a project normally uses its own variable with the same value (e.g. CBLD_ROOT) for referencing clean-build files
cb_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# include functions library
# note: assume project configuration makefile will not try to override macros defined in $(cb_dir)/core/functions.mk,
#  but if it is absolutely needed, it is possible to do so using the 'override' keyword
include $(cb_dir)/core/functions.mk

# clean_build_required_version - clean-build version required by the project makefiles,
#  it is normally defined in the project configuration makefile (see $(cb_dir)/stub/prepare.mk)
ifneq (file,$(origin clean_build_required_version))
clean_build_required_version := 0.0.0
endif

# check required clean-build version
ifeq (,$(call ver_compatible,$(clean_build_version),$(clean_build_required_version)))
$(error incompatible clean-build version: $(clean_build_version), project needs: $(clean_build_required_version))
endif

# CBLD_BUILD - directory of built artifacts - must be defined prior including this makefile
# note: we need non-recursive (simple) value of CBLD_BUILD to create simple variables: def_bin_dir, def_lib_dir, etc.
cb_build := $(abspath $(CBLD_BUILD))

ifndef cb_build
$(error CBLD_BUILD - path to directory of built artifacts is not defined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(cb_build)))
$(error CBLD_BUILD='$(cb_build)', path to directory of built artifacts must not contain spaces)
endif

# needed directories - clean-build will create them in $(cb_dir)/core/all.mk
# note: 'cb_needed_dirs' is never cleared, only appended
cb_needed_dirs:=

# add support for generation of $(CBLD_CONFIG) configuration makefile as result of predefined 'config' goal,
#  adjust values of 'cb_project_vars' and 'project_exported_vars' variables, define 'config_remember_vars' macro
include $(cb_dir)/core/confsup.mk

# clean-build always sets default values for the variables, to override these defaults
#  by the ones specified in the project configuration makefile, use the 'override' directive
$(foreach =,$(cb_project_vars),$(eval override $(if $(findstring simple,$(flavor \
  $=)),$$=:=$$($$=),define $$=$(newline)$(value $=)$(newline)endef)))

# include variables protection module - define 'cb_checking', 'cb_tracing', 'set_global', 'get_global', 'env_remember' and other macros
# protect from changes project variables - which have the 'override' $(origin) and exported variables in the $(project_exported_vars)
include $(cb_dir)/core/protection.mk

# protect from modification macros defined in the $(cb_dir)/core/functions.mk, $(cb_dir)/core/confsup.mk and $(cb_dir)/core/protection.mk
# note: 'cb_target_makefile' variable is used here temporary, it will be properly defined below
$(cb_target_makefile)

# list of project-supported target types
# note: normally these defaults are overridden in project configuration makefile
project_supported_targets := DEBUG RELEASE

# what target type to build (DEBUG, RELEASE, etc.)
# note: normally CBLD_TARGET get overridden by specifying it in the command line
CBLD_TARGET ?= RELEASE

# operating system we are building for (WIN7, DEBIAN6, SOLARIS10, etc.)
# note: normally CBLD_OS get overridden by specifying it in the command line
# note: CBLD_OS value may affect default values of other variables (CBLD_TCPU, CBLD_UTILS, etc.)
ifeq (undefined,$(origin CBLD_OS))
ifneq (,$(filter /cygdrive/%,$(CURDIR)))
CBLD_OS := CYGWIN
else ifneq (environment,$(origin OS))
CBLD_OS := $(call toupper,$(shell uname))
else ifeq (Windows_NT,$(OS))
CBLD_OS := WINDOWS
else
# unknown, should be defined in the project configuration makefile or in the command line
CBLD_OS :=
endif
endif # !CBLD_OS

# processor architecture of build helper tools created while the build
# note: CBLD_TCPU likely is the native processor architecture of the build toolchain
# note: equivalent of '--build' Gnu Autoconf configure script option
# note: CBLD_TCPU specification may also encode format of executable files, e.g. CBLD_TCPU=m68k-coff, it is checked by the C compiler
# note: normally CBLD_TCPU get overridden by specifying it in command line
ifeq (undefined,$(origin CBLD_TCPU))
ifndef CBLD_OS
CBLD_TCPU := x86
else ifeq (,$(filter WIN%,$(CBLD_OS)))
CBLD_TCPU := $(shell uname -m)
else ifeq (AMD64,$(if $(findstring environment,$(origin PROCESSOR_ARCHITECTURE)),$(PROCESSOR_ARCHITECTURE)))
# win64
CBLD_TCPU := x86_64
else ifeq (AMD64,$(if $(findstring environment,$(origin PROCESSOR_ARCHITEW6432)),$(PROCESSOR_ARCHITEW6432)))
# wow64
CBLD_TCPU := x86_64
else
# win32
CBLD_TCPU := x86
endif
endif # !CBLD_TCPU

# processor architecture we are building the package for (x86, sparc64, armv5, mips24k, etc.)
# note: equivalent of '--host' Gnu Autoconf configure script option
# note: CBLD_CPU specification may also encode format of executable files, e.g. CBLD_CPU=m68k-coff, it is checked by the C compiler
# note: normally CBLD_CPU get overridden by specifying it in command line
ifeq (undefined,$(origin CBLD_CPU))
CBLD_CPU := $(CBLD_TCPU)
endif

# flavor of system shell utilities (such as cp, mv, rm, etc.)
# note: $(CBLD_UTILS) value is used only to form name of standard makefile with definitions of shell utilities
# note: normally CBLD_UTILS get overridden by specifying it in command line, for example: CBLD_UTILS:=gnu
ifeq (undefined,$(origin CBLD_UTILS))
CBLD_UTILS := $(if \
  $(filter WIN%,$(CBLD_OS)),cmd,$(if \
  $(filter CYG% LIN%,$(CBLD_OS)),gnu,unix))
endif

# remember value of CBLD_BUILD if it was taken from the environment (in the project configuration makefile - $(cb_dir)/stub/project.mk)
# note: else, if CBLD_BUILD was not taken from the environment - CBLD_BUILD should be already stored for the generated configuration
#  makefile as a project variable (in the $(cb_dir)/core/confsup.mk)
# note: remember autoconfigured variables: CBLD_TARGET, CBLD_OS, CBLD_TCPU, CBLD_TCPU and CBLD_UTILS (if they are not defined as project
#  variables and so not already saved in the $(cb_dir)/core/confsup.mk)
$(call config_remember_vars,CBLD_BUILD CBLD_TARGET CBLD_OS CBLD_TCPU CBLD_CPU CBLD_UTILS)

# makefile with the definitions of shell utilities
utils_mk := $(cb_dir)/utils/$(CBLD_UTILS).mk

ifeq (,$(wildcard $(utils_mk)))
$(error file '$(utils_mk)' was not found, check $(if $(findstring file,$(origin \
  utils_mk)),values of CBLD_OS=$(CBLD_OS) and CBLD_UTILS=$(CBLD_UTILS),value of overridden 'utils_mk' variable))
endif

# run via $(MAKE) D=1 to debug makefiles
ifeq (command line,$(origin D))
cb_mdebug := $(D:0=)
else
# don't debug makefiles by default
cb_mdebug:=
endif

ifdef cb_mdebug
$(call dump_vars,CBLD_BUILD CBLD_CONFIG CBLD_TARGET CBLD_OS CBLD_TCPU CBLD_CPU CBLD_UTILS cb_dir cb_build utils_mk,,)
endif

# list of build system supported goals
# note: may be updated if necessary in the makefiles processed later
build_system_goals := all config clean check tests

# 'no_clean_build_distclean_goal' may be set to non-empty value in the project configuration makefile to disable
#  clean-build defined 'distclean' goal
no_clean_build_distclean_goal:=

ifndef no_clean_build_distclean_goal
build_system_goals += distclean
endif

# check that CBLD_TARGET is correctly defined only if goal is not 'distclean' (else do not require that CBLD_TARGET must be defined)
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

# what target type to build
ifeq (,$(filter $(CBLD_TARGET),$(project_supported_targets)))
$(error unknown CBLD_TARGET=$(CBLD_TARGET), please pick one of: $(project_supported_targets))
endif

else # distclean

ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error 'distclean' goal must be specified alone, current goals: $(MAKECMDGOALS))
endif

ifndef no_clean_build_distclean_goal

# define 'distclean' goal - delete all built artifacts, including directories
# note: 'delete_dirs' macro is defined in the included below $(utils_mk) makefile
distclean:
	$(quiet)$(call delete_dirs,$(cb_build))

endif # !no_clean_build_distclean_goal

endif # distclean

# define 'verbose' and 'quiet' constants, 'suppress' function and other macros
include $(cb_dir)/core/suppress.mk

# to simplify target makefiles, define 'debug' variable:
#  $(debug) is non-empty for debugging targets like "PROJECTD" or "DEBUG"
debug := $(filter DEBUG %D,$(CBLD_TARGET))

# base part of created directories of built artifacts, e.g. DEBUG-LINUX-x86
target_triplet := $(CBLD_TARGET)-$(CBLD_OS)-$(CBLD_CPU)

# output directories:
# bin - for executables, dlls
# lib - for libraries, shared objects
# obj - for object files
# gen - for generated files (headers, sources, resources, etc)
def_bin_dir := $(cb_build)/bin-$(target_triplet)
def_obj_dir := $(cb_build)/obj-$(target_triplet)
def_lib_dir := $(cb_build)/lib-$(target_triplet)
def_gen_dir := $(cb_build)/gen-$(target_triplet)

# code to evaluate for restoring default directories after the "tool mode"
define cb_set_sefault_dirs
bin_dir:=$(def_bin_dir)
obj_dir:=$(def_obj_dir)
lib_dir:=$(def_lib_dir)
gen_dir:=$(def_gen_dir)
endef

# base directory where build tools are built
tool_base := $(cb_build)/tools

# ensure $(tool_base) is under the $(cb_build)
ifeq (,$(filter $(cb_build)/%,$(abspath $(tool_base))))
$(error tool_base=$(tool_base) is not a subdirectory of cb_build=$(cb_build))
endif

# macro to form the path where tools are built
# $1 - $(tool_base)
# $2 - $(CBLD_TCPU)
mk_tools_dir = $1/bin-tool-$2-$(CBLD_TARGET)

# code to evaluate for overriding default directories in the "tool mode"
define cb_tool_override_dirs
bin_dir:=$(call mk_tools_dir,$(tool_base),$(CBLD_TCPU))
obj_dir:=$(tool_base)/obj-tool-$(CBLD_TCPU)-$(CBLD_TARGET)
lib_dir:=$(tool_base)/lib-tool-$(CBLD_TCPU)-$(CBLD_TARGET)
gen_dir:=$(tool_base)/gen-tool-$(CBLD_TCPU)-$(CBLD_TARGET)
endef

# redefine 'cb_set_sefault_dirs' and 'cb_tool_override_dirs' as non-recursive variables
ifndef set_global1
cb_set_sefault_dirs   := $(cb_set_sefault_dirs)
cb_tool_override_dirs := $(cb_tool_override_dirs)
else
# remember new values of standard directories
# note: trace namespace: dirs
cb_set_sefault_dirs   := $(cb_set_sefault_dirs)$(newline)$(call set_global1,bin_dir obj_dir lib_dir gen_dir,dirs)
cb_tool_override_dirs := $(cb_tool_override_dirs)$(newline)$(call set_global1,bin_dir obj_dir lib_dir gen_dir,dirs)
endif

# executable file suffix of the generated tools
# note: $(cb_dir)/utils/cmd.mk redefines 'tool_suffix' to exe
tool_suffix:=

# macro to form absolute paths to the tools executables
# $1 - $(tool_base)
# $2 - $(CBLD_TCPU)
# $3 - tool name(s)
get_tools = $(addprefix $(mk_tools_dir)/,$(3:=$(tool_suffix)))

# get path to the tool $1 for the current 'tool_base' and CBLD_TCPU
get_tool = $(call get_tools,$(tool_base),$(CBLD_TCPU),$1)

# 'cb_to_clean' - list of files/directories to recursively delete on $(MAKE) clean
# note: 'cb_to_clean' list is never cleared, only appended via 'toclean' macro
# note: should not be directly accessed/modified in target makefiles
cb_to_clean:=

# 'toclean' - function to add files/directories to delete to 'cb_to_clean' list
# note: do not add values to 'cb_to_clean' if not cleaning up
ifeq (,$(filter clean,$(MAKECMDGOALS)))
toclean:=
else ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error 'clean' goal must be specified alone, current goals: $(MAKECMDGOALS))
else ifndef cb_checking
toclean = $(eval cb_to_clean+=$$1)
else
# remember new value of 'cb_to_clean' list, without tracing calls to it because it's incremented
toclean = $(eval cb_to_clean+=$$1$(newline)$(call set_global1,cb_to_clean))
endif

# absolute path to the target makefile
cb_target_makefile := $(abspath $(firstword $(MAKEFILE_LIST)))

# append makefiles (really .PHONY goals created from them) to the 'order_deps' list
# note: this function is useful to specify dependency on all targets built by specified makefiles (a tree of makefiles)
# note: argument - list of makefiles (or directories, where Makefile file is searched)
# note: overridden in $(cb_dir)/core/_submakes.mk
add_mdeps:=

# macro that patches given evaluable template - to print what makefile builds
# $1 - template name
# $2 - expression that gives target file(s) the template builds
# $3 - optional expression that gives order-only dependencies
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating expansion result
cb_add_what_makefile_builds:=

# to be able to use 'suppress' function in the rules of the target(s) $1, define target-specific variables:
# F.^ - holds the path to current target makefile
# C.^ - holds the number of section in the target makefile after a call to $(make_continue)
# note: these target-specific variables are automatically defined for the targets registered via std_target_vars/add_generated macros
set_makefile_info:=

ifndef toclean

# define a .PHONY goal which will depend on main targets (registered via 'std_target_vars' macro defined below)
.PHONY: $(cb_target_makefile)-

# default goal 'all' - depends only on the root makefile
all: $(cb_target_makefile)-

# order-only dependencies of all leaf makefile targets
# note: 'order_deps' variable should not be directly modified in target makefiles,
#  use 'add_order_deps/add_mdeps' functions to append value(s) to 'order_deps'
order_deps:=

# append value(s) to 'order_deps' list
ifndef cb_checking
add_order_deps = $(eval order_deps+=$$1)
else
# remember new value of 'order_deps', without tracing calls to it because it's incremented
add_order_deps = $(eval order_deps+=$$1$(newline)$(call set_global1,order_deps))
endif

# add directories $1 to the list of auto-created ones - 'cb_needed_dirs'
# note: these directories are will be auto-deleted while cleaning up
# note: callers of 'need_gen_dirs' may assume that it will protect new value of 'cb_needed_dirs'
#  so callers _may_ change 'cb_needed_dirs' without protecting it. Protect 'cb_needed_dirs' here.
ifndef cb_checking
need_gen_dirs = $(eval cb_needed_dirs+=$$1)
else
# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
need_gen_dirs = $(eval cb_needed_dirs+=$$1$(newline)$(call set_global1,cb_needed_dirs))
endif

# register targets as main ones built by the current makefile, add standard target-specific variables
# $1 - target file(s) to build (absolute paths)
# $2 - directories of target file(s) (absolute paths)
# note: postpone expansion of $(order_deps) to optimize parsing
# note: .PHONY target $(cb_target_makefile)- will depend on the registered main targets in list $1
# note: callers of 'std_target_vars1' may assume that it will protect new value of 'cb_needed_dirs'
#  so callers _may_ change 'cb_needed_dirs' without protecting it. Protect 'cb_needed_dirs' here.
define std_target_vars1
$1:| $2 $$(order_deps)
$(cb_target_makefile)-:$1
cb_needed_dirs+=$2
endef

ifdef cb_checking

# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
$(call define_append,std_target_vars1,$(newline)$$(call set_global1,cb_needed_dirs))

# check that files $1 are generated under $(gen_dir), $(bin_dir), $(obj_dir) or $(lib_dir) directories
cb_check_generated_at = $(if $(filter-out $(gen_dir)/% $(bin_dir)/% $(obj_dir)/% $(lib_dir)/%,$1),$(error \
  these files are generated not under $$(gen_dir), $$(bin_dir), $$(obj_dir) or $$(lib_dir): $(filter-out \
  $(gen_dir)/% $(bin_dir)/% $(obj_dir)/% $(lib_dir)/%,$1)))

$(call define_prepend,std_target_vars1,$$(cb_check_generated_at))

endif # cb_checking

ifdef cb_mdebug

# fix template to print (while evaluating the template) what makefile builds
# $1 - template name
# $2 - expression that gives target file(s) the template builds
# $3 - optional expression that gives order-only dependencies
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating result of the expansion
cb_add_what_makefile_builds = $(call define_append,$1,$$(info \
  $$(if $$(is_tool_mode),[T]: )$$(patsubst $$(cb_build)/%,%,$2)$(if $3,$$(if $3, | $3))))

# patch 'std_target_vars1' template - print what makefile builds
$(call cb_add_what_makefile_builds,std_target_vars1,$$1,$$(order_deps))

endif # cb_mdebug

# define target-specific variables for the 'suppress' function
# note: 'suppress' and 'cb_makefile_info_templ' - defined in included above $(cb_dir)/core/suppress.mk
ifdef cb_makefile_info_templ

# to be able to use 'suppress' function in the rules of the target(s) $1, define target-specific variables:
# F.^ - holds the path to current target makefile
# C.^ - holds the number of section in the target makefile after a call to $(make_continue)
set_makefile_info = $(eval $(cb_makefile_info_templ))

# optimize: do not call 'set_makefile_info' from 'std_target_vars1', include code of 'set_makefile_info' directly
ifndef cb_tracing
# note: use value of 'cb_makefile_info_templ' only if not tracing, else - it was modified for the tracing
$(call define_prepend,std_target_vars1,$(value cb_makefile_info_templ)$(newline))
else
$(call define_prepend,std_target_vars1,$$(cb_makefile_info_templ)$(newline))
endif

endif # cb_makefile_info_templ

# register targets as the main ones built by the current makefile, add standard target-specific variables
# (main targets - that are not necessarily used as prerequisites for other targets in the same makefile)
# $1 - generated file(s) (absolute paths)
# note: callers of 'std_target_vars' may assume that it will protect new value of 'cb_needed_dirs'
#  so callers _may_ change 'cb_needed_dirs' without protecting it. Protect 'cb_needed_dirs' here.
std_target_vars = $(call std_target_vars1,$1,$(patsubst %/,%,$(sort $(dir $1))))

else # clean

# just delete (recursively, with all content) generated directories $1 (absolute paths) 
# note: callers of 'need_gen_dirs' may assume that it will protect new value of 'cb_needed_dirs'
#  so callers _may_ change 'cb_needed_dirs' without protecting it. Protect 'cb_needed_dirs' here (do not optimize!).
# remember new values of 'cb_to_clean' and 'cb_needed_dirs' without tracing calls to them because they are incremented
ifndef cb_checking
need_gen_dirs = $(eval cb_to_clean+=$$1)
else
need_gen_dirs = $(eval cb_to_clean+=$$1$(newline)$$(call set_global1,cb_to_clean cb_needed_dirs))
endif

# just delete target files $1 (absolute paths)
# note: callers of 'std_target_vars' may assume that it will protect new value of 'cb_needed_dirs'
#  so callers _may_ change 'cb_needed_dirs' without protecting it. Protect 'cb_needed_dirs' here (do not optimize!).
# remember new values of 'cb_to_clean' and 'cb_needed_dirs' without tracing calls to them because they are incremented
ifndef cb_checking
std_target_vars = cb_to_clean+=$1
else
std_target_vars = cb_to_clean+=$1$(newline)$(call set_global1,cb_to_clean cb_needed_dirs)
endif

# do nothing if cleaning up
add_order_deps:=

endif # clean

# add generated files $1 to build sequence
# note: files must be generated under $(gen_dir),$(bin_dir),$(obj_dir) or $(lib_dir) directories
# note: directories for generated files will be auto-created
# note: generated files will be auto-deleted while completing the 'clean' goal
add_generated = $(eval $(std_target_vars))

# same as 'add_generated', but return the list of generated files $1
add_generated_ret = $(add_generated)$1

# define bin_dir/obj_dir/lib_dir/gen_dir assuming that we are not in the "tool mode"
$(eval $(cb_set_sefault_dirs))

# non-empty (likely T) in "tool mode" - 'tool_mode' variable was set to that value prior evaluating $(cb_def_head), empty in normal mode.
# note: $(tool_mode) should not be used in rule templates - use $(is_tool_mode) instead, because 'tool_mode' variable may be set to
#  another value anywhere before $(make_continue), and so before the evaluation of rule templates.
# reset the value: we are currently not in the "tool mode", $(cb_def_head) was not evaluated yet, but $(cb_set_sefault_dirs) had
#  already been evaluated to set non-tool mode values of bin_dir/obj_dir/lib_dir/gen_dir.
ifeq (file,$(origin tool_mode))
is_tool_mode := $(tool_mode)
else
is_tool_mode:=
endif

# 'tool_mode' may be set to non-empty value (likely T) at the beginning of target makefile
#  (before including this file and so before evaluating $(cb_def_head))
# reset 'tool_mode' if it was not set in the target makefile
ifdef cb_checking
# do not allow to read 'tool_mode' in target makefiles, only to set it
cb_tool_mode_access_error = $(error please use 'is_tool_mode' variable to check for "tool mode")
tool_mode = $(cb_tool_mode_access_error)
else ifneq (file,$(origin tool_mode))
tool_mode:=
endif

# variable used to track makefiles include level
cb_include_level:=

# list of all processed target makefiles (absolute paths) - for the check that one makefile is not processed twice,
#  also used in $(cb_dir)/core/all.mk - to properly compute percents of completed target makefiles
# note: 'cb_target_makefiles' is never cleared, only appended (in $(cb_def_head))
ifneq (,$(cb_checking)$(value cb_add_shown_percents))
cb_target_makefiles:=
endif

# a chain of macros which should be evaluated for preparing target templates (resetting "local" variables - template parameters)
# $(cb_def_head) was not evaluated yet, the chain is empty (it's checked in 'cb_prepare_templ')
cb_head_eval:=

# initially reset variable holding a number of section of $(make_continue), it is checked in 'cb_def_head'
cb_make_cont:=

# ***********************************************
# code to $(eval ...) at the beginning of each target makefile
# NOTE: $(make_continue) before expanding $(cb_def_head) adds 2 to 'cb_make_cont' list (which is normally empty or contains 1 1...)
#  - so we know if $(cb_def_head) was expanded from $(make_continue) - remove 2 from 'cb_make_cont' list in that case
#  - if $(cb_def_head) was expanded not from $(make_continue) - no 2 in $(cb_make_cont) - reset 'cb_make_cont' variable
# NOTE: set 'is_tool_mode' variable to remember if we are in "tool mode" - 'tool_mode' variable may be set to another value before
#  calling $(make_continue)
define cb_def_head
ifneq (,$(findstring 2,$(cb_make_cont)))
cb_make_cont:=$$(subst 2,1,$$(cb_make_cont))
else
cb_make_cont:=
cb_head_eval=$$(eval $$(cb_def_head))
define_targets=$$(eval $$(cb_def_tail))
endif
is_tool_mode:=$(tool_mode)
$(if $(tool_mode),$(if \
  $(is_tool_mode),,$(cb_tool_override_dirs)),$(if \
  $(is_tool_mode),$(cb_set_sefault_dirs)))
endef

# show debug info prior defining targets, e.g.: "..../project/one.mk+2"
# note: $(cb_make_cont) contains 2 if inside $(make_continue)
ifdef cb_mdebug
$(call define_prepend,cb_def_head,$$(info $$(subst \
  $$(space),,$$(cb_include_level))$$(cb_target_makefile)$$(if $$(findstring 2,$$(cb_make_cont)),+$$(words $$(cb_make_cont)))))
endif

# prepend 'cb_def_head' with $(cb_check_at_head), if it's defined in $(cb_dir)/core/protection.mk
ifdef cb_check_at_head
$(call define_prepend,cb_def_head,$$(cb_check_at_head)$(newline))
endif

ifneq (,$(cb_checking)$(value cb_add_shown_percents))

# add $(cb_target_makefile) to the list of processed target makefiles (note: only before the first $(make_continue) call)
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)cb_target_makefiles+=$$$$(cb_target_makefile),$(value cb_def_head))$(newline)endef)

# remember new value of 'cb_target_makefiles' variable, without tracing calls to it because it's incremented
# note: assume result of $(call set_global1,cb_target_makefiles) will give an empty line at end of expansion
ifdef cb_checking
$(eval define cb_def_head$(newline)$(subst \
  cb_make_cont:=$(newline),$$(call set_global1,cb_target_makefiles)cb_make_cont:=$(newline),$(value cb_def_head))$(newline)endef)
endif

# check that all targets are built/update percents of completed makefiles
cb_check_targets=

ifdef cb_checking
# note: must be called in $(cb_target_makefile)'s rule body, where automatic variables $@ and $^ are defined
cb_check_targets += $(foreach =,$(filter-out $(wildcard $^),$^),$(info $(@:-=): cannot build $=))
endif

ifdef cb_add_shown_percents
# note: 'cb_update_percents' - defined in $(cb_dir)/core/suppress.mk
cb_check_targets += $(cb_update_percents)
endif

# if all targets of $(cb_target_makefile) are completed, check that files exist/update percents
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)$$$$(cb_target_makefile)-:$(newline)$(tab)$$$$(cb_check_targets),$(value cb_def_head))$(newline)endef)

endif # cb_checking || cb_add_shown_percents

ifdef cb_checking

# check that $(cb_target_makefile) was not already processed (note: check only before the first $(make_continue))
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)$$$$(if $$$$(filter $$$$(cb_target_makefile),$$$$(cb_target_makefiles)),$$$$(error \
  makefile $$$$(cb_target_makefile) was already processed!)),$(value cb_def_head))$(newline)endef)

# remember new value of 'cb_make_cont' (without tracing calls to it)
# note: assume result of $(call set_global1,cb_make_cont) will give an empty line at end of expansion
$(eval define cb_def_head$(newline)$(subst \
  endif$(newline),endif$(newline)$$(call set_global1,cb_make_cont),$(value cb_def_head))$(newline)endef)

endif # cb_checking

ifdef set_global1

# remember new values of 'is_tool_mode', 'cb_head_eval' and 'define_targets'
# note: trace namespaces: is_tool_mode, def_code
$(eval define cb_def_head$(newline)$(subst \
  is_tool_mode:=$$(tool_mode),is_tool_mode:=$$(tool_mode)$(newline)$$(call set_global1,is_tool_mode,is_tool_mode),$(subst \
  endif,$$(call set_global1,cb_head_eval define_targets,def_code)$(newline)endif,$(value cb_def_head)))$(newline)endef)

ifndef cb_checking
# trace (next) calls to 'tool_mode' if not checking makefiles, else - 'tool_mode' is protected at the end of $(cb_def_head)
# note: trace namespace: tool_mode
$(call define_prepend,cb_def_head,$$(call set_global1,tool_mode,tool_mode)$(newline))
endif

endif # set_global1

ifdef cb_checking

# use 'tool_mode' only to set value of 'is_tool_mode' variable, forbid reading $(tool_mode) in target makefiles
# note: do not trace calls to 'tool_mode' after resetting it to $$(cb_tool_mode_access_error) - this is needed to pass the (next) check
#  if value of 'tool_mode' is the '$(cb_tool_mode_access_error)' (or empty, or non-empty) at the beginning of $(cb_def_head)
# note: assume result of $(call set_global1,tool_mode) will give an empty line at end of expansion
$(eval define cb_def_head$(newline)$(subst endif$(newline),endif$(newline)tool_mode=$$$$(cb_tool_mode_access_error)$(newline)$$(call \
  set_global1,tool_mode),$(value cb_def_head))$(newline)endef)

# when expanding $(cb_def_head), first restore 'tool_mode' variable, if it wasn't changed before $(cb_def_head)
$(call define_prepend,cb_def_head,$$(if $$(findstring $$$$(cb_tool_mode_access_error),$$(value \
  tool_mode)),$$(eval tool_mode:=$$$$(is_tool_mode))))

endif # cb_checking

# ***********************************************
# code to $(eval ...) at the end of each target makefile
# include $(cb_dir)/core/all.mk only if $(cb_include_level) is empty and not inside the call of $(make_continue)
# note: $(make_continue) before expanding $(cb_def_tail) adds 2 to $(cb_make_cont) list
# note: $(cb_dir)/core/_submakes.mk calls 'cb_def_tail' with @ as first argument - for the checks in $(cb_check_at_tail)
cb_def_tail = $(if $(findstring 2,$(cb_make_cont)),,$(if $(cb_include_level),cb_head_eval:=,include $(cb_dir)/core/all.mk))

# prepend 'cb_def_tail' with $(cb_check_at_tail), if it's defined in the $(cb_dir)/core/protection.mk
ifdef cb_check_at_tail
$(call define_prepend,cb_def_tail,$$(cb_check_at_tail)$(newline))
endif

# called by 'define_targets' if it was not properly redefined in 'cb_def_head'
cb_no_def_head_err = $(error $$(cb_def_head) was not evaluated at head of makefile!)

# redefine 'define_targets' macro to produce an error if $(cb_def_head) was not evaluated prior expanding it
# note: the same check is performed in the $(cb_check_at_tail), but it will be done only after expanding templates added by the
#  previous target makefile - this may lead to errors, because templates were not prepared by the previous $(cb_head_eval)
ifdef cb_checking
$(eval define cb_def_tail$(newline)$(subst :=,:=$$(newline)define_targets=$$$$(cb_no_def_head_err),$(value cb_def_tail))$(newline)endef)
endif

# remember new values of 'cb_head_eval' (which was reset to empty) and 'define_targets' (which produces an error),
#  do not trace calls to them: value of 'cb_head_eval' is checked in 'cb_prepare_templ' below
ifdef cb_checking
$(eval define cb_def_tail$(newline)$(subst $(comma)include,$$(newline)$$(call \
  set_global1,cb_head_eval define_targets)$(comma)include,$(value cb_def_tail))$(newline)endef)
endif

# to define rules for building targets - just expand at end of makefile: $(define_targets)
# note: initialize 'define_targets' to produce an error - 'cb_def_head' will reset it to just evaluate $(cb_def_tail)
# note: $(define_targets) must not expand to any text - to allow calling it via just $(define_targets) in target makefiles
define_targets = $(cb_no_def_head_err)

# prepare template of target type (C, Java, etc.) for building (initialize its variables):
# init1->init2...->initN <define variables of target type templates> rulesN->...->rules2->rules1
# $1 - the name of the macro, the expansion of which gives the code for the initialization of target type template variables
# $2 - the name of the macro, the expansion of which gives the code for defining target type rules (by expanding target type template)
# NOTE: if $1 is empty, just evaluate $(cb_def_head), if it wasn't evaluated yet
# NOTE: if $1 is non-empty, expand it now via $(call $1) to not pass any parameters into the expansion
# NOTE: if $1 is non-empty, then $2 must also be non-empty: $1 - init template (now), $2 - expand template (later)
cb_prepare_templ = $(if $(value cb_head_eval),,$(eval $(cb_def_head)))$(if $1,$(eval \
  cb_head_eval=$(value cb_head_eval)$$(eval $$($1)))$(eval \
  define_targets=$$(eval $$($2))$(value define_targets))$(eval $(call $1)))

ifdef set_global

# remember new values of 'cb_head_eval' and 'define_targets'
# note: trace namespaces: def_code
$(eval cb_prepare_templ = $(subst $$$(open_brace)eval $$$(open_brace)call $$1,$$(call \
  set_global,cb_head_eval define_targets,def_code)$$$(open_brace)eval $$$(open_brace)call $$1,$(value cb_prepare_templ)))

# if 'cb_head_eval' and 'define_targets' are traced, get their original values
ifdef cb_tracing

$(eval cb_prepare_templ = $(subst \
  =$$(value cb_head_eval),=$$(call get_global,cb_head_eval),$(value cb_prepare_templ)))

$(eval cb_prepare_templ = $(subst \
  value define_targets,call get_global$(comma)define_targets,$(value cb_prepare_templ)))

endif # cb_tracing

endif # set_global

# ***********************************************

# before $(make_continue): save variables to restore them after (via 'cb_restore_vars' macro)
cb_save_vars = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v)),$v.^s:=$$($v),define $v.^s$(newline)$(value $v)$(newline)endef)$(newline)))

# after $(make_continue): restore variables saved before (via 'cb_save_vars' macro)
cb_restore_vars = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v.^s)),$v:=$$($v.^s),define $v$(newline)$(value $v.^s)$(newline)endef)$(newline)))

# reset %.^s variables
# note: 'cb_reset_saved_vars' - defined in $(cb_dir)/core/protection.mk
ifdef cb_reset_saved_vars
$(eval cb_restore_vars = $(subst \
  $(close_brace)$(close_brace)$(close_brace),$(close_brace)$(close_brace)$$(cb_reset_saved_vars)$(close_brace),$(value \
  cb_restore_vars)))
endif

# use $(make_continue) to define more than one targets in a single makefile
# note: all target rules are defined by the same set of templates included before $(make_continue)
# example:
#
# include $(top)/make/c.mk
# lib  := lib1
# my_c := src1.c
# src  := $(my_c)
# $(make_continue,my_c)
# include $(top)/make/java.mk
# jar  := jar1
# jsrc := j1.java
# lib  := lib2
# src  := src2.c $(my_c)
# ...
# $(define_targets)

# $(make_continue) is equivalent of: ... cb_make_cont+=2 $(TAIL) cb_make_cont=$(subst 2,1,$(cb_make_cont)) $(HEAD) ...
# $1 - names of "local" variables to pass through $(make_continue) - all "local" variables are reset by default in $(define_targets)
# 1) increment cb_make_cont
# 2) evaluate tail code with $(define_targets)
# 3) start next round - simulate including of appropriate $(top)/make/c.mk or $(top)/make/java.mk or whatever by evaluating
#   head-code $(cb_head_eval) - which was likely adjusted by $(top)/make/c.mk or $(top)/make/java.mk or whatever
# note: $(call define_targets) with empty arguments list to not pass any to 'cb_def_tail'
# note: $(call cb_head_eval) with empty arguments list to not pass any to 'cb_def_head'
# note: $(make_continue) must not expand to any text - to be able to call it with just $(make_continue) in target makefile
make_continue = $(if $1,$(cb_save_vars))$(eval cb_make_cont+=2)$(call define_targets)$(call cb_head_eval)$(if $1,$(cb_restore_vars))

# remember new value of 'cb_make_cont' (without tracing calls to it)
ifdef cb_checking
$(eval make_continue = $(subst $$(call define_targets),$$(call set_global,cb_make_cont)$$(call define_targets),$(value make_continue)))
endif

# ========== functions ==========

# for UNIX: don't change paths when converting from make internal file path to path accepted by $(utils_mk)
# note: $(cb_dir)/utils/cmd.mk included below redefines ospath
ospath = $1

# make path not relative: add prefix $1 only to non-absolute paths in $2
# note: path prefix $1 must end with /
# note: $(cb_dir)/utils/cmd.mk included below redefines nonrelpath
nonrelpath = $(patsubst $1/%,/%,$(addprefix $1,$2))

# add absolute path to directory of target makefile to given non-absolute paths
# - we need absolute paths to sources to work with generated dependencies in .d files
fixpath = $(abspath $(call nonrelpath,$(dir $(cb_target_makefile)),$1))

# SED - stream editor executable, should be defined in $(utils_mk) makefile
# 'sed_expr' - should also be defined in $(utils_mk) makefile
# this helper macro: convert multi-line sed script $1 to multiple sed expressions - one expression for each line of the script
sed_multi_expr = $(foreach s,$(subst $(newline), ,$(unspaces)),-e $(call sed_expr,$(call tospaces,$s)))

# define shell utilities
include $(utils_mk)

# if $(CBLD_CONFIG) was included, show it
# note: $(cb_dir)/utils/cmd.mk redefines 'cb_colorize' macro defined in $(cb_dir)/core/suppress.mk, so show $(CBLD_CONFIG)
#  _after_ including $(utils_mk)
ifndef verbose
ifneq (,$(filter $(CBLD_CONFIG),$(MAKEFILE_LIST)))
CBLD_CONF_COLOR ?= [1;32m
$(info $(call cb_print_percents,use)$(if $(cb_infomf),$(cb_target_makefile):)$(call cb_colorize,CONF,$(CBLD_CONFIG)))
endif
endif

# utilities colors - for 'suppress' function (and 'cb_colorize' macro)
CBLD_GEN_COLOR   ?= [1;32m
CBLD_MGEN_COLOR  ?= [1;32m
CBLD_CP_COLOR    ?= [1;36m
CBLD_RM_COLOR    ?= [1;31m
CBLD_RMDIR_COLOR ?= [1;31m
CBLD_MKDIR_COLOR ?= [36m
CBLD_TOUCH_COLOR ?= [36m
CBLD_CAT_COLOR   ?= [32m
CBLD_SED_COLOR   ?= [32m

# product version in form major.minor or major.minor.patch
# Note: this is the default value of 'modver' variable - per-module version number
product_version := 0.0.1

# CBLD_NO_DEPS - if defined, then do not generate auto-dependencies or process or delete previously generated auto-dependencies
# note: by default, do not generate auto-dependencies for release builds
ifeq (undefined,$(origin CBLD_NO_DEPS))
CBLD_NO_DEPS := $(if $(debug),,1)
endif

# remember value of CBLD_NO_DEPS - it may be taken from the environment
$(call config_remember_vars,CBLD_NO_DEPS)

# makefile parsing first phase variables
# Note: bin_dir/obj_dir/lib_dir/gen_dir change their values depending on the value of 'tool_mode' variable set in the last
#  parsed makefile, so clear these variables before rule execution second phase
cb_first_phase_vars += cb_needed_dirs build_system_goals bin_dir obj_dir lib_dir gen_dir order_deps cb_set_sefault_dirs \
  cb_tool_override_dirs toclean add_mdeps cb_add_what_makefile_builds set_makefile_info add_order_deps need_gen_dirs \
  std_target_vars1 cb_check_generated_at std_target_vars add_generated add_generated_ret is_tool_mode \
  cb_tool_mode_access_error tool_mode cb_include_level cb_target_makefiles cb_head_eval cb_make_cont cb_def_head \
  cb_def_tail define_targets cb_prepare_templ cb_save_vars cb_restore_vars make_continue

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,MAKEFLAGS SHELL cb_needed_dirs cb_first_phase_vars CBLD_TARGET CBLD_OS CBLD_TCPU CBLD_CPU CBLD_UTILS \
  cb_mdebug build_system_goals no_clean_build_distclean_goal debug cb_to_clean order_deps cb_include_level cb_target_makefiles \
  cb_make_cont CBLD_CONF_COLOR CBLD_GEN_COLOR CBLD_MGEN_COLOR CBLD_CP_COLOR CBLD_RM_COLOR CBLD_RMDIR_COLOR CBLD_MKDIR_COLOR \
  CBLD_TOUCH_COLOR CBLD_CAT_COLOR CBLD_SED_COLOR CBLD_NO_DEPS)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: core
$(call set_global,cb_project_vars clean_build_version cb_dir clean_build_required_version \
  cb_build project_supported_targets utils_mk target_triplet def_bin_dir def_obj_dir def_lib_dir def_gen_dir \
  cb_set_sefault_dirs tool_base mk_tools_dir cb_tool_override_dirs tool_suffix get_tools get_tool cb_target_makefile \
  add_mdeps cb_add_what_makefile_builds set_makefile_info add_order_deps=order_deps=order_deps \
  need_gen_dirs std_target_vars1 cb_check_generated_at std_target_vars add_generated add_generated_ret \
  is_tool_mode cb_tool_mode_access_error cb_def_head cb_check_targets cb_def_tail cb_no_def_head_err define_targets \
  cb_prepare_templ cb_save_vars cb_restore_vars make_continue ospath nonrelpath fixpath sed_multi_expr product_version,core)

# if 'toclean' value is non-empty, allow tracing calls to it (with trace namespace: toclean),
# else - just protect 'toclean' from changes, do not make it's value non-empty - because 'toclean' is checked in ifdefs
ifndef toclean
$(call set_global,toclean)
else
$(call set_global,toclean==cb_to_clean,toclean)
endif

# auxiliary macros
include $(cb_dir)/core/nonpar.mk
include $(cb_dir)/core/multi.mk
include $(cb_dir)/core/runtool.mk
