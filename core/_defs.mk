#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic rules and definitions for building targets,
#  defines constants, such as: CBLD_TARGET, CBLD_TOOL_TARGET, CBLD_OS, CBLD_BCPU, CBLD_TCPU, CBLD_CPU
#  different core macros, e.g.: 'toclean', 'add_generated', 'is_tool_mode', 'define_targets', 'make_continue', 'fixpath',
#  'ospath' and many more

# Note.
#  Any variable defined in the environment or command line by default is exported to sub-processes spawned by make.
#  Because it's not known in advance which variables are defined in the environment, it is possible to accidentally
#   change values of the environment variables due to collisions of the variable names in makefiles.
#  To reduce the probability of collisions of the names, use the unique variable names in makefiles whenever possible.

# Conventions:
#  1) variables in lower case are always initialized with default values and _never_ taken from the environment
#  2) clean-build internal core macros are prefixed with 'cb_' (except some common names, possibly redefined for the project)
#  3) user variables and parameters for build templates should also be in lower case
#  4) variables in UPPER case _may_ be taken from the environment or command line
#  5) clean-build specific variables that may be taken from the environment are in UPPER case and prefixed with 'CBLD_'
#  6) default values for variables from the environment should be set via operator ?= - to not override values passed to sub-processes
#  7) ifdef/ifndef should only be used with previously initialized (possibly by empty values) variables
#  8) variables with suffix defined by regexp .^[a-z]? are reserved for internal use by clean-build

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
# - it's better to specify these flags in the command line, e.g.:
# $ make -rR --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules --no-builtin-variables --warn-undefined-variables

# drop make's default legacy rules - we'll use only custom ones
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
#  - save list of those variables to redefine them below with 'override' keyword
# note: CBLD_CONFIG and CBLD_BUILD variables are used by clean-build only before including target makefiles, so
#  do not add 'override' attribute to them to protect from changes in target makefiles
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
cb_project_vars := $(strip $(foreach =,$(filter-out SHELL MAKEFLAGS CURDIR MAKEFILE_LIST MAKECMDGOALS .DEFAULT_GOAL \
  %.^e CBLD_CONFIG CBLD_BUILD,$(.VARIABLES)),$(if $(findstring file,$(origin $=)),$=)))

# clean-build version: major.minor.patch
clean_build_version := 0.9.2

# clean-build root directory
# note: a project normally uses its own variable with the same value (e.g. CBLD_ROOT) for referencing clean-build files
cb_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))..)

# include functions library
# note: assume project configuration makefile will not try to override macros defined in $(cb_dir)/core/functions.mk,
#  but if it's absolutely needed, it is possible to do so using 'override' keyword
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

# required variable: CBLD_BUILD - directory of built artifacts - must be defined prior including this makefile
# note: $(cb_build) - must be an absolute path for checks in included next $(cb_dir)/core/confsup.mk
cb_build := $(abspath $(CBLD_BUILD))

ifndef cb_build
$(error CBLD_BUILD - path to directory of built artifacts is not defined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(cb_build)))
$(error CBLD_BUILD='$(cb_build)', path to directory of built artifacts must not contain spaces)
endif

ifeq (,$(notdir $(cb_build)))
$(error CBLD_BUILD='$(cb_build)', path to directory of built artifacts cannot be root)
endif

# needed build directories - clean-build will define rules to create them in $(cb_dir)/core/all.mk
# note: 'cb_needed_dirs' contains $(cb_build)-relative simple paths, like $(target_triplet)/a/b, $(cb_tools_subdir)/1/2/3 and so on
# note: 'cb_needed_dirs' list is never cleared, only appended
cb_needed_dirs:=

# add support for generation of $(CBLD_CONFIG) configuration makefile as result of predefined 'config' goal,
#  adjust values of 'cb_project_vars' and 'project_exported_vars' variables, define 'config_remember_vars' macro
include $(cb_dir)/core/confsup.mk

# clean-build always resets non-environment variables by setting default values, to override these defaults by ones
#  specified in the project configuration makefile, here use 'override' directive
$(foreach =,$(cb_project_vars),$(eval override $(if $(findstring simple,$(flavor \
  $=)),$$=:=$$($$=),$(call define_multiline,$$=,$(value $=)))))

# include variables protection module - define 'cb_checking', 'cb_tracing', 'set_global', 'get_global', 'env_remember' and other macros
# protect from changes project variables - which have 'override' $(origin) and exported variables in 'project_exported_vars' list
include $(cb_dir)/core/protection.mk

# autoconfigure values of: CBLD_OS, CBLD_BCPU, CBLD_CPU, CBLD_TCPU, CBLD_UTILS
# define 'utils_mk' - makefile with definitions of shell utilities (included below)
include $(cb_dir)/core/aconf.mk

# list of project-supported target/tool target types
# note: normally these defaults are overridden in the project configuration makefile
project_supported_targets      := RELEASE DEBUG
project_supported_tool_targets := RELEASE DEBUG

