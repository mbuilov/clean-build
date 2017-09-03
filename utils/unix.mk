#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# system shell utilities

# this file included by $(CLEAN_BUILD_DIR)/core/_defs.mk

# print prepared environment in verbose mode (used for generating one-big-build instructions shell file)
PRINT_ENV = $(info for v in `env | cut -d= -f1`; do $(foreach \
  x,PATH SHELL $(PASS_ENV_VARS),[ "$x" = "$$v" ] ||) unset "$$v"; done$(foreach \
  v,PATH SHELL $(PASS_ENV_VARS),$(newline)$v='$($v)'$(newline)export $v))

# command line length is limited:
# POSIX smallest allowable upper limit on argument length (all systems): 4096
# define maximum number of path arguments that may be passed via command line,
# assuming the limit is 20000 chars (on Cygwin, on Unix it's generally much larger) and paths do not exceed 120 chars:
PATH_ARGS_LIMIT := $(if $(filter CYGWIN,$(OS)),166,1000)

# null device for redirecting output into
NUL := /dev/null

# delete file(s) $1 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides DELETE_FILES
DELETE_FILES = rm -f $1

# delete directories $1 (recursively) (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides DELETE_DIRS
DELETE_DIRS = rm -rf $1

# delete directories $1 (non-recursively) if they are empty (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides DELETE_DIRS_IF_EMPTY
DELETE_DIRS_IF_EMPTY = rmdir $1 2>/dev/null || true

# in directory $1 (path may contain spaces), delete files $2 (long list), to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
DELETE_FILES_IN1 = $(if $6,$(QUIET))cd $2 && $(DELETE_FILES)
DELETE_FILES_IN  = $(call xcmd,DELETE_FILES_IN1,$2,$(PATH_ARGS_LIMIT),$1,,,)

# delete files and/or directories (long list), to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
DEL_FILES_OR_DIRS1 = $(if $6,$(QUIET))$(DELETE_DIRS)
DEL_FILES_OR_DIRS  = $(call xcmd,DEL_FILES_OR_DIRS1,$1,$(PATH_ARGS_LIMIT),,,,)

# copy file(s) (long list) preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ be without spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ be without spaces, but path to file $2 may contain spaces)
# note: $6 - <empty> on first call, $(newline) on next calls
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides COPY_FILES2
COPY_FILES2 = cp -p $1 $2
COPY_FILES1 = $(if $6,$(QUIET))$(COPY_FILES2)
COPY_FILES  = $(if $(word 2,$1),$(call xcmd,COPY_FILES1,$1,$(PATH_ARGS_LIMIT),$2,,,),cp -p $1 $2)

# update modification date of given file(s) or create file(s) if they do not exist
# note: to support long list, paths _must_ be without spaces
# note: $6 - <empty> on first call, $(newline) on next calls
TOUCH_FILES1 = $(if $6,$(QUIET))touch $1
TOUCH_FILES  = $(call xcmd,TOUCH_FILES1,$1,$(PATH_ARGS_LIMIT),,,,)

# create directory, path may contain spaces: '1 2/3 4'
# to avoid races, CREATE_DIR must be called only if it's known that destination directory does not exist
# note: CREATE_DIR must create intermediate parent directories of destination directory
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides CREATE_DIR
CREATE_DIR = mkdir -p $1

# compare content of two text files: $1 and $2
# return an error code if they are differ
# note: paths to files may contain spaces
COMPARE_FILES = cmp $1 $2

# escape program argument to pass it via shell: "1 2" -> '"1 2"'
SHELL_ESCAPE = '$(subst ','"'"',$1)'

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration makefile, like:
# SED := /usr/local/bin/sed
SED := sed

# escape command line argument to pass it to $(SED)
# note: unix sed do not understands \n and \t escape sequences
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides SED_EXPR
SED_EXPR = $(subst \n,\$(newline),$(subst \t,\$(tab),$(SHELL_ESCAPE)))

# print contents of given file (to stdout, for redirecting it to output file)
CAT_FILE = cat $1

# prepare printf argument, append \n
ECHO_LINE_ESCAPE = $(call SHELL_ESCAPE,$(subst \,\\,$(subst %,%%,$1))\n)

# print one line of text (to stdout, for redirecting it to output file)
# note: line must not contain $(newline)s
# note: line will be ended with LF
# NOTE: echoed line length must not exceed maximum command line length (at least 4096 characters)
ECHO_LINE = printf $(ECHO_LINE_ESCAPE)

