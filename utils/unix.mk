#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities - UNIX specific

# this file is included by $(cb_dir)/core/_defs.mk

# common utilities definitions
include $(dir $(lastword $(MAKEFILE_LIST)))common.mk

# script to print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
# note: 'print_env' - used by $(cb_dir)/core/all.mk
print_env = $(foreach =,$(call uniq,$(project_exported_vars) $(cb_changed_env_vars)),$=='$($=)'$(newline)export $=$(newline)|)

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
shell_escape = '$(subst ','"'"',$1)'

# delete file(s) $1 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: $(cb_dir)/utils/gnu.mk overrides 'delete_files'
delete_files = $(RM) -f $1

# delete directories $1 (recursively) (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: $(cb_dir)/utils/gnu.mk overrides 'delete_dirs'
delete_dirs = $(RM) -rf $1

# try to non-recursively delete directories $1 if they are empty (short list, no more than CBLD_MAX_PATH_ARGS)
# note: if a path contains a space, use 'ifaddq' to add quotes: '1 2/3 4' '5 6/7 8/9' ...
# note: if directory is not empty, ignore an error
# note: $(cb_dir)/utils/gnu.mk overrides 'try_delete_dirs'
try_delete_dirs = $(RMDIR) $1 2>$(NUL) || $(TRUE)

# in a directory $1 (path may contain spaces), delete files $2 (long list)
# note: to support long list, paths in $2 _must_ not contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $6 - empty on first call, $(newline) on next calls
ifdef quiet
delete_files_in1 = $(if $6,$(quiet))$(CD) $2 && $(delete_files)
else # verbose
# show info about files $1 deleted in the directory $2, this info may be printed to build script
# note: 'delete_files_in1_info' - overridden in $(cb_dir)/utils/gnu.mk
delete_files_in1_info = ( $(CD) $2 && $(delete_files) )
delete_files_in1 = $(info $(delete_files_in1_info))@$(CD) $2 && $(delete_files)
endif # verbose
delete_files_in  = $(call xcmd,delete_files_in1,$2,$(CBLD_MAX_PATH_ARGS),$1,,,)

# delete files and/or directories (recursively) (long list)
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
del_files_or_dirs1 = $(if $6,$(quiet))$(delete_dirs)
del_files_or_dirs  = $(call xcmd,del_files_or_dirs1,$1,$(CBLD_MAX_PATH_ARGS),,,,)

# copy file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'copy_files2'
copy_files2 = $(CP) -p $1 $2
copy_files1 = $(if $6,$(quiet))$(copy_files2)
copy_files  = $(if $(findstring $(space),$1),$(call xcmd,copy_files1,$1,$(CBLD_MAX_PATH_ARGS),$2,,,),$(copy_files2))

# move file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ not contain spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ not contain spaces, but path to file $2 may contain spaces)
# note: $6 - empty on first call, $(newline) on next calls
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'move_files2'
move_files2 = $(MV) $1 $2
move_files1 = $(if $6,$(quiet))$(move_files2)
move_files  = $(if $(findstring $(space),$1),$(call xcmd,move_files1,$1,$(CBLD_MAX_PATH_ARGS),$2,,,),$(move_files2))

# update modification date of given file(s) or create file(s) if they do not exist
# note: to support long list, the paths _must_ not contain spaces
# note: $6 - empty on first call, $(newline) on next calls
touch_files1 = $(if $6,$(quiet))$(TOUCH) $1
touch_files  = $(call xcmd,touch_files1,$1,$(CBLD_MAX_PATH_ARGS),,,,)

# create a directory
# note: to avoid races, 'create_dir' must be called only if it's known that destination directory does not exist
# note: 'create_dir' must create intermediate parent directories of the destination directory
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'create_dir'
create_dir = $(MKDIR) -p $1

# compare content of two text files: $1 and $2
# return an error code if they are differ
# note: if path to a file contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
compare_files = $(CMP) $1 $2

# print content of a given file (to stdout, for redirecting it to output file)
# note: if path to file $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
cat_file = $(CAT) $1

# print short string (to stdout, for redirecting it to output file)
# note: there must be no $(newline)s in the string $1
# NOTE: printed string length must not exceed the maximum command line length (at least 4096 characters)
print_short_string = $(PRINTF) '%s' $(shell_escape)

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
# note: used by 'write_string' macro
write_string1 = $(if $6,$3,$4)$(PRINTF) -- $(call unhide_comments,$(call printf_line_escape,$(if $6, )$1))$(if $2,>$(if $6,>) $2)

# write string $1 to file $2, by $3 tokens at one time
# note: there must be no $(newline)s in the string $1
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (at least 4096 characters)
# NOTE: nothing is printed if string $1 is empty, output file is _not_ created in this case
write_string = $(call xargs,write_string1,$(subst $(space),$$(empty) $$(empty),$(hide_tabs)),$3,$2,$(quiet),,,$(newline))

