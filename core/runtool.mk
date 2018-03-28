#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for running a tool (with parameters) in a modified environment

# paths separator char, as used in PATH environment variable
# note: $(cb_dir)/utils/cmd.mk redefines 'pathsep' to ;
pathsep := :

# name of environment variable to modify in $(run_tool)
# note: $(dll_path_var) should be PATH (for Windows) or LD_LIBRARY_PATH (for Unix-like OS)
dll_path_var := $(if $(filter WIN% CYGWIN% MINGW%,$(CBLD_OS)),PATH,LD_LIBRARY_PATH)

# show environment variables prepared for running a tool in a modified environment
# $1 - tool to execute (with parameters - escaped by 'shell_escape' macro)
# $2 - additional paths separated by $(pathsep) to append to $(dll_path_var)
# $3 - directory to change to for executing a tool
# $4 - names of variables to set in the environment (export) to run given tool
# note: 'shell_escape', 'execute_in_info' macros - are defined in $(utils_mk) makefile
# note: $(cb_dir)/utils/cmd.mk redefines 'show_tool_vars'/'show_tool_vars_end' macros
show_tool_vars1 = $(foreach =,$(if $2,$(dll_path_var)) $4,$==$(call shell_escape,$($=))) $1
show_tool_vars = $(info $(if $3,$(call execute_in_info,$3,$(show_tool_vars1)),$(show_tool_vars1)))

# note: $(cb_dir)/utils/cmd.mk redefines 'show_tool_vars_end'
show_tool_vars_end:=

# run executable in a modified environment
# $1 - tool to execute (with parameters - escaped by 'shell_escape' macro)
# $2 - additional paths separated by $(pathsep) to append to $(dll_path_var)
# $3 - directory to change to for executing a tool
# $4 - names of variables to set in the environment (export) to run given tool
# note: this function should be used in rule body, where automatic variable $@ is defined
# note: 'execute_in' macro - defined in $(utils_mk) makefile
# note: calling a tool _must_ not produce any output to stdout of make, tool's stdout must be
#  redirected either to a file or to stderr, e.g. './my_tool >file' or './my_tool >&2'
run_tool = $(if $2$4,$(if $2,$(eval $$@:export $$(dll_path_var):=$(if $(findstring undefined,$(origin $(dll_path_var))),,$(if \
  $($(dll_path_var)),$$($(dll_path_var))$$(pathsep)))$$2))$(foreach =,$4,$(eval $$@:export $$=:=$$($$=)))$(if \
  $(verbose),$(show_tool_vars)@))$(if $3,$(call execute_in,$3,$1),$1)$(if $2$4,$(if $(verbose),$(show_tool_vars_end)))

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: run_tool
$(call set_global,pathsep dll_path_var show_tool_vars1 show_tool_vars show_tool_vars_end run_tool,run_tool)