# print lines of text to output file or to stdout (for redirecting it to output file)
# $1 - non-empty lines list, where entries are processed by $(unescape)
# $2 - if not empty, then file to print to
# $3 - text to prepend before the command when $6 is non-empty
# $4 - text to prepend before the command when $6 is empty
# $6 - empty if overwrite file $2, non-empty if append text to it
# NOTE: total text length must not exceed maximum command line length (at least 4096 characters)
ECHO_LINES = $(if $6,$3,$4)$(call ECHO_LINE,$(call tospaces,$(subst $(space),\n,$1)))$(if $2,>$(if $6,>) $2)

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with LF
# NOTE: total text length must not exceed maximum command line length (at least 4096 characters)
ECHO_TEXT = printf $(call ECHO_LINE_ESCAPE,$(subst $(newline),\n,$1))

# write lines of text $1 to file $2 by $3 lines at one time
# NOTE: any line must be less than maximum command length (at least 4096 characters)
# NOTE: number $3 must be adjusted so echoed at one time text length will not exceed maximum command length (at least 4096 characters)
WRITE_TEXT = $(call xargs,ECHO_LINES,$(subst $(newline),$$(empty) $$(empty),$(unspaces)),$3,$2,$(QUIET),,,$(newline))

# create symbolic link $2 -> $1, paths may contain spaces: '/opt/bin/my app' -> '../x y z/n m'
# note: UNIX-specific
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides CREATE_SIMLINK
CREATE_SIMLINK = ln -sf $1 $2

# set mode $1 of given file(s) $2 (short list, no more than PATH_ARGS_LIMIT), paths may contain spaces: '1 2/3 4' '5 6/7 8/9' ...
# note: UNIX-specific
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides CHANGE_MODE
CHANGE_MODE = chmod $1 $2

# execute command $2 in directory $1
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides EXECUTE_IN
EXECUTE_IN = ( cd $1 && $2 )

# delete target file(s) (short list, no more than PATH_ARGS_LIMIT) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || { $(DELETE_FILES); false; }

# standard 'install' utility
INSTALL := install

# create directory (with intermediate parent directories) while installing things
# $1 - path to directory to create, path may contain spaces, such as: '/opt/a b c'
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides INSTALL_DIR
INSTALL_DIR = $(INSTALL) -d $1

# install file(s) (long list) to directory or copy file to file
# $1 - file(s) to install (to support long list, paths _must_ be without spaces)
# $2 - destination directory or file, path may contain spaces
# $3 - optional access mode, such as 644 (rw--r--r-) or 755 (rwxr-xr-x)
# note: $6 - <empty> on first call, $(newline) on next calls
# note: $(CLEAN_BUILD_DIR)/utils/gnu.mk overrides INSTALL_FILES2
INSTALL_FILES2 = $(INSTALL) $3 $1 $2
INSTALL_FILES1 = $(if $6,$(QUIET))$(INSTALL_FILES2)
INSTALL_FILES  = $(call xcmd,INSTALL_FILES1,$1,$(PATH_ARGS_LIMIT),$2,$(addprefix -m,$3),,)

# add quotes if path has an embedded space(s):
# $(call ifaddq,a b) -> 'a b'
# $(call ifaddq,ab)  -> ab
# note: override default implementation in $(CLEAN_BUILD_DIR)/core/functions.mk
ifaddq = $(if $(findstring $(space),$1),'$1',$1)

# tools colors
LN_COLOR    := [36m
CHMOD_COLOR := [1;35m

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PRINT_ENV PATH_ARGS_LIMIT NUL DELETE_FILES DELETE_DIRS DELETE_DIRS_IF_EMPTY DELETE_FILES_IN1 DELETE_FILES_IN \
  DEL_FILES_OR_DIRS1 DEL_FILES_OR_DIRS COPY_FILES2 COPY_FILES1 COPY_FILES TOUCH_FILES1 TOUCH_FILES CREATE_DIR \
  COMPARE_FILES SHELL_ESCAPE SED SED_EXPR CAT_FILE ECHO_LINE_ESCAPE ECHO_LINE ECHO_LINES ECHO_TEXT WRITE_TEXT \
  CREATE_SIMLINK CHANGE_MODE EXECUTE_IN DEL_ON_FAIL INSTALL INSTALL_DIR INSTALL_FILES2 INSTALL_FILES1 INSTALL_FILES \
  LN_COLOR CHMOD_COLOR ifaddq)
