#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# common gcc compiler definitions, included by $(cb_dir)/compilers/gcc.mk

# prefix for passing options from gcc command line to the linker
wlprefix := -Wl,

# gcc option to use the pipe for communication between the various stages of compilation
pipe_option := -pipe

# flags for auto-dependencies generation
# note: CBLD_NO_DEPS - defined in $(cb_dir)/core/_defs.mk
auto_deps_flags := $(if $(CBLD_NO_DEPS),,-MMD -MP)

# write by that number of tokens at a time while generating a response file
# note: with too many tokens it is possible to exceed maximum command string length (possible of 4096 characters only)
# note: CBLD_MAX_PATH_ARGS is defined in $(utils_mk) - e.g. $(cb_dir)/utils/unix.mk
CBLD_LINK_RESP_WRITE_BY ?= $(CBLD_MAX_PATH_ARGS)

# It is possible to exceed maximum command string length if linking too many objects at once (especially on Windows), to avoid
#  command line length limitation, it may be required to use a response file - @<file>
# Number of linker arguments so that a response file is required for the linking
# note: CBLD_MAX_PATH_ARGS is defined in $(utils_mk) - e.g. $(cb_dir)/utils/unix.mk
CBLD_LINK_ARGS_LIMIT ?= $(CBLD_MAX_PATH_ARGS)

# $1 - linked target type: $(tm)EXE, $(tm)DLL, ...
# $2 - path to the target exe,dll...
# $3 - linker command (linker executable with flags)
# $4 - additional linker arguments (object files, libraries, flags)
# $5 - name of .rsp file, if empty, then .rsp file is not needed
gcc_rsp_wrap1 = $(if $5,$(call suppress,GEN,$5)$(call write_string,$4,$5,$(CBLD_LINK_RESP_WRITE_BY))$(newline))$(call \
  suppress,$1,$2)$3 $(if $5,@$5,$4)

# check if linker command line is too long - it is needed to create a response file for passing arguments to the linker
# $1 - linked target type: $(tm)EXE, $(tm)DLL, ...
# $2 - path to the target exe,dll...
# $3 - linker command (linker executable with flags)
# $4 - additional linker arguments (object files, libraries, more flags)
# target-specific: 'objdir' - defined by 'c_base_template' from $(cb_dir)/types/c/c_base.mk
gcc_rsp_wrap = $(call gcc_rsp_wrap1,$1,$2,$3,$4,$(if $(word $(CBLD_LINK_ARGS_LIMIT),$4),$(objdir)/link.rsp))

# remember values the variables possibly defined in the environment
$(call config_remember_vars,CBLD_LINK_RESP_WRITE_BY CBLD_LINK_ARGS_LIMIT)

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_LINK_RESP_WRITE_BY CBLD_LINK_ARGS_LIMIT)

# protect variables from modifications in target makefiles
# note: trace namespace: gcc
$(call set_global,wlprefix pipe_option auto_deps_flags gcc_rsp_wrap1 gcc_rsp_wrap,gcc)
