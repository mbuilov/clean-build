#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - GNU specific

# this file is included by $(cb_dir)/core/_defs.mk

# define UNIX utilities, then override some of them
include $(dir $(lastword $(MAKEFILE_LIST)))unix.mk

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
# note: assume SHELL supports define & export in one command: e.g. "export A=B"
print_env = $(foreach =,$(project_exported_vars),$(newline)export $=='$($=)')

# NOTE: in verbose mode, stdout is used only for printing executed commands, all output of the commands must go to stderr

ifdef verbose
# delete file(s) $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in quotes: '1 2/3 4' '5 6/7 8/9' ...
delete_files = $(RM) -fv $1 >&2
endif

ifdef verbose
# delete directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in quotes: '1 2/3 4' '5 6/7 8/9' ...
delete_dirs = $(RM) -rfv $1 >&2
endif

# try to non-recursively delete directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, it must be in quotes: '1 2/3 4' '5 6/7 8/9' ...
ifdef verbose
try_delete_dirs = $(RMDIR) --ignore-fail-on-non-empty -v $1 >&2
else
try_delete_dirs = $(RMDIR) --ignore-fail-on-non-empty $1
endif

ifdef verbose
# copy file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: if path to the directory/file $2 contains a space, it must be in quotes: '1 2/3 4'
copy_files2 = $(CP) -pv $1 $2 >&2
endif

ifdef verbose
# move file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: if path to the directory/file $2 contains a space, it must be in quotes: '1 2/3 4'
move_files2 = $(MV) -v $1 $2 >&2
endif

ifdef verbose
# create a directory
# note: to avoid races, 'create_dir' must be called only if it's known that destination directory does not exist
# note: 'create_dir' must create intermediate parent directories of the destination directory
# note: if path to the directory $1 contains a space, it must be in quotes: '1 2/3 4'
create_dir = $(MKDIR) -pv $1 >&2
endif

# escape command line argument to pass it to $(SED)
# note: assume GNU sed is used, which understands \n and \t
sed_expr = $(shell_escape)

ifdef verbose
# create symbolic link $2 -> $1
# note: UNIX-specific
# note: if path to the source or destination contains a space, it must be in quotes: '1 2/3 4'
create_simlink = $(LN) -sfv $1 $2 >&2
endif

ifdef verbose
# set mode $1 of given file(s) $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific
# note: if path to a file contains a space, it must be in quotes: '1 2/3 4'
change_mode = $(CHMOD) -v $1 $2 >&2
endif

# execute command $2 in the directory $1
# note: if path to the directory $1 contains a space, it must be in quotes: '1 2/3 4'
execute_in = pushd $1 >$(NUL) && { $2 && popd >$(NUL) || { popd >$(NUL); $(FALSE); } }

ifdef verbose
# create a directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to the directory $1 contains a space, it must be in quotes: '1 2/3 4'
install_dir = $(INSTALL) -dv $1 >&2
endif

ifdef verbose
# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as -m644 (rw--r--r-) or -m755 (rwxr-xr-x)
# note: if path to the directory/file $2 contains a space, it must be in quotes: '1 2/3 4'
install_files2 = $(INSTALL) -v $3 $1 $2 >&2
endif

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,print_env=project_exported_vars delete_files delete_dirs try_delete_dirs copy_files2 move_files2 \
  create_dir sed_expr create_simlink change_mode execute_in install_dir install_files2,utils)
