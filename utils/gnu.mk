#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - GNU specific

# this file is included by $(cb_dir)/core/_defs.mk

# define UNIX utilities, then override some of them
include $(dir $(lastword $(MAKEFILE_LIST)))unix.mk

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
# note: assume SHELL supports define & export in one command: e.g. "export A=B"
# note: 'print_env' - used by $(cb_dir)/core/all.mk
print_env = $(foreach =,$(call uniq,$(project_exported_vars) $(cb_changed_env_vars)),export $=='$($=)'$(newline)|)

# NOTE: in verbose mode, stdout is used only for printing executed commands, all output of the commands must go to stderr

ifdef verbose
# delete file(s) $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
delete_files = $(RM) -fv $1 >&2
endif

ifdef verbose
# delete directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
delete_dirs = $(RM) -rfv $1 >&2
endif

# try to non-recursively delete directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
ifdef verbose
try_delete_dirs = $(RMDIR) --ignore-fail-on-non-empty -v $1 >&2
else
try_delete_dirs = $(RMDIR) --ignore-fail-on-non-empty $1
endif

ifdef verbose
# show info about files $1 deleted in the directory $2, this info may be printed to build script
delete_files_in1_info = pushd $2 >$(NUL) && { $(delete_files) && popd >$(NUL) || { popd >$(NUL); $(FALSE); } }
endif

ifdef verbose
# copy file(s) (long list) trying to preserve modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
copy_files2 = $(CP) -pv $1 $2 >&2
endif

ifdef verbose
# move file(s) (long list) trying to preserve modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
move_files2 = $(MV) -v $1 $2 >&2
endif

ifdef verbose
# create symbolic link(s) to file(s) (long list):
# - to file(s) $1 in directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - to file $1 by simlink $2      (path to file $1 _must_ not contain spaces, but path to simlink $2 may contain spaces)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
simlink_files2 = $(LN) -sfv $1 $2 >&2
endif

ifdef verbose
# create directory
# note: to avoid races, 'create_dir' must be called only if it's known that destination directory does not exist
# note: 'create_dir' must create intermediate parent directories of the destination directory
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
create_dir = $(MKDIR) -pv $1 >&2
endif

ifdef verbose
# copy recursively directory $1 (path may contain spaces) to parent directory $2 (path may contain spaces)
# note: copy of the source directory $1 is created under the parent directory $2, which must exist
# note: if path to directory $1 or $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: to avoid races, there must be no other commands running in parallel and creating child sub-directories of new sub-directories
#  created while the copying by this command
copy_dir = $(CP) -rpv $1 $2 >&2
endif

ifdef verbose
# set mode $1 of given file(s) $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific
# note: if path to a file contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
change_mode = $(CHMOD) -v $1 $2 >&2
endif

# show info about command $2 executed in the directory $1, this info may be printed to build script
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
execute_in_info = pushd $1 >$(NUL) && { $2 && popd >$(NUL) || { popd >$(NUL); $(FALSE); } }

ifdef verbose
# create a directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
install_dir = $(INSTALL) -dv $1 >&2
endif

ifdef verbose
# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as -m644 (rw--r--r-) or -m755 (rwxr-xr-x)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
install_files2 = $(INSTALL) -v $3 $1 $2 >&2
endif

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,print_env=project_exported_vars delete_files delete_dirs try_delete_dirs delete_files_in1_info \
  copy_files2 move_files2 simlink_files2 create_dir copy_dir change_mode execute_in_info install_dir install_files2,utils)
