# this file included by $(MTOP)/SOLARIS/make_c.mk

DEL   = rm -f $1
RM    = $(if $(VERBOSE),,@)rm -rf $1
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

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,DEL RM MKDIR SED SED_EXPR CAT ECHO CD NUL CP TOUCH DEL_ON_FAIL)
