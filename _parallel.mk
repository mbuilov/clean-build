#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin DEF_HEAD_CODE)))
include $(dir $(lastword $(MAKEFILE_LIST)))_defs.mk
endif

# initial reset
MDEPS:=

# make absolute paths to makefiles $1 with suffix $2:
# add path to directory of $(TARGET_MAKEFILE) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst %.mk/Makefile$2,%.mk$2,$(addsuffix /Makefile$2,$(patsubst %/Makefile,%,$(call fixpath,$1))))

# add empty rules for $(MDEPS): don't complain if order deps are not resolved when build started in sub-directory
# note: $(ORDER_DEPS) - absolute paths of dependency makefiles with '-' suffix
# note: reset MDEPS to not update ORDER_DEPS on each evaluation of STD_TARGET_VARS in target makefile
APPEND_MDEPS1 = $(if $1,$1:$(newline)ORDER_DEPS+=$1$(newline))
APPEND_MDEPS = $(if $(MDEPS),$(call APPEND_MDEPS1,$(filter-out $(ORDER_DEPS),$(call NORM_MAKEFILES,$(MDEPS),-)))$(eval MDEPS:=))

# overwrite code for adding $(MDEPS) - list of makefiles that need to be built before target makefile - to $(ORDER_DEPS)
$(eval FIX_ORDER_DEPS = $(value APPEND_MDEPS))

# $m - absolute path to makefile to include
# note: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# note: $(TOOL_MODE) value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
# note: first line must be empty
define CB_INCLUDE_TEMPLATE

TARGET_MAKEFILE:=$m
ORDER_DEPS:=$(ORDER_DEPS)
TOOL_MODE:=$(TOOL_MODE)
include $m
endef

# build CLEAN_BUILD_PARALLEL macro, which generates code for processing given makefiles

# add list of makefiles $(MDEPS) that need to be built before current makefile to
# $(ORDER_DEPS) - list of order-only dependencies of targets of current makefile,
# then reset $(MDEPS) - next included makefile may have it's own dependencies
CLEAN_BUILD_PARALLEL = $(eval $(APPEND_MDEPS))

# show debug info now - later, after processing all included makefiles,
# DEF_TAIL_CODE will be called with @ - to suppress showing debug info.
# note: debug info shows $(ORDER_DEPS), so ORDER_DEPS must be set before showing the info
ifdef MDEBUG
$(eval CLEAN_BUILD_PARALLEL = $(value CLEAN_BUILD_PARALLEL)$$(info $$(MAKEFILE_DEBUG_INFO)))
endif

# $(TARGET_MAKEFILE) is built if all $$1 makefiles are built
# note: $(TARGET_MAKEFILE)- and other order-dependent makefile names - are .PHONY targets,
# and built target files may depend on .PHONY targets only as order-only,
# otherwise target files are will always be rebuilt - because .PHONY targets are always updated
ifndef TOCLEAN
$(eval CLEAN_BUILD_PARALLEL = $(value CLEAN_BUILD_PARALLEL)$$(TARGET_MAKEFILE)-:| $$(addsuffix -,$$1)$(newline))
endif

# increase makefile include level,
# include and process makefiles $$1,
# decrease makefile include level
$(call define_append,CLEAN_BUILD_PARALLEL,CB_INCLUDE_LEVEL+=.$$(foreach \
  m,$$1,$$(CB_INCLUDE_TEMPLATE))$(newline)CB_INCLUDE_LEVEL:=$$(CB_INCLUDE_LEVEL))

# remember number of intermediate non-target makefiles if build is non-verbose
ifdef ADD_SHOWN_PERCENTS
$(call define_append,CLEAN_BUILD_PARALLEL,$(newline)PROCESSED_MAKEFILES+=$$(TARGET_MAKEFILE)-$(newline)INTERMEDIATE_MAKEFILES+=1)
endif

# at last, check if need to include $(CLEAN_BUILD_DIR)/all.mk
# NOTE: call DEF_TAIL_CODE with @ - to not show debug info that was already shown above
#  and for the checks in $(CLEAN_BUILD_CHECK_AT_TAIL) at $(CLEAN_BUILD_DIR)/protection.mk
$(call define_append,CLEAN_BUILD_PARALLEL,$(newline)$$$$(eval $$$$(call DEF_TAIL_CODE,@)))

# PROCESS_SUBMAKES normally called with non-empty first argument $1
# to not define variable 1 for next processed makefiles,
# this macro must be expanded by explicit $(call PROCESS_SUBMAKES_EVAL)
PROCESS_SUBMAKES_EVAL = $(eval $(value CB_PARALLEL_CODE))

# generate code for processing given makefiles - in $(CB_PARALLEL_CODE), then evaluate it
# note: make absolute paths to makefiles to include $1
PROCESS_SUBMAKES = $(eval define CB_PARALLEL_CODE$(newline)$(call CLEAN_BUILD_PARALLEL,$(call \
  NORM_MAKEFILES,$1,))$(newline)endef)$(call PROCESS_SUBMAKES_EVAL)

# protect variables from modifications in target makefiles
# note: don't complain about new FIX_ORDER_DEPS value
# - replace old FIX_ORDER_DEPS value defined in $(CLEAN_BUILD_DIR)/defs.mk with a new one
$(call CLEAN_BUILD_PROTECT_VARS,NORM_MAKEFILES APPEND_MDEPS1 APPEND_MDEPS=MDEPS;ORDER_DEPS FIX_ORDER_DEPS=MDEPS;ORDER_DEPS \
  CB_INCLUDE_TEMPLATE=ORDER_DEPS;TOOL_MODE CLEAN_BUILD_PARALLEL PROCESS_SUBMAKES_EVAL=CB_PARALLEL_CODE PROCESS_SUBMAKES)