# what target/tool target type to build (RELEASE, DEBUG, PROJECT_DEBUG, etc.) - must be a value from
#  $(project_supported_targets)/$(project_supported_tool_targets) lists
# note: normally CBLD_TARGET/CBLD_TOOL_TARGET are overridden by specifying them in the command line
ifeq (undefined,$(origin CBLD_TARGET))
CBLD_TARGET := $(firstword $(project_supported_targets))
endif
ifeq (undefined,$(origin CBLD_TOOL_TARGET))
CBLD_TOOL_TARGET := $(firstword $(project_supported_tool_targets))
endif

# run via "$(MAKE) D=1" to debug makefiles
ifeq (command line,$(origin D))
cb_mdebug := $(D:0=)
else
# don't debug makefiles by default
cb_mdebug:=
endif

# show sensible variables
ifdef cb_mdebug
$(call dump_vars,CBLD_BUILD CBLD_CONFIG CBLD_TARGET CBLD_TOOL_TARGET \
  CBLD_OS CBLD_BCPU CBLD_CPU CBLD_TCPU CBLD_UTILS cb_dir cb_build utils_mk)
endif

# list of build system supported goals
# note: this list may be amended in makefiles processed later
build_system_goals := all config clean check tests

# 'no_clean_build_distclean_goal' may be set to non-empty value in the project configuration makefile to avoid clean-build definition
#  of 'distclean' goal
no_clean_build_distclean_goal:=

ifndef no_clean_build_distclean_goal
build_system_goals += distclean
endif

# check that CBLD_TARGET/CBLD_TOOL_TARGET are correctly defined only if goal is not 'distclean' (they are not needed for 'distclean')
ifeq (,$(filter distclean,$(MAKECMDGOALS)))

# what target/tool target type to build
ifeq (,$(filter $(CBLD_TARGET),$(project_supported_targets)))
$(error unknown CBLD_TARGET=$(CBLD_TARGET), please pick one of: $(project_supported_targets))
endif
ifeq (,$(filter $(CBLD_TOOL_TARGET),$(project_supported_tool_targets)))
$(error unknown CBLD_TOOL_TARGET=$(CBLD_TOOL_TARGET), please pick one of: $(project_supported_tool_targets))
endif

else # distclean

ifneq (,$(word 2,$(MAKECMDGOALS)))
$(error 'distclean' goal must be specified alone, current goals: $(MAKECMDGOALS))
endif

ifndef no_clean_build_distclean_goal

# define 'distclean' goal - delete all built artifacts, including directories
# note: 'sh_rm_some_dirs' macro is defined in included below $(utils_mk) makefile
distclean:
	$(quiet)$(call sh_rm_some_dirs,$(cb_build))

endif # !no_clean_build_distclean_goal

endif # distclean

# non-empty if cleaning up built files or directories
cleaning := $(filter clean distclean,$(MAKECMDGOALS))

# define 'verbose' and 'quiet' constants, 'suppress' function and other macros
include $(cb_dir)/core/suppress.mk

# if $(CBLD_CONFIG) makefile was included, show it
# note: 'cb_infomf' - defined in $(cb_dir)/core/suppress.mk
ifndef verbose
ifneq (,$(filter $(CBLD_CONFIG),$(MAKEFILE_LIST)))
CBLD_CONF_COLOR ?= [1;32m
$(info $(call cb_print_percents,use)$(if $(cb_infomf),$(cb_target_makefile):)$(call cb_show_tool,CONF,$(CBLD_CONFIG)))
endif
endif

# to simplify target makefiles, define 'debug' variable:
#  $(debug) is non-empty for debugging targets like "DEBUG" or "PROJECT_DEBUG"
# note: define 'debug' assuming that we are not in the "tool" mode
debug := $(filter DEBUG %_DEBUG,$(CBLD_TARGET))

# 'debug' variable is redefined in the "tool" mode and restored in non-"tool" mode
cb_set_default_vars   := debug:=$(debug)
cb_tool_override_vars := debug:=$(filter DEBUG %_DEBUG,$(CBLD_TOOL_TARGET))

# note: do not trace access to 'debug' variable - it may be used in ifdefs
ifdef cb_checking
cb_set_default_vars   := $(cb_set_default_vars)$(newline)$(call set_global1,debug)
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)$(call set_global1,debug)
endif

# define macros: 'o_ns', 'o_path', 'get_tool_dir', 'get_tools', 'get_deps'
include $(cb_dir)/core/o_path.mk

# 'toclean' - function to add files/directories to delete to 'cb_to_clean' list
# $1 - target, whose built files/directories need to delete, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - built files/directories of the target $1 to delete, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/file.txt
ifndef cleaning

# do nothing if not cleaning up
cb_to_clean_add:=

ifndef cb_checking
toclean:=
else
toclean = $(if $(cb_check_vpath_r),$(call cb_check_vpaths,$2),$(if $2,$(error toclean: target is not specified)))
endif

else ifneq (,$(word 2,$(MAKECMDGOALS)))

$(error 'clean' goal must be specified alone, current goals: $(MAKECMDGOALS))

else # cleaning

# 'cb_to_clean' - list of $(cb_build)-relative paths to files/directories to recursively delete on "$(MAKE) clean"
# note: this list is never cleared, only appended - via 'cb_to_clean_add' macro
# note: 'cb_to_clean' variable should not be directly accessed/modified in target makefiles
cb_to_clean:=

