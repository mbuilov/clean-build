#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef CB_INCLUDE
include $(MTOP)/_parallel.mk
endif

# if $(MTOP)/defs.mk was included and processed before including this $(MTOP)/parallel.mk
# then DEF_HEAD_CODE_PROCESSED will be defined
ifndef DEF_HEAD_CODE_PROCESSED
$(DEF_HEAD_CODE_EVAL)
endif

# allow to evaluate $(DEF_HEAD_CODE_EVAL) in next included $(MTOP)/parallel.mk
DEF_HEAD_CODE_PROCESSED:=

# add $(TOP)-related list of makefiles that need to be built before current makefile to $(ORDER_DEPS)
# - list of order-only dependencies of targets of current makefile
# reset $(MDEPS) - next included makefile may have it's own dependencies
$(eval $(APPEND_MDEPS))

# avoid errors in $(CLEAN_BUILD_CHECK_AT_HEAD) in next included makefile
CLEAN_BUILD_NEED_TAIL_CODE:=

# show debug info now, not later in $(DEF_TAIL_CODE)
ifdef MDEBUG
$(info $(MAKEFILE_DEBUG_INFO))
endif

# make $(TOP)-related list of makefiles to include
TO_MAKE := $(call NORM_MAKEFILES,$(TO_MAKE))

# $(CURRENT_MAKEFILE) is built if all $(TO_MAKE) makefiles are built
# note: $(CURRENT_MAKEFILE)- and other order-dependent makefile names - are .PHONY targets,
# and built target files may depend on .PHONY targets only as order-only,
# otherwise target files are will always be rebuilt - because .PHONY targets are always updated
$(CURRENT_MAKEFILE)-: $(addsuffix -,$(TO_MAKE))

# increase makefile include level, include and process makefiles, decrease makefile include level
CB_INCLUDE_LEVEL += 1
$(eval $(CB_INCLUDE))
CB_INCLUDE_LEVEL := $(wordlist 2,999999,$(CB_INCLUDE_LEVEL))

# check if need to include $(MTOP)/all.mk
# NOTE: call DEF_TAIL_CODE with @ - to not show debug info that was already shown above
$(eval $(call DEF_TAIL_CODE,@))
