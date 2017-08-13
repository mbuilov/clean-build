#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/impl/_defs.mk

# define unix utilities, then override some of them
include $(dir $(lastword $(MAKEFILE_LIST)))unix.mk

# print prepared environment in verbose mode
# note: cannot unset some variables (under cygwin) such as "!::" or "CommonProgramFiles(x86)", so filter them out
PRINT_ENV = $(info for v in `env | cut -d= -f1`; do $(foreach \
  x,PATH SHELL $(PASS_ENV_VARS) CommonProgramFiles(x86) ProgramFiles(x86) !::,[ "$x" = "$$v" ] ||) unset "$$v"; done$(foreach \
  v,PATH SHELL $(PASS_ENV_VARS),$(newline)export $v='$($v)'))

# delete files $1
DEL = rm -f$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# delete files and directories
# note: do not need to add $(QUIET) before $(RM)
RM = $(QUIET)rm -rf$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# to avoid races, MKDIR must be called only if destination directory does not exist
# note: MKDIR should create intermediate parent directories of destination directory
MKDIR = mkdir -p$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# escape command line argument to pass it to $(SED)
# note: assume GNU sed is used, which understands \n and \t
SED_EXPR = '$1'

# copy preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 or
# - file $1 to file $2
CP = cp -p$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# create symbolic link
# note: this tool is UNIX-specific and may be not defined for other OSes
LN = ln -sf$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# set mode $1 of given file(s) $2
# note: this tool is UNIX-specific and may be not defined for other OSes
CHMOD = chmod$(if $(VERBOSE), -v) $1 $2$(if $(VERBOSE), >&2)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PRINT_ENV DEL RM MKDIR SED_EXPR CP LN CHMOD)