ifndef cb_checking

cb_to_clean_add = $(eval cb_to_clean+=$$1)
toclean = $(call cb_to_clean_add,$(addprefix $(patsubst $(cb_build)/%,%,$(o_ns))/,$2))

else # cb_checking

# remember new value of 'cb_to_clean' list, without tracing calls to it because it's incremented
cb_to_clean_add = $(eval cb_to_clean+=$$1$(newline)$(call set_global1,cb_to_clean))
toclean = $(if $(cb_check_vpath_r),$(call cb_to_clean_add,$(addprefix $(patsubst $(cb_build)/%,%,$(o_ns))/,$(call \
  cb_check_vpaths_r,$2))),$(if $2,$(error toclean: target is not specified)))

endif # cb_checking

endif # cleaning

# define macros: 'assoc_dirs', 'deploy_files_from', 'deploy_files', 'deploy_dirs'
include $(cb_dir)/core/deploy.mk

# define macros:
#  'need_built_files_from', 'need_built_files', 'need_tool_files', 'need_built_dirs', 'need_tool_dirs', 'need_tool_execs',
#  'get_tool_execs', 'get_dep_dir_tags', 'get_tool_dir_tags
include $(cb_dir)/core/need.mk

# path to the root target makefile the build was started from
# note: when building from the command line one of out-of-project tree external modules, such as $(cb_dir)/extensions/version/Makefile,
#  which cannot include project configuration makefiles directly (because external modules are project-independent), 'cb_first_makefile'
#  variable may be auto-set to a wrong value (not a target makefile), so it may be required to override 'cb_first_makefile' in the command
#  line explicitly, e.g.:
# $ make cb_first_makefile=/opt/clean-build/extensions/version/Makefile \
#   --eval="include ./examples/hello/make/c_project.mk" -f /opt/clean-build/extensions/version/Makefile
cb_first_makefile := $(firstword $(MAKEFILE_LIST))

# absolute path to current target makefile
# note: this variable is redefined by clean-build for each processed target makefile
# note: path must be absolute - there could be only one .PHONY target '$(cb_first_makefile)-' per target makefile
cb_target_makefile := $(abspath $(cb_first_makefile))

# append makefiles (really .PHONY targets created from them) to 'order_deps' list - see below
# note: this function is useful to add dependency on all targets built by the specified makefiles (a tree of makefiles) to targets
#  of current makefile
# note: argument $1 - list of makefiles (or directories, where "Makefile" file is searched)
# note: overridden in $(cb_dir)/core/_submakes.mk
add_mdeps:=

# for targets $1, define target-specific variable - used by 'suppress' function in "makefile info" mode (enabled via "$(MAKE) M=1"):
# C.^ - makefile which specifies how to build the targets and a number of section in the makefile after a call to $(make_continue)
# note: do not call this macro for targets registered via 'cb_target_vars'/'add_generated' - they call 'set_makefile_info' implicitly
# note: 'set_makefile_info' does nothing in non-"makefile info" mode
# note: it is possible to call this macro only for a root target (e.g. a lib), dependent targets (e.g. objs) will inherit target-specific
#  variable C.^ from the root (lib). The root must be one - if there are many, target-specific variable may be inherited from any of them.
set_makefile_info:=

# same as 'set_makefile_info', but return passed targets $1
set_makefile_info_r = $1

# patch given evaluable template - to print (in "makefile debug" mode - enabled via "$(MAKE) D=1") what targets current makefile builds
# $1 - template name
# $2 - expression that gives list of targets the template builds
# $3 - optional expression that gives order-only dependencies of the targets
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating expansion result
cb_add_what_makefile_builds:=

ifndef cleaning

# define a .PHONY goal which will depend on main targets (registered via 'cb_target_vars' macro - defined below)
.PHONY: $(cb_target_makefile)-

# default goal 'all' - depends only on a root target makefile (a .PHONY goal)
all: $(cb_target_makefile)-

# order-only dependencies of all leaf makefile targets
# note: 'order_deps' variable should not be directly modified in target makefiles, use 'add_order_deps/add_mdeps' functions to append
#  value(s) to 'order_deps'
order_deps:=

# append values to 'order_deps' list
ifndef cb_checking
add_order_deps = $(eval order_deps+=$$1)
else
# remember new value of 'order_deps', without tracing calls to it because it's incremented
add_order_deps = $(eval order_deps+=$$1$(newline)$(call set_global1,order_deps))
endif

# $1 - target which needs directories, absolute path,       e.g.: /build/tt/a/b/c@-/tt/a/b/c
# $2 - needed directories by the target $1, absolute paths, e.g.: /build/tt/a/b/c@-/tt/x/y/z
define create_dirs2
$1:| $2
cb_needed_dirs+=$(patsubst $(cb_build)/%,%,$2)
endef

# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
ifdef cb_checking
$(call define_append,create_dirs2,$(newline)$$(call set_global1,cb_needed_dirs))
endif

# $1 - target which needs the directories, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - directories, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/gg2
# $3 - namespace directory of the target: $(call o_ns,$1), e.g. /build/tt/gen/file.txt@-
create_dirs1 = $(call create_dirs2,$3/$1,$(addprefix $3/,$2))

