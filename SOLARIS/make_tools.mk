# this file included by SOLARIS/make_header.mk

DEL   = rm -f $1
RM    = $(if $(VERBOSE:1=),@)rm -rf $1
MKDIR = mkdir -p $1
SED  := sed
SED_EXPR = '$(subst \n,\$(newline),$(subst \t,\$(tab),$1))'
CAT   = cat $1
ECHO  = printf '$(subst ','"'"',$(subst $(newline),\n,$(subst \,\\,$(subst %,%%,$1))))\n'
CD    = cd $1
NUL  := /dev/null
CP    = cp $1 $2
TOUCH = touch $1

# delete target if failed to build it and exit shell with some error code
DEL_ON_FAIL = || ($(DEL); false)
