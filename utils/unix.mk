#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - UNIX specific

# this file is included by $(cb_dir)/core/_defs.mk

# common utilities definitions
include $(dir $(lastword $(MAKEFILE_LIST)))common.mk

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
# note: 'sh_print_env' - used by $(cb_dir)/core/all.mk
sh_print_env = $(foreach =,$(call uniq,$(project_exported_vars) $(cb_changed_env_vars)),$=='$($=)'$(newline)export $=$(newline)|)

# command line length is limited, define the maximum number of path arguments that may be passed via the command line assuming
#  the limit is 20000 chars (on Cygwin, on Unix it's generally much larger) and each path do not exceed 120 chars
ifeq (undefined,$(origin CBLD_MAX_PATH_ARGS))
CBLD_MAX_PATH_ARGS := $(if $(filter CYGWIN% MINGW%,$(CBLD_OS)),166,1000)
endif

# null device for redirecting output into
NUL ?= /dev/null

# standard tools
# note: ignore Gnu Make defaults
ifeq (default,$(origin RM))
RM := rm
else
RM ?= rm
endif
RMDIR   ?= rmdir
TRUE    ?= true
FALSE   ?= false
CD      ?= cd
CP      ?= cp
MV      ?= mv
TOUCH   ?= touch
MKDIR   ?= mkdir
CMP     ?= cmp
GREP    ?= grep
CAT     ?= cat
ECHO    ?= echo
PRINTF  ?= printf
LN      ?= ln
CHMOD   ?= chmod
INSTALL ?= install

# escape program argument to pass it via shell: "1 2" -> '"1 2"'
# note: not expecting newlines in $1
shell_escape = '$(subst ','"'"',$1)'

# convert escaped program arguments string to the form accepted by standard unix shell
# do nothing, arguments are already in the required form
shell_args_to_unix = $1

# remove (delete) files $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_rm_some_files'
sh_rm_some_files = $(RM) -f $1

# remove (delete) directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_rm_some_dirs'
sh_rm_some_dirs = $(RM) -rf $1

# try to non-recursively remove directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: if directory is not empty, ignore an error
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_try_rm_some_empty_dirs'
sh_try_rm_some_empty_dirs = $(RMDIR) $1 2>$(NUL) || $(TRUE)

# in a directory $1 (path may contain spaces), delete files $2 (long list)
# note: to support long list, paths in $2 _must_ not contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $6 - empty on first call, $(newline) on next calls
ifdef quiet
sh_rm_files_in1 = $(if $6,$(quiet))$(CD) $2 && $(sh_rm_some_files)
else # verbose
# show info about files $1 deleted in directory $2, this info may be printed to build script
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_rm_files_in1_info'
sh_rm_files_in1_info = ( $(CD) $2 && $(sh_rm_some_files) )
sh_rm_files_in1 = $(info $(sh_rm_files_in1_info))@$(CD) $2 && $(sh_rm_some_files)
endif # verbose
sh_rm_files_in  = $(call xcmd,sh_rm_files_in1,$2,$(CBLD_MAX_PATH_ARGS),$1)

# delete files/directories (recursively) (long list)
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
sh_rm_recursive1 = $(if $6,$(quiet))$(sh_rm_some_dirs)
sh_rm_recursive  = $(call xcmd,sh_rm_recursive1,$1,$(CBLD_MAX_PATH_ARGS))

# copy files (long list) trying to preserve modification date, ownership and mode:
# - files $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2       (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_copy_files2'
sh_copy_files2 = $(CP) $1 $2
sh_copy_files1 = $(if $6,$(quiet))$(sh_copy_files2)
sh_copy_files  = $(if $(findstring $(space),$1),$(call xcmd,sh_copy_files1,$1,$(CBLD_MAX_PATH_ARGS),$2),$(sh_copy_files2))

# move files/directories (long list) trying to preserve modification date, ownership and mode:
# - files/directories $1 to directory $2 (paths to entries $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2                   (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces) or
# - directory $1 to directory $2         (path to directory $1 _must_ not contain spaces, but path to directory $2 may contain spaces)
# note: if $2 is an existing directory, files/directories $1 are moved _under_ it
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_move2'
sh_move2 = $(MV) $1 $2
sh_move1 = $(if $6,$(quiet))$(sh_move2)
sh_move  = $(if $(findstring $(space),$1),$(call xcmd,sh_move1,$1,$(CBLD_MAX_PATH_ARGS),$2),$(sh_move2))

