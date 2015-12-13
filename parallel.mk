ifndef DEFS_MK_INCLUDED
# set DEFS_MK_INCLUDED_BY value - don't execute $(DEF_HEAD_CODE) in $(MTOP)/defs.mk - we'll execute it below
DEFS_MK_INCLUDED_BY := parallel.mk
include $(MTOP)/defs.mk
endif

ifndef NORM_MAKEFILES

# make $(TOP)-related paths to makefiles $1 with suffix $2:
# add $(VPREFIX) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst $(TOP)/%,%$2,$(abspath $(foreach \
  x,$1,$(if $(call isrelpath,$x),$(VPREFIX))$x$(if $(filter-out %.mk %/Makefile Makefile,$x),/Makefile))))

# trace function call if TRACE defined
$(call trace_calls2,NORM_MAKEFILES,VPREFIX)

# overwrite code for adding $(MDEPS) - list of makefiles that need to be maked before target makefile - to $(ORDER_DEPS)
FIX_ORDER_DEPS := ORDER_DEPS := $$(strip $$(ORDER_DEPS) $$(call NORM_MAKEFILES,$$(MDEPS),-))$(newline)MDEPS:=

# dump in TRACE mode that FIX_ORDER_DEPS was changed
$(call dump,FIX_ORDER_DEPS,$$(MTOP)/parallel.mk)

# don't complain about changed FIX_ORDER_DEPS value
$(call CLEAN_BUILD_REPLACE_PROTECTED_VARS,FIX_ORDER_DEPS)

# $m - next $(TOP)-related makefile to include
# NOTE: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# NOTE: $(TOOL_MODE) value may be changed in included makefile, so restore TOOL_MODE before including next makefile
define CB_INCLUDE_TEMPLATE1
$(empty)
VPREFIX := $(call GET_VPREFIX,$m)
CURRENT_MAKEFILE := $m
ORDER_DEPS := $(ORDER_DEPS)
TOOL_MODE := $(TOOL_MODE)
$$(call dump,VPREFIX CURRENT_MAKEFILE ORDER_DEPS TOOL_MODE,$$$$(MTOP)/parallel.mk)
include $(TOP)/$m
endef

# note: $(TO_MAKE) - list of $(TOP)-related makefiles to include
CB_INCLUDE_TEMPLATE = $(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE1))
$(call trace_calls,CB_INCLUDE_TEMPLATE,TO_MAKE)

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_APPEND_PROTECTED_VARS,NORM_MAKEFILES CB_INCLUDE_TEMPLATE1 CB_INCLUDE_TEMPLATE)

endif # NORM_MAKEFILES

# DEF_HEAD_CODE_PROCESSED may be set specially to avoid evaluating $(DEF_HEAD_CODE) here
# - if $(MTOP)/defs.mk was included and processed before including this $(MTOP)/parallel.mk
ifndef DEF_HEAD_CODE_PROCESSED
# this sets DEF_HEAD_CODE_PROCESSED
$(eval $(DEF_HEAD_CODE))
endif
# allow to execute $(DEF_HEAD_CODE) in next included $(MTOP)/parallel.mk
DEF_HEAD_CODE_PROCESSED:=

# add $(TOP)-related list of makefiles that need to be maked before current makefile - to $(ORDER_DEPS)
# - list of order-only dependencies of targets of current makefile
ORDER_DEPS := $(strip $(ORDER_DEPS) $(call NORM_MAKEFILES,$(MDEPS),-))
$(call dump,ORDER_DEPS MDEPS,$$(MTOP)/parallel.mk)

# reset $(MDEPS) - next included makefile may have it's own dependencies
MDEPS:=

# avoid errors in $(CLEAN_BUILD_CHECK_AT_HEAD) in next included makefile
CLEAN_BUILD_NEED_TAIL_CODE:=

# show debug info now, not later in $(DEF_TAIL_CODE)
ifdef MDEBUG
$(info $(call MAKEFILES_LEVEL,$(CB_INCLUDE_LEVEL))$(CURRENT_MAKEFILE)$(if $(ORDER_DEPS), | $(ORDER_DEPS:-=)))
endif

# make $(TOP)-related list of makefiles to include
TO_MAKE := $(call NORM_MAKEFILES,$(TO_MAKE))
$(call dump,TO_MAKE)

# $(CURRENT_MAKEFILE) is built if all $(TO_MAKE) makefiles are built
# note: $(CURRENT_MAKEFILE)- and other order-dependent makefile names - are .PHONY targets,
# and built target files may dependend on .PHONY targets only as order-only,
# otherwise target files are will always be rebuilt because .PHONY targets are always updated
$(CURRENT_MAKEFILE)-: $(addsuffix -,$(TO_MAKE))

# increase makefile include level, include and process makefiles, decrease makefile include level
CB_INCLUDE_LEVEL := $(CURRENT_MAKEFILE) $(CB_INCLUDE_LEVEL)
$(eval $(CB_INCLUDE_TEMPLATE))
CB_INCLUDE_LEVEL := $(wordlist 2,999999,$(CB_INCLUDE_LEVEL))

# check if need to include $(MTOP)/all.mk
# NOTE: call DEF_TAIL_CODE with @ - to not show debug info that was already shown above
$(eval $(call DEF_TAIL_CODE,@))