# add directories to the list of auto-created ones for a given target
# $1 - target which needs the directories, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - directories, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/gg2
# note: these directories are will be auto-deleted while cleaning up
# note: callers of 'create_dirs' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here.
ifndef cb_checking
create_dirs = $(eval $(call create_dirs1,$1,$2,$(o_ns)))
else
create_dirs = $(if $(cb_check_vpath_r),$(eval $(call create_dirs1,$1,$(call \
  cb_check_vpaths_r,$2),$(o_ns))),$(if $2,$(error create_dirs: target is not specified)))
endif

# $1 - target files to build (absolute paths)
# $2 - directories of target files - $(cb_build)-relative simple paths: $(patsubst $(cb_build)/%/,%,$(dir $1))
# note: postpone expansion of $(order_deps) to optimize parsing
define cb_target_vars2
$1:| $$(order_deps)
$(subst |,:| $(cb_build)/,$(subst $(space),$(newline),$(join $(1:=|),$2)))
$(cb_target_makefile)-:$1
cb_needed_dirs+=$2
endef

# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
ifdef cb_checking
$(call define_append,cb_target_vars2,$(newline)$$(call set_global1,cb_needed_dirs))
endif

# note: 'suppress' and 'cb_makefile_info' macros - defined in included above $(cb_dir)/core/suppress.mk
# note: 'cb_makefile_info' - defined to non-empty value in "makefile info" mode (enabled via "$(MAKE) M=1")
ifdef cb_makefile_info

# for targets $1, define target-specific variable - used by 'suppress' function in "makefile info" mode:
# C.^ - makefile which specifies how to build the targets and a number of section in the makefile after a call to $(make_continue)
set_makefile_info = $(eval $(value cb_makefile_info))
set_makefile_info_r = $(set_makefile_info)$1

# optimize: do not call 'set_makefile_info' from 'cb_target_vars2', include code of 'set_makefile_info' directly
$(call define_prepend,cb_target_vars2,$(value cb_makefile_info)$(newline))

endif # cb_makefile_info

ifdef cb_mdebug

# show what targets a template builds (prior building them)
# $1 - targets the template builds (absolute paths)
# $2 - optional suffix (e.g. order-only dependencies)
# note: 'cb_colorize' - defined in included above $(cb_dir)/core/suppress.mk
# note: one space after $(call cb_colorize,TARGET,TARGET)
cb_what_makefile_builds = $(info $(call cb_what_makefile_builds1,$1,$2,$(call cb_colorize,TARGET,TARGET) $(is_tool_mode:%=[%]: )))
cb_what_makefile_builds1 = $3$(subst $(space),$2$(newline)$3,$(join $(patsubst $(cb_build)/%,$(call \
  cb_colorize,CB_BUILD,$$(cb_build))/%,$(dir $1)),$(call cb_colorize,TARGET,$(notdir $1))))$2

