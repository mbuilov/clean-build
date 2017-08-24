#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/core/_defs.mk

# print prepared environment in verbose mode
PRINT_ENV = $(info for v in `env | cut -d= -f1`; do $(foreach \
  x,PATH SHELL $(PASS_ENV_VARS),[ "$x" = "$$v" ] ||) unset "$$v"; done$(foreach \
  v,PATH SHELL $(PASS_ENV_VARS),$(newline)$v='$($v)'$(newline)export $v))

# delete files $1 (short list), paths may contain spaces: '1 2\3 4' '5 6\7 8\9' ...
DEL = rm -f $1

# delete directories $1 (short list), paths may contain spaces: '1 2\3 4' '5 6\7 8\9' ...
RMDIR = $(RM)

# in directory $1 (path may contain spaces), delete files $2 (long list), to support long list, paths _must_ be without spaces
DELIN = pushd $1 >/dev/null && { $(call RM,$2) && popd >/dev/null || { popd >/dev/null; false; } }

# delete files and directories (long list), to support long list, paths _must_ be without spaces
RM = rm -rf $1

# copy preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 (paths to files $1 _must_ be without spaces, but path to directory $2 may contain spaces) or
# - file $1 to file $2         (path to file $1 _must_ be without spaces, but path to file $2 may contain spaces)
CP = cp -p $1 $2

# update modification date of given file(s) or create file(s) if they do not exist
# note: paths may contain spaces, but list of files should be short
TOUCH = touch $1

# create directory, path may contain spaces: '1 2\3 4'
# to avoid races, MKDIR must be called only if it's known that destination directory does not exist
# note: MKDIR must create intermediate parent directories of destination directory
MKDIR = mkdir -p $1

# compare content of two text files: $1 and $2
# return an error if they are differ
CMP = cmp $1 $2

# escape program argument to pass it via shell: "1 2" -> '"1 2"'
SHELL_ESCAPE = '$(subst ','"'"',$1)'

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration file, like:
# SED := /usr/local/bin/sed
SED := sed

# escape command line argument to pass it to $(SED)
SED_EXPR = $(call SHELL_ESCAPE,$(subst \n,\$(newline),$(subst \t,\$(tab),$1)))

# print contents of given file (to stdout, for redirecting it to output file)
CAT = cat $1

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with LF
ECHO = printf '$(subst ','"'"',$(subst $(newline),\n,$(subst \,\\,$(subst %,%%,$1))))\n'

# write lines of text $1 to file $2 by $3 lines at one time
WRITE = $(ECHO) > $2

# null device for redirecting output into
NUL := /dev/null

# create symbolic link
# note: this tool is UNIX-specific and may be not defined for other OSes
LN = ln -sf $1 $2

# set mode $1 of given file(s) $2
# note: paths may contain spaces, but list of files should be short
# note: this tool is UNIX-specific and may be not defined for other OSes
CHMOD = chmod $1 $2

# execute command $2 in directory $1
EXECIN = pushd $1 >/dev/null && { $2 && popd >/dev/null || { popd >/dev/null; false; } }

# delete target file(s) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || { $(DEL); false; }

# add quotes if path has an embedded space:
# $(call ifaddq,a b) -> 'a b'
# $(call ifaddq,ab)  -> ab
# note: override default implementation in $(CLEAN_BUILD_DIR)/core/functions.mk
ifaddq = $(if $(findstring $(space),$1),'$1',$1)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PRINT_ENV DEL RMDIR DELIN RM CP TOUCH MKDIR CMP SHELL_ESCAPE SED SED_EXPR CAT \
  ECHO WRITE NUL LN CHMOD EXECIN DEL_ON_FAIL ifaddq)
