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
#  - save list of those variables to redefine them below with the 'override' keyword
# note: CBLD_CONFIG and CBLD_BUILD variables are used by the clean-build only before including target makefiles, so
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
#  but if it's absolutely needed, it is possible to do so using the 'override' keyword
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
# note: must be an absolute path for the checks in included next $(cb_dir)/core/confsup.mk
cb_build := $(abspath $(CBLD_BUILD))

ifndef cb_build
$(error CBLD_BUILD - path to directory of built artifacts is not defined, example: C:/opt/project/build or /home/oper/project/build)
endif

ifneq (,$(findstring $(space),$(cb_build)))
$(error CBLD_BUILD='$(cb_build)', path to directory of built artifacts must not contain spaces)
endif

# needed directories other than $(cb_build) - clean-build will define rules to create them in $(cb_dir)/core/all.mk
# note: 'cb_needed_dirs' contains $(cb_build)-relative simple paths, like a/b, 1/2/3 and so on
# note: 'cb_needed_dirs' is never cleared, only appended
cb_needed_dirs:=

# add support for generation of $(CBLD_CONFIG) configuration makefile as result of predefined 'config' goal,
#  adjust values of 'cb_project_vars' and 'project_exported_vars' variables, define 'config_remember_vars' macro
include $(cb_dir)/core/confsup.mk

# clean-build always sets default values for the variables, to override these defaults
#  by the ones specified in the project configuration makefile, here use the 'override' directive
$(foreach =,$(cb_project_vars),$(eval override $(if $(findstring simple,$(flavor \
  $=)),$$=:=$$($$=),$(call define_multiline,$$=,$(value $=)))))

# include variables protection module - define 'cb_checking', 'cb_tracing', 'set_global', 'get_global', 'env_remember' and other macros
# protect from changes project variables - which have the 'override' $(origin) and exported variables in the $(project_exported_vars)
include $(cb_dir)/core/protection.mk

# autoconfigure values of: CBLD_OS, CBLD_BCPU, CBLD_CPU, CBLD_TCPU, CBLD_UTILS
# define 'utils_mk' - makefile with definitions of shell utilities (included below)
include $(cb_dir)/core/aconf.mk

# list of project-supported target/tool target types
# note: normally these defaults are overridden in the project configuration makefile
project_supported_targets      := RELEASE DEBUG
project_supported_tool_targets := RELEASE DEBUG

# what target/tool target type to build (DEBUG, RELEASE, etc.) - must be a value from
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
# note: 'delete_dirs' macro is defined in the included below $(utils_mk) makefile
distclean:
	$(quiet)$(call delete_dirs,$(cb_build))

endif # !no_clean_build_distclean_goal

endif # distclean

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
#  $(debug) is non-empty for debugging targets like "PROJECT_DEBUG" or "DEBUG"
# note: define 'debug' assuming that we are not in "tool" mode
debug := $(filter DEBUG %_DEBUG,$(CBLD_TARGET))

# 'debug' variable is redefined in "tool" mode and restored in non-"tool" mode
cb_set_default_vars   := debug:=$(debug)$(newline)
cb_tool_override_vars := debug:=$(filter DEBUG %_DEBUG,$(CBLD_TOOL_TARGET))$(newline)

# note: do not trace access to 'debug' variable - it may be used in ifdefs
# note: assume result of $(call set_global1,debug) will give an empty line at end of expansion
ifdef cb_checking
cb_set_default_vars   := $(cb_set_default_vars)$(call set_global1,debug)
cb_tool_override_vars := $(cb_tool_override_vars)$(call set_global1,debug)
endif

# ---------- output paths: 'o_dir' and 'o_path' ---------------

# base part of sub-directory of built artifacts, e.g. DEBUG-LINUX-x86
target_triplet := $(CBLD_TARGET)-$(CBLD_OS)-$(CBLD_CPU)

# private namespace - name of sub-directory of $(cb_build)/$(target_triplet) where modules create their files while the build
ifndef cb_checking
priv_prefix:=
else
priv_prefix := pp
endif

