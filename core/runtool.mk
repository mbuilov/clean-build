#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for running a tool (with parameters) in a modified environment

# paths separator char, as used in PATH environment variable
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
# note: SHELL_ESCAPE, EXECUTE_IN - defined in the $(UTILS_MK) makefile
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars/show_tool_vars_end
show_tool_vars1 = $(foreach v,$(if $2,$(DLL_PATH_VAR)) $4,$v=$(call SHELL_ESCAPE,$($v))) $1
show_tool_vars = $(info $(if $3,$(call EXECUTE_IN,$3,$(show_tool_vars1)),$(show_tool_vars1)))

# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars_end
show_tool_vars_end:=

# run executable in a modified environment
# $1 - tool to execute (with parameters)
# $2 - additional path(s) separated by $(PATHSEP) to append to $(DLL_PATH_VAR)
# $3 - directory to change to for executing a tool
# $4 - list of names of variables to set in environment (export) for running an executable
# note: this function should be used in rule body, where automatic variable $@ is defined
# note: calling a tool _must_ not produce any output to stdout,
#  tool's stdout must be redirected either to a file or to stderr, e.g. './my_tool >file' or './my_tool >&2'
# note: $(CLEAN_BUILD_DIR)/utils/cmd.mk defines own show_tool_vars/show_tool_vars_end
RUN_TOOL = $(if $2$4,$(if $2,$(eval \
  $$@:export $(DLL_PATH_VAR):=$$($(DLL_PATH_VAR))$$(if $$($(DLL_PATH_VAR)),$$(if $2,$(PATHSEP)))$2))$(foreach v,$4,$(eval \
  $$@:export $v:=$$($v)))$(if $(VERBOSE),$(show_tool_vars)@))$(if $3,$(call EXECUTE_IN,$3,$1),$1)$(if \
  $2$4,$(if $(VERBOSE),$(show_tool_vars_end)))

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,PATHSEP DLL_PATH_VAR show_tool_vars1 show_tool_vars show_tool_vars_end RUN_TOOL)