# create symbolic links to files (long list):
# - to files $1 in directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - to file $1 by simlink $2    (path to file $1 _must_ not contain spaces, but path to simlink $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_simlink_files2'
sh_simlink_files2 = $(LN) -sf $1 $2
sh_simlink_files1 = $(if $6,$(quiet))$(sh_simlink_files2)
sh_simlink_files  = $(if $(findstring $(space),$1),$(call xcmd,sh_simlink_files1,$1,$(CBLD_MAX_PATH_ARGS),$2),$(sh_simlink_files2))

# update modification date of given files (long list) or create them if they do not exist
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
sh_touch1 = $(if $6,$(quiet))$(TOUCH) $1
sh_touch  = $(call xcmd,sh_touch1,$1,$(CBLD_MAX_PATH_ARGS))

# create directory
# note: to avoid races, 'sh_mkdir' must be called only if it's known that destination directory does not exist
# note: 'sh_mkdir' must create intermediate parent directories of the destination directory
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: to avoid races, there must be no other commands running in parallel and creating child sub-directories of new sub-directories
#  created by this command
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_mkdir'
sh_mkdir = $(MKDIR) -p $1

# copy recursively directory $1 (path may contain spaces) to directory $2 (path may contain spaces)
# note: if $2 - is an existing directory, a copy is created _under_ it
# note: if path to directory $1 or $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: try to preserve modification date, ownership and mode of copied files and directories
# note: paths $1 and $2 _must_ be absolute (Windows-implementation specific requirement)
# NOTE: to avoid races, there must be no other commands running in parallel and creating child sub-directories of new sub-directories
#  created by this command
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_copy_dir'
sh_copy_dir = $(CP) -r $1 $2

# create symbolic link to directory $1 from $2
# note: if $2 - is an existing directory, a simlink is created _under_ it
# note: if path to directory $1 or $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_simlink_dir'
sh_simlink_dir = $(LN) -sf $1 $2

# compare content of two text files: $1 and $2
# raise an error if they are differ
# note: if path to a file contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
sh_cmp_files = $(CMP) $1 $2

# print content of a given file (to stdout, for redirecting it to output file)
# note: if path to file $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
sh_cat = $(CAT) $1

# print short string of options (to stdout, for redirecting it to output file)
# note: there must be no $(newline)s in the string $1
# NOTE: printed string length must not exceed the maximum command line length (at least 4096 characters)
sh_print_some_options = $(PRINTF) '%s' $(shell_escape)

# prepare printf argument
printf_line_escape = $(call shell_escape,$(subst \,\\,$(subst %,%%,$1)))

# write batch of text tokens to output file or to stdout (for redirecting it to output file
# $1 - tokens list, where entries are processed by $(hide_tabs)
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: there must be no $(newline)s among text tokens
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: printed batch length must not exceed the maximum command line length (at least 4096 characters)
sh_write_options1 = $(if $6,$3,$4)$(PRINTF) -- $(call unhide_comments,$(call printf_line_escape,$(if $6, )$1))$(if $2,>$(if $6,>) $2)

# write string of options $1 to file $2, by $3 tokens at one time
# note: one leading space will be ignored
# note: there must be no $(newline)s in the string $1
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (at least 4096 characters)
# NOTE: nothing is printed if string $1 is empty, output file is _not_ created in this case
sh_write_options = $(call xargs,sh_write_options1,$(subst \
  $(space) , $$(empty) ,$(subst $(space) , $$(empty) ,$(hide_tabs)$$(empty))),$3,$2,$(quiet),,,$(newline))

# print one short line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with LF: line -> line\n
# NOTE: printed line length must not exceed the maximum command line length (at least 4096 characters)
sh_print_short_line = $(PRINTF) '%s\n' $(shell_escape)

# print small batch of short text lines (to stdout, for redirecting it to output file)
# note: each line will be ended with LF: line1$(newline)line2 -> line1\nline2\n
# NOTE: total text length must not exceed the maximum command line length (at least 4096 characters)
sh_print_some_lines = $(PRINTF) -- $(subst $(newline),\n,$(call printf_line_escape,$1$(newline)))