# check that paths are relative and simple: 1/2/3, but not /1/2/3 or 1//2/3 or 1/2/../3
ifdef cb_checking
cb_check_virt_paths = $(if $(filter-out $(addprefix /,$1),$(abspath $(addprefix /,$1))),$(error \
  paths are not relative and simple: $(foreach p,$1,$(if $(filter-out /$p,$(abspath /$p)),$p))))
endif

# get absolute paths to output directories for given targets
# $1 - simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/file2.txt
# note: define 'o_dir' assuming that we are not in "tool" mode
ifndef cb_checking
o_dir = $(patsubst %,$(cb_build)/$(target_triplet),$1)
else
$(eval o_dir = $$(cb_check_virt_paths)$$(addprefix \
  $(cb_build)/$(target_triplet)/$(priv_prefix)/,$$(subst /,-,$$1)))
endif

# get absolute paths to built files
# $1 - simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/file2.txt
ifndef cb_checking
$(eval o_path = $$(addprefix $(cb_build)/$(target_triplet)/,$$1))
else
$(eval o_path = $$(cb_check_virt_paths)$$(addprefix \
  $(cb_build)/$(target_triplet)/$(priv_prefix)/,$$(join $$(addsuffix /,$$(subst /,-,$$1)),$$1)))
endif

# code to evaluate for restoring default output directory after "tool" mode
cb_set_default_vars := $(cb_set_default_vars)o_dir=$(value o_dir)$(newline)o_path=$(value o_path)

# ---------- 'o_dir' and 'o_path' for the "tool" mode ---------

# base directory where auxiliary build tools are built
# note: path should be absolute for absolute values of 'o_dir' and 'o_path' in "tool" mode
tool_base := $(cb_build)

# check that $(tool_base) path is absolute
ifneq ("$(tool_base)","$(abspath $(tool_base))")
$(error tool_base=$(tool_base) path is not absolute, should be: $(abspath $(tool_base)))
endif

# 'tool_base' may be redefined in the project configuration makefile, ensure $(tool_base) is under $(cb_build)
ifeq (,$(filter $(cb_build)/%,$(tool_base)/))
$(error tool_base=$(tool_base) is not cb_build=$(cb_build) nor a subdirectory of it)
endif

# macro to form a path where tools are built
# $1 - $(tool_base)
# $2 - $(CBLD_TCPU)
mk_tools_dir = $1/tool-$2-$(CBLD_TOOL_TARGET)

# absolute path where tools are built, for the current 'tool_base' and CBLD_TCPU
cb_tools_dir := $(call mk_tools_dir,$(tool_base),$(CBLD_TCPU))

# code to evaluate for overriding default output directory in "tool" mode
ifndef cb_checking
cb_tool_override_vars := $(cb_tool_override_vars)o_dir=$$(patsubst \
  %,$(cb_tools_dir),$$1)$(newline)o_path=$$(addprefix $(cb_tools_dir)/,$$1)
else
cb_tool_override_vars := $(cb_tool_override_vars)o_dir=$$(cb_check_virt_paths)$$(addprefix \
  $(cb_tools_dir)/$(priv_prefix)/,$$(subst /,-,$$1))$(newline)o_path=$$(cb_check_virt_paths)$$(addprefix \
  $(cb_tools_dir)/$(priv_prefix)/,$$(join $$(addsuffix /,$$(subst /,-,$$1)),$$1))
endif

# ---------------------------------------------

# remember new values of 'o_dir' and 'o_path'
# note: trace namespace: core
ifdef set_global1
cb_set_default_vars   := $(cb_set_default_vars)$(newline)$(call set_global1,o_dir o_path,core)
cb_tool_override_vars := $(cb_tool_override_vars)$(newline)$(call set_global1,o_dir o_path,core)
endif

# ---------- deploying files ------------------

ifndef cb_checking

# files are built directly in "public" place, no need to copy there files from private directories
deploy_files:=
deploy_dirs:=

else # cb_checking

