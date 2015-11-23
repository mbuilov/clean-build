ifndef MAKE_DEFS_INCLUDED
# don't execute $(DEF_HEAD_CODE) in make_defs.mk - we'll execute it below
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

# makefile include level
SUB_LEVEL := $(CURRENT_MAKEFILE) $(SUB_LEVEL)

# assume $(CURRENT_MAKEFILE) is built after all $(TO_MAKE) makefiles are built - extract dependencies
# $(TO_MAKE) list is something like: gen1.mk gen2.mk cmn.mk|gen1.mk,gen2.mk serv.mk|cmn.mk
# note: $(CURRENT_MAKEFILE) and other $(TOP)-related makefile names - are .PHONY targets,
# so target files may dependend on .PHONY targets only as order-only
# (otherwise target files are will always be rebuilt because .PHONY targets are always updated)
$(CURRENT_MAKEFILE): $(foreach x,$(TO_MAKE),$(call MAKE_TOP_MAKEFILE,$(firstword $(subst |, ,$x))))

# $1 - next makefile to include, $2 - dependent makefiles, $3 - VPREFIX, $4 - $(TOP)-related CURRENT_MAKEFILE
define INCLUDE_TEMPLATE
$(empty)
VPREFIX := $3
CURRENT_MAKEFILE := $4
ORDER_DEPS := $(sort $(ORDER_DEPS) $(call GET_MAKEFILE_DEPS,$2))
include $1
endef

# $1 - makefile to include, $2 - dependent makefiles, $3 - $(VPREFIX)
INCLUDE_TEMPLATE3 = $(call INCLUDE_TEMPLATE,$1,$2,$3,$(call MAKE_TOP_MAKEFILE1,$1,$3))

# $1 - makefile to include, $2 - dependent makefiles
INCLUDE_TEMPLATE2 = $(call INCLUDE_TEMPLATE3,$1,$2,$(call GET_VPREFIX,$1))

# $1 - makefile$(space)comma-separated dependent makefiles
INCLUDE_TEMPLATE1 = $(call INCLUDE_TEMPLATE2,$(call NORM_MAKEFILE,$(firstword $1)),$(subst $(comma), ,$(word 2,$1)))

$(eval $(foreach x,$(TO_MAKE),$(call INCLUDE_TEMPLATE1,$(subst |, ,$x))))

SUB_LEVEL := $(wordlist 2,999999,$(SUB_LEVEL))

ifdef TOOL_MODE
$(error $$(DEF_TAIL_CODE) was not evaluated at end of target makefile!)
endif

$(DEF_TAIL_CODE)