# print one short line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with LF: line -> line\n
# NOTE: printed line length must not exceed the maximum command line length (at least 4096 characters)
print_short_line = $(PRINTF) '%s\n' $(shell_escape)

# print small batch of short text lines (to stdout, for redirecting it to output file)
# note: each line will be ended with LF: line1$(newline)line2 -> line1\nline2\n
# NOTE: total text length must not exceed the maximum command line length (at least 4096 characters)
print_some_lines = $(PRINTF) -- $(subst $(newline),\n,$(call printf_line_escape,$1$(newline)))

# write batch of text lines to output file or to stdout (for redirecting it to output file)
# $1 - lines list, where entries are processed by $(hide_tab_spaces)
# $2 - if not empty, then a file to print to (path to the file may contain spaces)
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: each line will be ended with LF: line1$(space)line2 -> line1\nline2\n
# NOTE: printed batch length must not exceed the maximum command line length (at least 4096 characters)
# note: used by 'write_lines' macro
write_lines1 = $(if $6,$3,$4)$(PRINTF) -- $(call \
  unhide_comments,$(subst $(space),\n,$(call printf_line_escape,$1 )))$(if $2,>$(if $6,>) $2)

# write lines of text $1 to file $2, by $3 lines at one time
# note: if path to file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# NOTE: any line must be less than the maximum command length (at least 4096 characters)
# NOTE: number $3 must be adjusted so printed at one time text length will not exceed the maximum command length (at least 4096 characters)
# NOTE: nothing is printed if text $1 is empty, output file is _not_ created in this case
write_lines = $(call xargs,write_lines1,$(subst $(newline),$$(empty) $$(empty),$(hide_tab_spaces)),$3,$2,$(quiet),,,$(newline))

# create symbolic link $2 -> $1
# note: UNIX-specific
# note: if path to the source or destination contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'create_simlink'
create_simlink = $(LN) -sf $1 $2

# set mode $1 of given file(s) $2 (short list, no more than CBLD_MAX_PATH_ARGS)
# note: UNIX-specific
# note: if path to a file contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'change_mode'
change_mode = $(CHMOD) $1 $2

# execute command $2 in the directory $1
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
execute_in = $(CD) $1 && $2

# show info about command $2 executed in the directory $1, this info may be printed to build script
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $(cb_dir)/utils/gnu.mk overrides 'execute_in_info'
execute_in_info = ( $(CD) $1 && $2 )

# delete target file(s) (short list, no more than CBLD_MAX_PATH_ARGS) if failed to build them and exit shell with error code 1
del_on_fail = || { $(delete_files); $(FALSE); }

# create a directory (with intermediate parent directories) while installing things
# $1 - path to the directory to create, path may contain spaces
# note: if path to directory $1 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: directory $1 must not exist, 'install_dir' may be implemented via 'create_dir' (e.g. under WINDOWS)
# note: $(cb_dir)/utils/gnu.mk overrides 'install_dir'
install_dir = $(INSTALL) -d $1

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ not contain spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: if path to directory/file $2 contains a space, use 'ifaddq' to add quotes: '1 2/3 4'
# note: $6 - empty on first call, $(newline) on next calls
# note: $(cb_dir)/utils/gnu.mk overrides 'install_files2'
install_files2 = $(INSTALL) $3 $1 $2
install_files1 = $(if $6,$(quiet))$(install_files2)
install_files  = $(call xcmd,install_files1,$1,$(CBLD_MAX_PATH_ARGS),$2,$(addprefix -m,$3),,)

# tools colors
CBLD_LN_COLOR    ?= [36m
CBLD_CHMOD_COLOR ?= [1;35m

# remember value of variables that may be taken from the environment
$(call config_remember_vars,CBLD_MAX_PATH_ARGS NUL RM RMDIR TRUE FALSE CD CP MV TOUCH MKDIR CMP GREP CAT ECHO PRINTF LN CHMOD INSTALL)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_MAX_PATH_ARGS NUL RM RMDIR TRUE FALSE CD CP MV TOUCH MKDIR CMP GREP CAT ECHO PRINTF LN CHMOD INSTALL \
  CBLD_LN_COLOR CBLD_CHMOD_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: utils
$(call set_global,print_env=project_exported_vars shell_escape delete_files delete_dirs try_delete_dirs \
  delete_files_in1 delete_files_in1_info delete_files_in del_files_or_dirs1 del_files_or_dirs copy_files2 copy_files1 copy_files \
  move_files2 move_files1 move_files touch_files1 touch_files create_dir compare_files cat_file print_short_string \
  printf_line_escape write_string1 write_string print_short_line print_some_lines write_lines1 write_lines create_simlink \
  change_mode execute_in execute_in_info del_on_fail install_dir install_files2 install_files1 install_files,utils)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: functions
$(call set_global,ifaddq,functions)