# deploy built target files
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: assume deployed files are needed only by $(cb_target_makefile)-, so:
#  1) set makefile info (target-specific variables) by 'set_makefile_info_r' macro only for the $(cb_target_makefile)- and
#   assume that this makefile info will be properly inherited by the targets in copying rules
#  2) create needed directories prior copying any deployed file
define cb_deply_templ
$(subst |,: ,$(subst $(space),$(newline),$(join $(2:=|),$1)))
$(call set_makefile_info_r,$(cb_target_makefile)-): $2 | $(patsubst %/,%,$(sort $(dir $2)))
$(call suppress_targets_r,$2):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# deploy built tools
# $1 - built files,    e.g.: /build/pp/bin-tool.exe/bin/tool.exe /build/pp/gen-tool.cfg/gen/tool.cfg
# $2 - deployed paths, e.g.: /build/bin/tool.exe /build/gen/tool.cfg
# note: deployed tools may be needed for building other targets, so:
#  1) set makefile info (target-specific variables) by 'set_makefile_info_r' macro for all deployed tools
#  2) create needed directory prior copying for each deployed tool
define cb_deply_tools_templ
$(subst |, | ,$(subst ||,: ,$(subst / ,$(newline),$(join $(join $(2:=||),$(1:=|)),$(dir $2)) )))$(cb_target_makefile)-: $2
$(call set_makefile_info_r,$(call suppress_targets_r,$2)):
	$$(call suppress,COPY,$$@)$$(call copy_files,$$<,$$@)
endef

# add files to "deployed tools group"
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
# $2 - alias of deployed files group
cb_form_deployed_group = $(if $2,$$2.^d $(if $(findstring file,$(origin $2.^d)),+,:)= $$1$(newline),$(error \
  deployed files group alias name is not specified))

# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
# $2 - alias of deployed files group (used only in "tool" mode)
deploy_files1 = $(if $(is_tool_mode),$(cb_form_deployed_group)$(call \
  cb_deply_tools_templ,$(o_path),$(addprefix $(cb_tools_dir)/,$1)),$(call \
  cb_deply_templ,$(o_path),$(addprefix $(cb_build)/$(target_triplet)/,$1)))

# deploy files - copy them from target's private build directory to "public" place, where files may be accessed for ex. by an installer
# $1 - deployed files - simple paths relative to virtual $(out_dir), e.g.: bin/tool.exe gen/tool.cfg
# $2 - alias of deployed files group (used only in "tool" mode - when deploying build tools)
deploy_files = $(eval $(deploy_files1))

deploy_dirs = $(eval $(deploy_dirs1))

endif # cb_checking

# ----------


# get absolute paths to the tools $2 needed by the target $1
get_tools = 




# macro to form absolute paths to the (built and deployed) tool executables
# $1 - $(tool_base)
# $2 - $(CBLD_TCPU)
# $3 - tool paths - simple and relative to virtual $(out_dir), e.g.: ex/tool1 ex/tool2
cb_built_tools = $(patsubst %,$(mk_tools_dir)/%$(tool_suffix),$3)

/build/tool-x86-release/bin/tool.exe
/build/tool-x86-release/gen/tool.cfg

/build/tool-x86-release/pp/tool/bin/tool.exe -> /build/tool-x86-release/bin/tool.exe
/build/tool-x86-release/pp/tool/gen/tool.cfg -> /build/tool-x86-release/gen/tool.cfg

# in "check mode", tools are deployed to target's private directory $(o_dir)
ifdef cb_checking
$(eval get_tools1 = $(value get_tools))
get_tools = $(call cb_deployed_tools,$(o_dir),$(CBLD_TCPU),$2)
endif




# executable file suffix of the generated tools
tool_suffix := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),.exe)




# note: 'cb_check_virt_paths' - defined in included below $(cb_dir)/core/path.mk
ifdef cb_checking
$(eval cb_deployed_tools1 = $(value cb_deployed_tools))
cb_deployed_tools = $(call cb_check_virt_paths,$3)$(cb_deployed_tools1)
endif

# get absolute paths to the tools $2 needed by the target $1, for the current 'tool_base' and CBLD_TCPU
get_tools = $(call cb_deployed_tools,$(tool_base),$(CBLD_TCPU),$2)

# in "check mode", tools are deployed to target's private directory $(o_dir)
ifdef cb_checking
$(eval get_tools1 = $(value get_tools))
get_tools = $(call cb_deployed_tools,$(o_dir),$(CBLD_TCPU),$2)
endif

# declare that target $1 requires tools $2
ifndef cb_checking
need_tools:=
else
need_tools = $(call need_tools1,$(get_tools),$(call deployed_tools,$(tool_base),$(CBLD_TCPU),$2))

