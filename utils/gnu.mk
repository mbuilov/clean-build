#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - GNU specific

# this file included by $(CLEAN_BUILD_DIR)/core/_defs.mk

# define unix utilities, then override some of them
include $(dir $(lastword $(MAKEFILE_LIST)))unix.mk

# note: cannot unset some variables (under Cygwin) such as "!::" or "CommonProgramFiles(x86)", so filter them out
CYGWIN_FILTERED_ENV := $(if $(filter CYGWIN,$(OS)),CommonProgramFiles(x86) ProgramFiles(x86) !::)

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
PRINT_ENV = for v in `env | cut -d= -f1`; do $(foreach \
  x,PATH SHELL $(PASS_ENV_VARS) $(CYGWIN_FILTERED_ENV),[ "$x" = "$$v" ] ||) unset "$$v"; done$(foreach \
  v,PATH SHELL $(PASS_ENV_VARS),$(newline)export $v='$($v)')

# delete file(s) $1 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
DELETE_FILES = rm -f$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# delete directories $1 (recursively) (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
DELETE_DIRS = rm -rf$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# try to delete directories $1 (non-recursively) if they are empty (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces
TRY_DELETE_DIRS = rmdir$(if $(VERBOSE), -v) --ignore-fail-on-non-empty $1$(if $(VERBOSE), >&2)

# copy file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ be without spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ be without spaces, but path to file $2 may contain spaces)
COPY_FILES2 = cp -p$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# move file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ be without spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ be without spaces, but path to file $2 may contain spaces)
MOVE_FILES2 = mv$(if $(VERBOSE), -v) $1 $2$(if $(VERBOSE), >&2)

# create directory, path may contain spaces: '1 2/3 4'
# to avoid races, CREATE_DIR must be called only if it's known that destination directory does not exist
# note: CREATE_DIR must create intermediate parent directories of destination directory
CREATE_DIR = mkdir -p$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# escape command line argument to pass it to $(SED)
# note: assume GNU sed is used, which understands \n and \t
SED_EXPR = $(SHELL_ESCAPE)

# create symbolic link $2 -> $1, paths may contain spaces: '/opt/bin/my app' -> '../x y z/n m'
# note: UNIX-specific
CREATE_SIMLINK = ln -sf$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# set mode $1 of given file(s) $2 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
# note: UNIX-specific
CHANGE_MODE = chmod$(if $(VERBOSE), -v) $1 $2$(if $(VERBOSE), >&2)

# execute command $2 in directory $1
EXECUTE_IN = pushd $1 >/dev/null && { $2 && popd >/dev/null || { popd >/dev/null; false; } }

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, path may contain spaces, such as: '/opt/a b c'
# note: INSTALL defined in $(CLEAN_BUILD_DIR)/utils/unix.mk
INSTALL_DIR = $(INSTALL) -d$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ be without spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as -m644 (rw--r--r-) or -m755 (rwxr-xr-x)
# note: overwrite INSTALL_FILES2 macro from $(CLEAN_BUILD_DIR)/utils/unix.mk
INSTALL_FILES2 = $(INSTALL)$(if $(VERBOSE), -v) $3 $1 $2$(if $(VERBOSE), >&2)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,CYGWIN_FILTERED_ENV PRINT_ENV DELETE_FILES DELETE_DIRS TRY_DELETE_DIRS COPY_FILES2 MOVE_FILES2 \
  CREATE_DIR SED_EXPR CREATE_SIMLINK CHANGE_MODE EXECUTE_IN INSTALL_DIR INSTALL_FILES2)