# for the 'cb_colorize' macro called in 'cb_what_makefile_builds'
CBLD_TARGET_COLOR   ?= [32m
CBLD_CB_BUILD_COLOR ?= [31;1m

# fix template to print (while evaluating the template) what targets current makefile builds
# $1 - template name
# $2 - expression that gives targets the template builds (absolute paths)
# $3 - optional expression that gives order-only dependencies of the targets
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating result of the expansion
cb_add_what_makefile_builds = $(call define_prepend,$1,$$(call cb_what_makefile_builds,$2,$(if $3,$$(if $3, | $3))))

# patch 'cb_target_vars2' template - print what targets current makefile builds
$(call cb_add_what_makefile_builds,cb_target_vars2,$$1,$$(order_deps))

endif # cb_mdebug

# register targets - to properly count percent of building targets by the calls to 'suppress' macro
# note: 'suppress_targets_r' - defined in $(cb_dir)/core/suppress.mk
ifndef cleaning
ifdef quiet
$(eval define cb_target_vars2$(newline)$(subst $$1:|,$$(suppress_targets_r):|,$(value cb_target_vars2))$(newline)endef)
endif
endif

# $1 - target files to build (absolute paths), e.g.: /build/tt/a/b/c@-/tt/a/b/c
cb_target_vars_a = $(call cb_target_vars2,$1,$(patsubst $(cb_build)/%/,%,$(dir $1)))

else # ---------------------- cleaning ---------------------

# just delete (recursively, with all content) generated directories
# $1 - target which needs the directories, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - directories, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/gg2
create_dirs = $(toclean)

# just delete target files
# $1 - target files to delete (absolute paths), e.g.: /build/tt/a/b/c@-/tt/a/b/c
cb_target_vars_a = $(call cb_to_clean_add,$(patsubst $(cb_build)/%,%,$1))

# note: callers of 'create_dirs' or 'cb_target_vars' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here (do not optimize!).
# remember new value of 'cb_needed_dirs' without tracing calls to it because it is incremented
ifdef cb_checking
$(eval create_dirs = $(value create_dirs)$$(call set_global,cb_needed_dirs))
$(eval cb_target_vars_a = $(value cb_target_vars_a)$$(call set_global,cb_needed_dirs))
endif

# do nothing if cleaning up
add_order_deps:=

endif # cleaning

# register targets as the main ones built by current makefile, add standard target-specific variables
# (main targets - that are not necessarily used as prerequisites for other targets in the same makefile)
# $1 - targets (generated files), must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/22.33
# note: .PHONY target '$(cb_target_makefile)-' will depend on registered main targets in the list $1
# note: callers of 'cb_target_vars' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here.
# note: rules of the targets should contain only one call to 'suppress' macro - to properly update percent of building targets
# note: if a rule consists of multiple commands - use 'suppress_more' macro instead of additional calls to 'suppress' macro
cb_target_vars = $(call cb_target_vars_a,$(o_path))

# same as 'cb_target_vars_a', but add one line containing absolute paths to output files, e.g.: /build/tt/a/b/c@-/tt/a/b/c
cb_target_vars_a_o = $(cb_target_vars_a)$(newline)$1

# same as 'cb_target_vars', but add one line containing absolute paths to output files, e.g.: /build/tt/a/b/c@-/tt/a/b/c
# note: this macro may be used for defining a rule in place, e.g.: $(eval $(call cb_target_vars_o,a/b/c):; <rule>)
cb_target_vars_o = $(call cb_target_vars_a_o,$(o_path))

# same as 'create_dirs', but return target $1 -  simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $1 - target which needs the directories, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - directories, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/gg2
create_dirs_r = $(create_dirs)$1

# same as 'create_dirs', but return absolute paths to generated directories
# $1 - target which needs the directories, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# $2 - directories, must be paths relative to virtual $(out_dir), e.g.: ex/tool1 gen/gg2
create_dirs_o = $(create_dirs)$(addprefix $(o_ns)/,$2)

# add generated files to build sequence
# $1 - generated files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/22.33
# note: directories for generated files will be auto-created
# note: generated files will be auto-deleted while completing the 'clean' goal
# note: rules of the targets should contain only one call to 'suppress' macro - to properly update percent of building targets
# note: if a rule consists of multiple commands - use 'suppress_more' macro instead of additional calls to 'suppress' macro
add_generated = $(eval $(cb_target_vars))

# do the same as 'add_generated', but also return list of generated files $1 - simple paths relative to virtual $(out_dir)
# $1 - generated files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/22.33
add_generated_r = $(add_generated)$1

# $1 - absolute paths to generated files
cb_add_generated_a_o = $(eval $(cb_target_vars_a))$1

# do the same as 'add_generated', but also return absolute paths to generated files $1
# $1 - generated files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/22.33
add_generated_o = $(call cb_add_generated_a_o,$(o_path))

# 'tool_mode' may be set to non-empty value (likely T) at the beginning of target makefile
#  (before including this file and so before evaluating $(cb_def_head))
# if 'tool_mode' is not set - reset it - we are not in the "tool" mode
# else - check its value while evaluation of 'cb_def_head'
ifneq (file,$(origin tool_mode))
tool_mode:=
endif

# non-empty (e.g. T) in the "tool" mode - 'tool_mode' variable was set to that value prior evaluating $(cb_def_head), empty in normal mode.
# note: 'tool_mode' variable should not be used in rule templates - use $(is_tool_mode) instead, because 'tool_mode' may be set to another
#  value anywhere before $(make_continue), and so before the evaluation of rule templates.
# reset the value: we are currently not in the "tool" mode
is_tool_mode:=

# code to evaluate at the beginning of target makefile to adjust variables for "tool" mode
# note: set 'is_tool_mode' variable to remember if we are in the "tool" mode - 'tool_mode' variable may be set to another value
#  before calling $(make_continue), and this new value will affect only the next sections of $(make_continue)
define cb_tool_mode_adjust
is_tool_mode:=$(tool_mode)
$(if $(tool_mode),$(if \
  $(is_tool_mode),,$(cb_tool_override_vars)),$(if \
  $(is_tool_mode),$(cb_set_default_vars)))
endef

# remember new value of 'is_tool_mode'
# note: trace namespace: is_tool_mode
ifdef set_global1
$(eval define cb_tool_mode_adjust$(newline)$(subst \
  is_tool_mode:=$$(tool_mode),is_tool_mode:=$$(tool_mode)$(newline)$$(call \
  set_global1,is_tool_mode,is_tool_mode),$(value cb_tool_mode_adjust))$(newline)endef)
endif

ifdef cb_checking

# do not allow to read 'tool_mode' variable in target makefiles, only to set it
cb_tool_mode_access_error = $(error please use 'is_tool_mode' variable to check for "tool" mode)

# use 'tool_mode' only to set value of 'is_tool_mode' variable, forbid reading $(tool_mode) in target makefiles
# note: do not trace calls to 'tool_mode' after resetting it to $$(cb_tool_mode_access_error) - this is needed to pass the (next)
#  check if a value of 'tool_mode' is '$(cb_tool_mode_access_error)' (or empty, or non-empty)
$(call define_prepend,cb_tool_mode_adjust,$$(if $$(findstring $$$$(cb_tool_mode_access_error),$$(value tool_mode)),$$(eval \
  tool_mode:=$$$$(is_tool_mode)))tool_mode=$$$$(cb_tool_mode_access_error)$(newline)$$(call set_global1,tool_mode)$(newline))

endif # cb_checking

# variable used to track makefiles include level
cb_include_level:=

# list of all processed target makefiles (absolute paths) - for the check in $(cb_def_head) that one makefile is not processed twice
# note: 'cb_target_makefiles' is never cleared, only appended - in $(cb_def_head)
ifdef cb_checking
cb_target_makefiles:=
endif

# a chain of macros which should be evaluated for preparing target templates (i.e. resetting "local" variables - template parameters)
# $(cb_def_head) was not evaluated yet, the chain is empty (it's checked in 'cb_prepare')
cb_head_eval:=

# initially reset variable holding a number of section of $(make_continue), it is checked in 'cb_def_head'
cb_make_cont:=

# ***********************************************
# code to $(eval ...) at the beginning of each target makefile
# NOTE: $(make_continue) before expanding $(cb_def_head) adds ~ to 'cb_make_cont' list (which is normally empty or contains 1 1...)
#  - so we know if $(cb_def_head) was expanded from $(make_continue) - remove ~ from 'cb_make_cont' list in that case
#  - if $(cb_def_head) was expanded not from $(make_continue) - no ~ in $(cb_make_cont) - reset 'cb_make_cont' variable
define cb_def_head
$(cb_tool_mode_adjust)
ifneq (,$(findstring ~,$(cb_make_cont)))
cb_make_cont:=$$(subst ~,1,$$(cb_make_cont))
else
cb_make_cont:=
cb_head_eval=$$(eval $$(cb_def_head))
cb_def_targets=$$(cb_def_tail)
endif
endef

ifdef cb_mdebug

# show debug info prior defining targets, e.g.: ">>>>/project/one.mk+2"
# note: $(cb_make_cont) contains ~ if inside $(make_continue)
# note: 'cb_colorize' - defined in included above $(cb_dir)/core/suppress.mk
# note: two spaces after $(call cb_colorize,LEAF,LEAF)
cb_show_leaf_mk = $(info $(call cb_colorize,LEAF,LEAF)  $(call cb_colorize,LEVEL,$(subst \
  $(space),,$(cb_include_level)))$(dir $(cb_target_makefile))$(call cb_colorize,LEAF,$(notdir \
  $(cb_target_makefile)))$(if $(findstring ~,$(cb_make_cont)),+$(words $(cb_make_cont))))

# for the 'cb_colorize' macro called in 'cb_show_leaf_mk'
CBLD_LEAF_COLOR  ?= [33;1m
CBLD_LEVEL_COLOR ?= [36;1m

# show debug info prior defining targets
$(call define_prepend,cb_def_head,$$(cb_show_leaf_mk))

endif # cb_mdebug

ifdef cb_checking

# reset "local" variables, check if $(cb_def_tail) was evaluated after previous $(cb_def_head)
# note: 'cb_check_at_head' - defined in $(cb_dir)/core/protection.mk
$(eval define cb_def_head$(newline)$(subst ifneq,$$(cb_check_at_head)$(newline)ifneq,$(value cb_def_head))$(newline)endef)

# 1) check that $(cb_target_makefile) was not already processed (note: check only before the first $(make_continue))
# 2) add $(cb_target_makefile) to the list of processed target makefiles (note: only before the first $(make_continue) call)
# 3) remember new value of 'cb_target_makefiles' variable, without tracing calls to it because it's incremented
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)$$(if $$(filter $$(cb_target_makefile),$$(cb_target_makefiles)),$$(error \
  makefile $$(cb_target_makefile) was already processed!))cb_target_makefiles+=$$$$(cb_target_makefile)$(newline)$$(call \
  set_global1,cb_target_makefiles),$(value cb_def_head))$(newline)endef)

# check that all target files are built:
#  'cb_target_vars2' template only declares 'phony' targets (without rules), rules for the targets should be defined elsewhere,
#  if a target file does not exist - corresponding rule should create it, but if the rule wasn't defined - a warning will be generated.
# note: this macro must be expanded in $(cb_target_makefile)'s rule body, where automatic variables $@ and $^ are defined
# note: $(wildcard) may return cached results (for existing files)
cb_check_targets = $(foreach =,$(filter-out $(wildcard $^),$^),$(info $(@:-=): warning: file wasn't built: $=))

# after all targets the $(cb_target_makefile) depends on are completed, check that target files are really built
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)$$$$(cb_target_makefile)-:; $$$$(cb_check_targets),$(value cb_def_head))$(newline)endef)