need_tools1 = $(call need_tools2,$(get_tools1),
endif

# get absolute paths to the tools $2 needed by the target $1, for the current 'tool_base' and CBLD_TCPU, copy needed tools
# 
need_tools = $(get_tools)

# get absolute path to the tool $2 needed by the targets $1, for the current 'tool_base' and CBLD_TCPU
# $1 - simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen2/file2.txt
# $2 - tool path - simple and relative to virtual $(out_dir), e.g.: ex/tool1
ifndef cb_checking
need_tool = $(call get_tools,$(tool_base),$(CBLD_TCPU),$2)
else
need_tool = $(cb_check_virt_paths)$(call get_tools,$(tool_base),$(CBLD_TCPU),$2)....
endif






# 'cb_to_clean' - list of $(cb_build)-relative paths to files/directories to recursively delete on "$(MAKE) clean"
# note: 'cb_to_clean' list is never cleared, only appended via 'toclean' macro
# note: 'cb_to_clean' variable should not be directly accessed/modified in target makefiles
cb_to_clean:=

# 'toclean' - function to add files/directories to delete to 'cb_to_clean' list
# $1 - simple paths relative to virtual $(out_dir), e.g.: ex/tool1 bin/file.txt
# note: do nothing if not cleaning up
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

# path to the root target makefile the build was started from
# note: when building from the command line one of out-of-project tree external modules, such as $(cb_dir)/extensions/version/Makefile,
#  which cannot include project configuration makefiles directly (because external modules are project-independent), 'cb_first_makefile'
#  may be auto-defined to a wrong value (not a target makefile), so it may be required to override 'cb_first_makefile' in the command
#  line explicitly, e.g.:
# $ make cb_first_makefile=/opt/clean-build/extensions/version/Makefile \
#   --eval="include ./examples/hello/make/c_project.mk" -f /opt/clean-build/extensions/version/Makefile
cb_first_makefile := $(firstword $(MAKEFILE_LIST))

# absolute path to current target makefile
# note: this variable is redefined by the clean-build for each processed target makefile
# note: path must be absolute - there could be only one .PHONY target '$(cb_first_makefile)-' per target makefile
cb_target_makefile := $(abspath $(cb_first_makefile))

# append makefiles (really .PHONY targets created from them) to the 'order_deps' list - see below
# note: this function is useful to add dependency on all targets built by the specified makefiles (a tree of makefiles) to the targets
#  of current makefile
# note: argument $1 - list of makefiles (or directories, where "Makefile" file is searched)
# note: overridden in $(cb_dir)/core/_submakes.mk
add_mdeps:=

# for the targets $1, define target-specific variable - used by the 'suppress' function in "makefile info" mode (enabled via "$(MAKE) M=1"):
# C.^ - makefile which specifies how to build the targets and a number of section in the makefile after a call to $(make_continue)
# note: do not call this macro for the targets registered via 'cb_target_vars'/'add_generated' - they call 'set_makefile_info' implicitly
# note: 'set_makefile_info' does nothing in non-"makefile info" mode
# note: it is possible to call this macro only for the root target (e.g. a lib), dependent targets (e.g. objs) will inherit target-specific
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

ifndef toclean

# define a .PHONY goal which will depend on main targets (registered via 'cb_target_vars' macro defined below)
.PHONY: $(cb_target_makefile)-

# default goal 'all' - depends only on the root target makefile (a .PHONY goal)
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

# add directories $1 (absolute virtual paths, e.g.: gen/sub_gen) to the list of auto-created ones - 'cb_needed_dirs'
........
# note: these directories are will be auto-deleted while cleaning up
# note: callers of 'need_gen_dirs' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here.
ifndef cb_checking
need_gen_dirs = $(eval cb_needed_dirs+=$$1)
else
# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
# note: paths to directories must be absolute and must not end with backslash
need_gen_dirs = $(if $(filter-out $(abspath $1),$1),$(error \
  paths to directories are not absolute or end with backslash: $(filter-out $(abspath $1),$1)))$(eval \
  cb_needed_dirs+=$$1$(newline)$(call set_global1,cb_needed_dirs))
endif

# register targets as main ones built by the current makefile, add standard target-specific variables
# $1 - target files to build (absolute paths)
# $2 - directories of target files (absolute paths)
# note: postpone expansion of $(order_deps) to optimize parsing
# note: .PHONY target '$(cb_target_makefile)-' will depend on the registered main targets in list $1
# note: callers of 'cb_target_vars1' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here.
# note: rules of the targets should contain only one call to the 'suppress' macro - to properly update percent of building targets
# note: if a rule consists of multiple commands - use 'suppress_more' macro instead of additional calls to the 'suppress' macro
define cb_target_vars1
$1:| $2 $$(order_deps)
$(cb_target_makefile)-:$1
cb_needed_dirs+=$2
endef

# note: 'suppress' and 'cb_makefile_info' macros - defined in included above $(cb_dir)/core/suppress.mk
# note: 'cb_makefile_info' - defined to non-empty value in "makefile info" mode (enabled via "$(MAKE) M=1")
ifdef cb_makefile_info

# for the targets $1, define target-specific variable - used by the 'suppress' function in "makefile info" mode:
# C.^ - makefile which specifies how to build the targets and a number of section in the makefile after a call to $(make_continue)
set_makefile_info = $(eval $(value cb_makefile_info))
set_makefile_info_r = $(set_makefile_info)$1

# optimize: do not call 'set_makefile_info' from 'cb_target_vars1', include code of 'set_makefile_info' directly
$(call define_prepend,cb_target_vars1,$(value cb_makefile_info)$(newline))

endif # cb_makefile_info

ifdef cb_mdebug

# show what targets a template builds (prior building them)
# $1 - targets the template builds
# $2 - optional suffix (e.g. order-only dependencies)
# note: 'cb_colorize' - defined in included above $(cb_dir)/core/suppress.mk
# note: one space after $(call cb_colorize,TARGET,TARGET)
cb_what_makefile_builds = $(info $(call cb_what_makefile_builds1,$1,$2,$(call cb_colorize,TARGET,TARGET) $(if $(is_tool_mode),[T]: )))
cb_what_makefile_builds1 = $3$(subst $(space),$2$(newline)$3,$(join $(patsubst $(cb_build)/%,$(call \
  cb_colorize,CB_BUILD,$$(cb_build))/%,$(dir $1)),$(call cb_colorize,TARGET,$(notdir $1))))$2

# for the 'cb_colorize' macro called in 'cb_what_makefile_builds'
CBLD_TARGET_COLOR   ?= [32m
CBLD_CB_BUILD_COLOR ?= [31;1m

# fix template to print (while evaluating the template) what targets current makefile builds
# $1 - template name
# $2 - expression that gives targets the template builds
# $3 - optional expression that gives order-only dependencies of the targets
# note: expressions $2 and $3 are expanded while expanding template $1, _before_ evaluating result of the expansion
cb_add_what_makefile_builds = $(call define_prepend,$1,$$(call cb_what_makefile_builds,$2,$(if $3,$$(if $3, | $3))))

# patch 'cb_target_vars1' template - print what targets current makefile builds
$(call cb_add_what_makefile_builds,cb_target_vars1,$$1,$$(order_deps))

endif # cb_mdebug

ifdef cb_checking

# remember new value of 'cb_needed_dirs', without tracing calls to it because it's incremented
$(call define_append,cb_target_vars1,$(newline)$$(call set_global1,cb_needed_dirs))

# check that paths to files $1 are absolute and files are generated under $(out_dir)
cb_check_generated_at = $(if \
  $(filter-out $(abspath $1),$1),$(error path to these files are not absolute: $(filter-out $(abspath $1),$1)))$(if \
  $(filter-out $(out_dir)/%,$1),$(error these files are generated not under $$(out_dir): $(filter-out $(out_dir)/%,$1)))

$(call define_prepend,cb_target_vars1,$$(cb_check_generated_at))

endif # cb_checking

# register targets - to properly count percent of building targets by the calls to 'suppress' macro
# note: 'suppress_targets' and 'suppress_targets_r' - are defined in $(cb_dir)/core/suppress.mk
ifdef suppress_targets
$(eval define cb_target_vars1$(newline)$(subst $$1:|,$$(suppress_targets_r):|,$(value cb_target_vars1))$(newline)endef)
endif

# register targets as the main ones built by the current makefile, add standard target-specific variables
# (main targets - that are not necessarily used as prerequisites for other targets in the same makefile)
# $1 - generated file(s) (must be absolute paths)
# note: callers of 'cb_target_vars' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here.
# note: rules of the targets should contain only one call to the 'suppress' macro - to properly update percent of building targets
# note: if a rule consists of multiple commands - use 'suppress_more' macro instead of additional calls to the 'suppress' macro
cb_target_vars = $(call cb_target_vars1,$1,$(patsubst %/,%,$(sort $(dir $1))))

else # toclean

# just delete (recursively, with all content) generated directories $1 (absolute paths) 
ifndef cb_checking
need_gen_dirs = $(eval cb_to_clean+=$$1)
else
# remember new values of 'cb_to_clean' and 'cb_needed_dirs' without tracing calls to them because they are incremented
# note: callers of 'need_gen_dirs' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here (do not optimize!).
need_gen_dirs = $(eval cb_to_clean+=$$1$(newline)$$(call set_global1,cb_to_clean cb_needed_dirs))
endif

# just delete target files $1 (absolute paths)
ifndef cb_checking
cb_target_vars = cb_to_clean+=$1
else
# remember new values of 'cb_to_clean' and 'cb_needed_dirs' without tracing calls to them because they are incremented
# note: callers of 'cb_target_vars' may assume that it will protect new value of 'cb_needed_dirs', so callers
#  _may_ change 'cb_needed_dirs' without protecting it - before the call. Protect 'cb_needed_dirs' here (do not optimize!).
cb_target_vars = cb_to_clean+=$1$(newline)$(call set_global1,cb_to_clean cb_needed_dirs)
endif

# do nothing if cleaning up
add_order_deps:=

endif # toclean

# same as 'cb_target_vars', but add one line containing $1
define cb_target_vars_r
$(cb_target_vars)
$1
endef

# add generated files $1 (must be absolute paths) to build sequence
# note: files must be generated under $(out_dir) directory (which is in turn under $(cb_build))
# note: directories for generated files will be auto-created
# note: generated files will be auto-deleted while completing the 'clean' goal
# note: rules of the targets should contain only one call to the 'suppress' macro - to properly update percent of building targets
# note: use 'suppress_more' macro instead of additional calls to 'suppress' macro - e.g. if a rule consists of multiple commands
add_generated = $(eval $(cb_target_vars))

# do the same as 'add_generated', but also return list of generated files $1
add_generated_r = $(add_generated)$1

# 'tool_mode' may be set to non-empty value (likely T) at the beginning of target makefile
#  (before including this file and so before evaluating $(cb_def_head))
# if 'tool_mode' is not set - reset it - we are not in "tool" mode
# else - check its value while evaluation of 'cb_def_head'
ifneq (file,$(origin tool_mode))
tool_mode:=
endif

# non-empty (likely T) in "tool" mode - 'tool_mode' variable was set to that value prior evaluating $(cb_def_head), empty in normal mode.
# note: 'tool_mode' variable should not be used in rule templates - use $(is_tool_mode) instead, because 'tool_mode' may be set to another
#  value anywhere before $(make_continue), and so before the evaluation of rule templates.
# reset the value: we are currently not in "tool" mode
is_tool_mode:=

# code to evaluate at the beginning of target makefile to adjust variables for "tool" mode
# note: set 'is_tool_mode' variable to remember if we are in "tool" mode - 'tool_mode' variable may be set to another value
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
# note: assume result of $(call set_global1,tool_mode) will give an empty line at end of expansion
$(call define_prepend,cb_tool_mode_adjust,$$(if $$(findstring $$$$(cb_tool_mode_access_error),$$(value tool_mode)),$$(eval \
  tool_mode:=$$$$(is_tool_mode)))tool_mode=$$$$(cb_tool_mode_access_error)$(newline)$$(call set_global1,tool_mode))

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
# note: assume result of $(call set_global1,cb_target_makefiles) will give an empty line at end of expansion
$(eval define cb_def_head$(newline)$(subst \
  else$(newline),else$(newline)$$(if $$(filter $$(cb_target_makefile),$$(cb_target_makefiles)),$$(error \
  makefile $$(cb_target_makefile) was already processed!))cb_target_makefiles+=$$$$(cb_target_makefile)$(newline)$$(call \
  set_global1,cb_target_makefiles),$(value cb_def_head))$(newline)endef)

# check that all target files are built:
#  'cb_target_vars1' template only declares 'phony' targets (without rules), rules for the targets should be defined elsewhere,
#  if a target file does not exist - corresponding rule should create it, but if the rule wasn't defined - it will be a warning.
# note: must be called in $(cb_target_makefile)'s rule body, where automatic variables $@ and $^ are defined
# note: $(wildcard) may return cached results (for existing files)
cb_check_targets = $(foreach =,$(filter-out $(wildcard $^),$^),$(info $(@:-=): warning: these files are not built: $=))

# if all targets of $(cb_target_makefile) are completed, check that files exist/update percents
$(eval define cb_def_head$(newline)$(subst \
  else,else$(newline)$$$$(cb_target_makefile)-:; $$$$(cb_check_targets),$(value cb_def_head))$(newline)endef)

# remember new value of 'cb_make_cont' (without tracing calls to it - it's modified via +=)
# note: result of $(call set_global1,cb_make_cont) will give an empty line at end of expansion
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
# include $(cb_dir)/core/all.mk only if $(cb_include_level) is empty and not inside the call of $(make_continue)
# note: $(make_continue) before expanding $(cb_def_tail) adds ~ to $(cb_make_cont) list
cb_def_tail = $(if $(findstring ~,$(cb_make_cont)),,$(if $(cb_include_level),cb_head_eval:=,include $(cb_dir)/core/all.mk))

# prepend 'cb_def_tail' with $(cb_check_at_tail) - it is defined in $(cb_dir)/core/protection.mk
ifdef cb_checking
$(call define_prepend,cb_def_tail,$$(cb_check_at_tail)$(newline))
endif

# called by 'cb_def_targets' if it was not properly redefined in 'cb_def_head'
cb_no_def_head_err = $(error $$(cb_def_head) was not evaluated at head of makefile!)

# 1) redefine 'cb_def_targets' macro to produce an error if $(cb_def_head) was not evaluated prior expanding it
# note: the same check is performed in $(cb_check_at_tail), but it will be done only after expanding templates added by the
#  previous target makefile - this may lead to errors, because templates were not prepared by the previous $(cb_head_eval)
# 2) remember new values of 'cb_head_eval' (which was reset to empty) and 'cb_def_targets' (which produces an error),
#  do not trace calls to them: value of 'cb_head_eval' is checked in 'cb_prepare' below
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
# $1 - the name of the macro, the expansion of which gives the code for the initialization of target type template variables
# $2 - the name of the macro, the expansion of which gives the code for defining target type rules (by expanding target type template)
# NOTE: if $1 is empty, just evaluate $(cb_def_head), if it wasn't evaluated yet
# NOTE: if $1 is non-empty, expand it now via $(call $1) to not pass any parameters into the expansion
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
cb_save_vars = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v)),$v.^s:=$$($v),define $v.^s$(newline)$(value $v)$(newline)endef)$(newline)))

