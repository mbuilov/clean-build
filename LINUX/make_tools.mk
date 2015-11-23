# this file included by $(MTOP)/LINUX/make_c.mk

DEL   = rm -f$(if $(VERBOSE:0=),v) $1
RM    = $(if $(VERBOSE:1=),@)rm -rf$(if $(VERBOSE:0=),v) $1
MKDIR = mkdir -p$(if $(VERBOSE:0=),v) $1
SED  := sed
SED_EXPR = '$1'
CAT   = cat $1
ECHO  = printf '$(subst ','"'"',$(subst $(newline),\n,$(subst \,\\,$(subst %,%%,$1))))\n'
CD    = cd $1
NUL  := /dev/null
CP    = cp $(if $(VERBOSE:0=),-v) $1 $2
TOUCH = touch $1

# delete target if failed to build it and exit shell with some error code
DEL_ON_FAIL = || ($(DEL); false)
