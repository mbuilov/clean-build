#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/defs.mk

DEL   = rm -f$(if $(VERBOSE),v) $1
RM    = $(if $(VERBOSE),,@)rm -rf$(if $(VERBOSE),v) $1
MKDIR = mkdir -p$(if $(VERBOSE),v) $1
SED  := sed
SED_EXPR = '$1'
CAT   = cat $1
ECHO  = printf '$(subst ','"'"',$(subst $(newline),\n,$(subst \,\\,$(subst %,%%,$1))))\n'
NUL  := /dev/null
CP    = cp$(if $(VERBOSE), -v) $1 $2
LN    = ln -sf$(if $(VERBOSE),v) $1 $2
TOUCH = touch $1
CHMOD = chmod$(if $(VERBOSE), -v) $1 $2

# execute command $2 in directory $1
EXECIN = pushd $1 >/dev/null && { $2 && popd >/dev/null || { popd >/dev/null; false; } }

# delete target if failed to build it and exit shell with some error code
DEL_ON_FAIL = || ($(DEL); false)

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,DEL RM MKDIR SED SED_EXPR CAT ECHO EXECIN NUL CP LN TOUCH CHMOD DEL_ON_FAIL)