# after $(make_continue): restore variables saved before (via 'cb_save_vars' macro)
cb_restore_vars = $(eval $(foreach v,$1,$(if $(findstring \
  simple,$(flavor $v.^s)),$v:=$$($v.^s),define $v$(newline)$(value $v.^s)$(newline)endef)$(newline)))

# reset %.^s variables
# note: 'cb_reset_saved_vars' - defined in $(cb_dir)/core/protection.mk
ifdef cb_checking
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
$(eval make_continue = $(subst $$(call define_targets),$$(call set_global,cb_make_cont)$$(call define_targets),$(value make_continue)))
endif

# define functions: 'fixpath', 'ospath', 'ifaddq', 'path_unspaces', 'qpath' and 'gmake_path'
include $(cb_dir)/core/path.mk

# define 'run_tool' macro
# note: included below $(utils_mk) (e.g. $(cb_dir)/utils/cmd.mk) may override some of macros defined in this $(cb_dir)/core/runtool.mk
include $(cb_dir)/core/runtool.mk

# define shell utilities
# note: $(cb_dir)/utils/cmd.mk overrides macros defined in $(cb_dir)/core/runtool.mk: 'pathsep', 'show_tool_vars', 'show_tool_vars_end'
include $(utils_mk)

# product version in form "major.minor" or "major.minor.patch"
# Note: this is the default value of 'modver' variable - per-module version number defined by 'c_prepare_base_vars' template from
#  $(cb_dir)/types/c/c_base.mk
product_version := 0.0.1

