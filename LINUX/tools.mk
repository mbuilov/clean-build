#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/defs.mk

OSTYPE := UNIX

# delete files $1
DEL = rm -f$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# delete files and directories
# note: do not need to add $(QUIET) before $(RM)
RM = $(QUIET)rm -rf$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# to avoid races, MKDIR must be called only if destination directory does not exist
# note: MKDIR should create intermediate parent directories of destination directory
MKDIR = mkdir -p$(if $(VERBOSE),v) $1$(if $(VERBOSE), >&2)

# stream-editor executable
# note: SED value may be overridden either in command line or in project configuration file, like:
# override SED := /usr/local/bin/sed
SED := sed

# escape command line argument to pass it to $(SED)
SED_EXPR = '$1'

# print contents of given file (to stdout, for redirecting it to output file)
CAT = cat $1

# print lines of text (to stdout, for redirecting it to output file)
# note: each line will be ended with LF
ECHO = printf '$(subst ','"'"',$(subst $(newline),\n,$(subst \,\\,$(subst %,%%,$1))))\n'

# null device for redirecting output into
NUL := /dev/null

# copy preserving modification date, ownership and mode:
# - file(s) $1 to directory $2 or
# - file $1 to file $2
CP = cp -p$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# create symbolic link
# note: this tool is UNIX-specific and may be not defined for other OSes
LN = ln -sf$(if $(VERBOSE),v) $1 $2$(if $(VERBOSE), >&2)

# update modification date of given file(s) or create file(s) if they do not exist
TOUCH = touch $1

# set mode $1 of given file(s) $2
# note: this tool is UNIX-specific and may be not defined for other OSes
CHMOD = chmod$(if $(VERBOSE), -v) $1 $2$(if $(VERBOSE), >&2)

# execute command $2 in directory $1
EXECIN = pushd $1 >/dev/null && { $2 && popd >/dev/null || { popd >/dev/null; false; } }

# delete target file(s) if failed to build them and exit shell with error code 1
DEL_ON_FAIL = || { $(DEL); false; }

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DEL RM MKDIR SED SED_EXPR CAT ECHO EXECIN NUL CP LN TOUCH CHMOD DEL_ON_FAIL)