# remember new value of 'cb_make_cont' (without tracing calls to it - it's modified via +=)
$(call define_append,cb_def_head,$(newline)$$(call set_global1,cb_make_cont))

endif # cb_checking

ifdef set_global1

# remember new values of 'cb_head_eval' and 'cb_def_targets'
# note: trace namespace: def_code
$(eval define cb_def_head$(newline)$(subst endif,$$(call \
  set_global1,cb_head_eval cb_def_targets,def_code)$(newline)endif,$(value cb_def_head))$(newline)endef)

# trace (next) calls to 'tool_mode' if not checking makefiles, else - 'tool_mode' is protected in 'cb_tool_mode_adjust'
# note: trace namespace: tool_mode
ifndef cb_checking
$(call define_prepend,cb_def_head,$$(call set_global1,tool_mode,tool_mode)$(newline))
endif

endif # set_global1

# ***********************************************
# code to $(eval ...) at the end of each target makefile
# include $(cb_dir)/core/all.mk only if $(cb_include_level) is empty and not inside a call of $(make_continue)
# note: $(make_continue) before expanding $(cb_def_tail) adds ~ to 'cb_make_cont' list
cb_def_tail = $(if $(findstring ~,$(cb_make_cont)),,$(if $(cb_include_level),cb_head_eval:=,include $(cb_dir)/core/all.mk))