# CBLD_NO_DEPS - if defined, then do not generate, process or cleanup previously generated auto-dependencies
# note: by default, do not generate auto-dependencies for release builds
#ifeq (undefined,$(origin CBLD_NO_DEPS))
#CBLD_NO_DEPS := $(if $(debug),,1)
#endif

# remember values of variables possibly taken from the environment
# note: CBLD_BUILD - initialized in the project configuration makefile - $(cb_dir)/stub/project.mk
$(call config_remember_vars,CBLD_BUILD CBLD_TARGET CBLD_TOOL_TARGET)

# makefile parsing first phase variables
# Note: 'o_dir', 'o_path' and 'debug' change their values depending on the value of 'tool_mode' variable set in the last
#  parsed makefile, so clear these variables before rule execution second phase
cb_first_phase_vars += cb_needed_dirs build_system_goals debug cb_set_default_vars cb_tool_override_vars \
  o_dir o_path order_deps toclean cb_target_makefile add_mdeps cb_what_makefile_builds cb_what_makefile_builds1 \
  set_makefile_info set_makefile_info_r cb_add_what_makefile_builds add_order_deps need_gen_dirs cb_target_vars1 \
  cb_check_generated_at cb_target_vars cb_target_vars_r add_generated add_generated_r set_makefile_specific2 set_makefile_specific1 \
  set_makefile_specific tool_mode is_tool_mode cb_tool_mode_adjust cb_tool_mode_access_error cb_include_level \
  cb_target_makefiles cb_head_eval cb_make_cont cb_def_head cb_show_leaf_mk cb_def_tail cb_def_targets define_targets \
  cb_prepare cb_save_vars cb_restore_vars make_continue

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,MAKEFLAGS SHELL cb_needed_dirs cb_first_phase_vars CBLD_BUILD CBLD_TARGET CBLD_TOOL_TARGET \
  cb_mdebug build_system_goals no_clean_build_distclean_goal debug cb_to_clean order_deps CBLD_TARGET_COLOR CBLD_CB_BUILD_COLOR \
  cb_include_level cb_target_makefiles cb_make_cont CBLD_LEAF_COLOR CBLD_LEVEL_COLOR CBLD_CONF_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: core