# write batch of text lines to output file or to stdout (for redirecting it to output file)
# $1 - lines list, where entries are processed by $(hide_tab_spaces)
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: each line will be ended with LF: line1$(space)line2 -> line1\nline2\n
# NOTE: printed batch length must not exceed the maximum command line length (at least 4096 characters)
sh_write_lines1 = $(if $6,$3,$4)$(PRINTF) -- $(call \
  unhide_comments,$(subst $(space),\n,$(call printf_line_escape,$1 )))$(if $2,>$(if $6,>) $2)

# write lines of text $1 to file $2, by $3 lines at one time
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: any line must be less than the maximum command length (at least 4096 characters)
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (at least 4096 characters)
# NOTE: nothing is printed if text $1 is empty, output file is _not_ created in this case
sh_write_lines = $(call xargs,sh_write_lines1,$(subst $(space) , $$(empty) ,$(subst $(space) , $$(empty) ,$(subst \
  $(newline), ,$$(empty)$(hide_tab_spaces)$$(empty)))),$3,$2,$(quiet),,,$(newline))

# set mode $1 of given files $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific
# note: if path to a file contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_chmod_some_files'
sh_chmod_some_files = $(CHMOD) $1 $2

# set mode $1 of given files $2 (long list)
# note: UNIX-specific
# note: to support long list, paths in $2 _must_ not contain spaces
sh_chmod  = $(call xcmd,sh_chmod1,$2,$(CBLD_MAX_PATH_ARGS),$1)

# $1 - files
# $2 - mode
# note: $6 - empty on first call, $(newline) on next calls
sh_chmod1 = $(if $6,$(quiet))$(call sh_chmod_some_files,$2,$1)

# execute command $2 in the directory $1
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
sh_execute_in = $(CD) $1 && $2

# show info about command $2 executed in the directory $1, this info may be printed to build script
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_execute_in_info'
sh_execute_in_info = ( $(CD) $1 && $2 )

# delete target files (short list, no more than CBLD_MAX_PATH_ARGS) if failed to build them and exit shell with error code 1
del_on_fail = || { $(sh_rm_some_files); $(FALSE); }

# create directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: directory $1 must not exist, 'sh_install_dir' may be implemented via 'sh_mkdir' (e.g. under WINDOWS)
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_install_dir'
sh_install_dir = $(INSTALL) -d $1

# install files (long list) to directory or copy file to file
# $1 - files to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $6 - empty on first call, $(newline) on next calls
# note: $(cb_dir)/utils/gnu.mk overrides 'sh_install_files2'
sh_install_files2 = $(INSTALL) $3 $1 $2
sh_install_files1 = $(if $6,$(quiet))$(sh_install_files2)
sh_install_files  = $(call xcmd,sh_install_files1,$1,$(CBLD_MAX_PATH_ARGS),$2,$(addprefix -m,$3))

# remember values of variables possibly be taken from the environment
$(call config_remember_vars,CBLD_MAX_PATH_ARGS NUL RM RMDIR TRUE FALSE CD CP MV TOUCH MKDIR CMP GREP CAT ECHO PRINTF LN CHMOD INSTALL)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_MAX_PATH_ARGS NUL RM RMDIR TRUE FALSE CD CP MV TOUCH MKDIR CMP GREP CAT ECHO PRINTF LN CHMOD INSTALL)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,sh_print_env=project_exported_vars shell_escape shell_args_to_unix sh_rm_some_files sh_rm_some_dirs \
  sh_try_rm_some_empty_dirs sh_rm_files_in1 sh_rm_files_in1_info sh_rm_files_in sh_rm_recursive1 sh_rm_recursive \
  sh_copy_files2 sh_copy_files1 sh_copy_files sh_move2 sh_move1 sh_move sh_simlink_files2 sh_simlink_files1 sh_simlink_files \
  sh_touch1 sh_touch sh_mkdir sh_copy_dir sh_simlink_dir sh_cmp_files sh_cat sh_print_some_options printf_line_escape \
  sh_write_options1 sh_write_options sh_print_short_line sh_print_some_lines sh_write_lines1 sh_write_lines sh_chmod_some_files \
  sh_chmod sh_chmod1 sh_execute_in sh_execute_in_info del_on_fail sh_install_dir sh_install_files2 sh_install_files1 sh_install_files,utils)