# prepend 'cb_def_tail' with $(cb_check_at_tail) - it's defined in $(cb_dir)/core/protection.mk
ifdef cb_checking
$(call define_prepend,cb_def_tail,$$(cb_check_at_tail)$(newline))
endif

# called by 'cb_def_targets' if it was not properly redefined in 'cb_def_head'
cb_no_def_head_err = $(error $$(cb_def_head) was not evaluated at head of makefile!)

# 1) redefine 'cb_def_targets' macro to produce an error if $(cb_def_head) was not evaluated prior expanding it
# note: the same check is performed in $(cb_check_at_tail), but it will be done only after expanding templates added by the
#  previous target makefile - this may lead to errors, because templates were not prepared by the previous $(cb_head_eval)
# 2) remember new values of 'cb_head_eval' (which was reset to empty) and 'cb_def_targets' (which produces an error),
#  do not trace calls to them: value of 'cb_head_eval' is checked in 'cb_prepare' below, 'cb_def_targets' already produces an error
ifdef cb_checking
$(eval define cb_def_tail$(newline)$(subst :=,:=$$(newline)cb_def_targets=$$$$(cb_no_def_head_err)$$(newline)$$(call \
  set_global1,cb_head_eval cb_def_targets),$(value cb_def_tail))$(newline)endef)
endif

# initialize 'cb_def_targets' to produce an error - 'cb_def_head' will reset it to just expand $(cb_def_tail)
cb_def_targets = $(cb_no_def_head_err)

# to define rules for building targets - just expand at end of makefile: $(define_targets)
# note: $(define_targets) must not expand to any text - to allow calling it via just $(define_targets) in target makefiles
# note: result of expansion of $(cb_def_targets) contains a code that redefines 'cb_def_targets' macro - this code must not be
#  evaluated while expanding 'cb_def_targets' - Gnu Make 3.81 doesn't like this, evaluate that code here
define_targets = $(eval $(cb_def_targets))

# prepare template of target type (C, Java, etc.) for building (initialize its variables):
# init1->init2...->initN <define variables of target type templates> rulesN->...->rules2->rules1
# $1 - name of a macro, expansion of which gives a code for initialization of target type template variables
# $2 - name of a macro, expansion of which gives a code for defining target type rules (by expanding target type template)
# NOTE: if $1 is empty, just evaluate $(cb_def_head), if it wasn't evaluated yet
# NOTE: if $1 is non-empty, expand it now via $(call $1) - without arguments - to not pass any parameters into the expansion
# NOTE: if $1 is non-empty, then $2 must also be non-empty: $1 - init template (now), $2 - expand template (later)
cb_prepare = $(if $(value cb_head_eval),,$(eval $(cb_def_head)))$(if $1,$(eval \
  cb_head_eval=$(value cb_head_eval)$$(eval $$($1)))$(eval \
  cb_def_targets=$$(eval $$($2))$(value cb_def_targets))$(eval $(call $1)))

ifdef set_global

# remember new values of 'cb_head_eval' and 'cb_def_targets'
# note: trace namespaces: def_code
$(eval cb_prepare = $(subst $$$(open_brace)eval $$$(open_brace)call $$1,$$(call \
  set_global,cb_head_eval cb_def_targets,def_code)$$$(open_brace)eval $$$(open_brace)call $$1,$(value cb_prepare)))

# if 'cb_head_eval' and 'cb_def_targets' are traced, get their original values
ifdef cb_tracing
$(eval cb_prepare = $(subst =$$(value cb_head_eval),=$$(call get_global,cb_head_eval),$(value cb_prepare)))
$(eval cb_prepare = $(subst value cb_def_targets,call get_global$(comma)cb_def_targets,$(value cb_prepare)))
endif # cb_tracing

endif # set_global

# ***********************************************

# before $(make_continue): save variables to restore them after (via 'cb_restore_vars' macro)
cb_save_vars = $(foreach v,$1,$(eval \
  $(if $(findstring simple,$(flavor $v)),$$v.^s:=$$($$v),$(call define_multiline,$$v.^s,$(value $v)))))

# after $(make_continue): restore variables saved before (via 'cb_save_vars' macro)
cb_restore_vars = $(foreach v,$1,$(eval \
  $(if $(findstring simple,$(flavor $v.^s)),$$v:=$$($$v.^s),$(call define_multiline,$$v,$(value $v.^s)))))

# reset %.^s variables
# note: 'cb_reset_saved_vars' - defined in $(cb_dir)/core/protection.mk
ifdef cb_checking
$(eval cb_restore_vars = $(value cb_restore_vars)$$(eval $$(cb_reset_saved_vars)))
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

