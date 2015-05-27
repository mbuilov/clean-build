ifndef MAKE_DEFS_INCLUDED
# don't execute $(DEF_HEAD_CODE) in make_defs.mk
MAKE_DEFS_INCLUDED_BY := make_parallel.mk
include $(MTOP)/make_defs.mk
endif

# DEF_HEAD_CODE_PROCESSED may be set specially to avoid evaluating $(DEF_HEAD_CODE) here
ifndef DEF_HEAD_CODE_PROCESSED
# this sets DEF_HEAD_CODE_PROCESSED
$(eval $(DEF_HEAD_CODE))
endif
# allow to execute $(DEF_HEAD_CODE) in next included make_parallel.mk
DEF_HEAD_CODE_PROCESSED:=

SUB_LEVEL := $(CURRENT_MAKEFILE_TM) $(SUB_LEVEL)

# add $(VPREFIX) if makefile $1 is not $(TOP)-related, add /Makefile if $1 is a directory
NORM_MAKEFILE = $(if $(filter-out $(TOP)/%,$1),$(VPREFIX))$1$(if $(filter-out %.mk,$1),/Makefile)

# compute VPREFIX to included normalized makefile $1
GET_VPREFIX = $(if $(filter $(TOP)/%,$1),$(call reldir,$(CURDIR),$(dir $1)),$(filter-out ./,$(dir $(call normp,$1))))

# make $(TOP)-relative path to included makefile $1, $2 - VPREFIX for included makefile
MAKE_CURRENT_MAKEFILE1 = $(call normp,$(patsubst $(TOP)/%,%,$(CURDIR)/)$2$(notdir $1))
MAKE_CURRENT_MAKEFILE2 = $(call MAKE_CURRENT_MAKEFILE1,$1,$(call GET_VPREFIX,$1))
MAKE_CURRENT_MAKEFILE = $(call MAKE_CURRENT_MAKEFILE2,$(call NORM_MAKEFILE,$1))

# $(TO_MAKE) list is something like:
# gen1.mk gen2.mk cmn.mk:gen1.mk,gen2.mk serv.mk:cmn.mk
$(CURRENT_MAKEFILE_TM): $(foreach x,$(TO_MAKE),$(call MAKE_MAKEFILE_TIMESTAMP,$(call \
  MAKE_CURRENT_MAKEFILE,$(firstword $(subst $$(TOP),$(TOP)/,$(subst :, ,$(subst $(TOP)/,$$(TOP),$x)))))))

# $1 - next makefile to include, $2 - deps list, $3 - VPREFIX, $4 - $(TOP)-related CURRENT_MAKEFILE
define INCLUDE_TEMPLATE
$(empty)
VPREFIX := $3
CURRENT_MAKEFILE := $4
CURRENT_DEPS := $(strip $(CURRENT_DEPS) $(foreach x,$2,$(call MAKE_MAKEFILE_TIMESTAMP,$(call MAKE_CURRENT_MAKEFILE,$x))))
CURRENT_MAKEFILE_TM := $(call MAKE_MAKEFILE_TIMESTAMP,$4)
include $1
endef

# $1 - makefile to include, $2 - dependencies list, $3 - $(VPREFIX)
INCLUDE_TEMPLATE3 = $(call INCLUDE_TEMPLATE,$1,$2,$3,$(call MAKE_CURRENT_MAKEFILE1,$1,$3))

# $1 - makefile to include, $2 - dependencies list
INCLUDE_TEMPLATE2 = $(call INCLUDE_TEMPLATE3,$1,$2,$(call GET_VPREFIX,$1))

# $1 - makefile$(space)comma-separated dependencies
INCLUDE_TEMPLATE1 = $(call INCLUDE_TEMPLATE2,$(call NORM_MAKEFILE,$(firstword $1)),$(subst $(comma), ,$(word 2,$1)))

$(eval $(foreach x,$(TO_MAKE),$(call INCLUDE_TEMPLATE1,$(subst $$(TOP),$(TOP)/,$(subst :, ,$(subst $(TOP)/,$$(TOP),$x))))))

SUB_LEVEL := $(wordlist 2,999999,$(SUB_LEVEL))

ifdef TOOL_MODE
$(error $$(DEF_TAIL_CODE) was not evaluated at end of target makefile!)
endif

$(DEF_TAIL_CODE)