$(call set_global,cb_project_vars clean_build_version cb_dir clean_build_required_version \
  cb_build project_supported_targets project_supported_tool_targets cb_set_default_vars cb_tool_override_vars \
  target_triplet o_dir o_path tool_base mk_tools_dir tool_suffix get_tools get_tool cb_first_makefile \
  cb_target_makefile add_mdeps cb_what_makefile_builds cb_what_makefile_builds1 set_makefile_info set_makefile_info_r \
  cb_add_what_makefile_builds add_order_deps=order_deps=order_deps need_gen_dirs cb_target_vars1 cb_check_generated_at cb_target_vars \
  cb_target_vars_r add_generated add_generated_r set_makefile_specific2 set_makefile_specific1 set_makefile_specific is_tool_mode \
  cb_tool_mode_adjust cb_tool_mode_access_error cb_def_head cb_show_leaf_mk cb_check_targets cb_def_tail cb_no_def_head_err \
  cb_def_targets define_targets cb_prepare cb_save_vars cb_restore_vars make_continue product_version,core)

# if 'toclean' value is non-empty, allow tracing calls to it (with trace namespace: toclean),
# else - just protect 'toclean' from changes, do not make it's value non-empty - because 'toclean' is checked in ifdefs
ifndef toclean
$(call set_global,toclean)
else
$(call set_global,toclean==cb_to_clean,toclean)
endif

# define auxiliary macros: 'non_parallel_execute', 'multi_target' and 'multi_target_r'
include $(cb_dir)/core/nonpar.mk
include $(cb_dir)/core/multi.mk