# $(make_continue) is equivalent of: ... cb_make_cont+=~ $(TAIL) cb_make_cont=$(subst ~,1,$(cb_make_cont)) $(HEAD) ...
# $1 - names of "local" variables to pass through $(make_continue) - all "local" variables are reset by default in $(cb_head_eval)
# 1) increment cb_make_cont
# 2) evaluate tail code with $(define_targets)
# 3) start next round - simulate including of appropriate $(top)/make/c.mk or $(top)/make/java.mk or whatever by evaluating
#   head-code $(cb_head_eval) - which was likely adjusted by $(top)/make/c.mk or $(top)/make/java.mk or whatever
# note: $(call define_targets) with empty arguments list to not pass any to 'cb_def_tail'
# note: $(call cb_head_eval) with empty arguments list to not pass any to 'cb_def_head'
# note: $(make_continue) must not expand to any text - to be able to call it with just $(make_continue) in target makefile
make_continue = $(if $1,$(cb_save_vars))$(eval cb_make_cont+=~)$(call define_targets)$(call cb_head_eval)$(if $1,$(cb_restore_vars))

# remember new value of 'cb_make_cont' (without tracing calls to it)
ifdef cb_checking
$(eval make_continue = $(subst ~,~$$(newline)$$(call set_global1,cb_make_cont),$(value make_continue)))
endif

# define functions: 'fixpath', 'ospath', 'ifaddq', 'path_unspaces', 'qpath' and 'gmake_path'
include $(cb_dir)/core/path.mk

# define 'run_tool' macro
# note: included below $(utils_mk) (e.g. $(cb_dir)/utils/cmd.mk) may override some of macros defined in this $(cb_dir)/core/runtool.mk
include $(cb_dir)/core/runtool.mk

# define shell utilities
# note: $(cb_dir)/utils/cmd.mk overrides macros defined in $(cb_dir)/core/runtool.mk: 'pathsep', 'show_tool_vars', 'show_tool_vars_end'
include $(utils_mk)

# remember values of variables possibly taken from the environment
# note: CBLD_BUILD - initialized in the project configuration makefile - $(cb_dir)/stub/project.mk
$(call config_remember_vars,CBLD_BUILD CBLD_TARGET CBLD_TOOL_TARGET)

# makefile parsing first phase variables
# Note: 'debug' variable change its value depending on the value of 'tool_mode' variable set in the last
#  parsed makefile, so clear this variables before rule execution second phase
cb_first_phase_vars += cb_needed_dirs build_system_goals debug cb_set_default_vars cb_tool_override_vars cb_to_clean_add \
  toclean order_deps cb_target_makefile add_mdeps set_makefile_info set_makefile_info_r cb_add_what_makefile_builds \
  add_order_deps create_dirs2 create_dirs1 create_dirs cb_target_vars2 cb_what_makefile_builds cb_what_makefile_builds1 \
  cb_target_vars_a cb_target_vars cb_target_vars_a_o cb_target_vars_o create_dirs_r create_dirs_o add_generated add_generated_r \
  cb_add_generated_a_o add_generated_o tool_mode is_tool_mode cb_tool_mode_adjust cb_tool_mode_access_error cb_include_level \
  cb_target_makefiles cb_head_eval cb_make_cont cb_def_head cb_show_leaf_mk cb_def_tail cb_no_def_head_err cb_def_targets \
  define_targets cb_prepare cb_save_vars cb_restore_vars make_continue

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,MAKEFLAGS SHELL cb_needed_dirs cb_first_phase_vars CBLD_BUILD CBLD_TARGET CBLD_TOOL_TARGET \
  cb_mdebug build_system_goals no_clean_build_distclean_goal cleaning debug cb_to_clean order_deps CBLD_TARGET_COLOR \
  CBLD_CB_BUILD_COLOR cb_include_level cb_target_makefiles cb_make_cont CBLD_LEAF_COLOR CBLD_LEVEL_COLOR CBLD_CONF_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: core
$(call set_global,cb_project_vars clean_build_version cb_dir clean_build_required_version cb_build \
  project_supported_targets project_supported_tool_targets cb_set_default_vars cb_tool_override_vars \
  cb_to_clean_add==cb_to_clean toclean cb_first_makefile cb_target_makefile add_mdeps set_makefile_info set_makefile_info_r \
  cb_add_what_makefile_builds add_order_deps=order_deps=order_deps create_dirs2 create_dirs1 create_dirs cb_target_vars2 \
  cb_what_makefile_builds cb_what_makefile_builds1 cb_target_vars_a cb_target_vars cb_target_vars_a_o cb_target_vars_o \
  create_dirs_r create_dirs_o add_generated add_generated_r cb_add_generated_a_o add_generated_o is_tool_mode cb_tool_mode_adjust \
  cb_tool_mode_access_error cb_def_head cb_show_leaf_mk cb_check_targets cb_def_tail cb_no_def_head_err cb_def_targets \
  define_targets cb_prepare cb_save_vars cb_restore_vars make_continue,core)

# define auxiliary macros: 'non_parallel_execute', 'multi_target' and 'multi_target_r'
include $(cb_dir)/core/nonpar.mk
include $(cb_dir)/core/multi.mk
