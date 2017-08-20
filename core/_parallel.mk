#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin DEF_TAIL_CODE)))
include $(dir $(lastword $(MAKEFILE_LIST)))_defs.mk
endif

# make absolute paths to makefiles $1 with suffix $2:
# add path to directory of $(TARGET_MAKEFILE) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst %.mk/Makefile$2,%.mk$2,$(addsuffix /Makefile$2,$(patsubst %/Makefile,%,$(call fixpath,$1))))

# $m - absolute path to makefile to include
# note: TOOL_MODE value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
# note: last line must be empty to allow to join multiple $(CB_INCLUDE_TEMPLATE)s together
define CB_INCLUDE_TEMPLATE
TARGET_MAKEFILE:=$m
TOOL_MODE:=$(TOOL_MODE)
include $m

endef

# remember new values of TARGET_MAKEFILE and TOOL_MODE
ifdef SET_GLOBAL1
$(eval define CB_INCLUDE_TEMPLATE$(newline)$(subst include,$$(call \
  SET_GLOBAL1,TARGET_MAKEFILE TOOL_MODE)$(newline)include,$(value CB_INCLUDE_TEMPLATE))$(newline)endef)
endif

# generate code for processing given list of makefiles
# $1 - absolute path to makefiles to include
define CLEAN_BUILD_PARALLEL
CB_INCLUDE_LEVEL+=.
$(foreach m,$1,$(CB_INCLUDE_TEMPLATE))
CB_INCLUDE_LEVEL:=$(CB_INCLUDE_LEVEL)
endef

# remember new value of CB_INCLUDE_LEVEL, without tracing calls to it because it is incremented
ifdef MCHECK
$(eval define CLEAN_BUILD_PARALLEL$(newline)$(subst \
  CB_INCLUDE_LEVEL+=.,CB_INCLUDE_LEVEL+=.$(newline)$$(call SET_GLOBAL1,CB_INCLUDE_LEVEL,0),$(value \
  CLEAN_BUILD_PARALLEL))$(newline)$$(call SET_GLOBAL1,CB_INCLUDE_LEVEL,0)$(newline)endef)
endif

ifndef TOCLEAN

# note: ORDER_DEPS value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
$(call define_prepend,CB_INCLUDE_TEMPLATE,ORDER_DEPS:=$$(ORDER_DEPS)$(newline))

# remember new value of ORDER_DEPS, without tracing calls to it because it is incremented
ifdef MCHECK
$(eval define CB_INCLUDE_TEMPLATE$(newline)$(subst include,$$(call \
  SET_GLOBAL1,ORDER_DEPS,0)$(newline)include,$(value CB_INCLUDE_TEMPLATE))$(newline)endef)
endif

# append makefiles (really PHONY targets created from them) to ORDER_DEPS list
# note: argument - list of makefiles (or directories, where Makefile is searched)
# note: add empty rules for makefile dependencies (absolute paths of dependency makefiles with '-' suffix):
#  don't complain if order deps are not resolved when build started in sub-directory
ADD_MDEPS1 = $(if $1,$(eval $1:$(newline)ORDER_DEPS+=$1))
ADD_MDEPS = $(call ADD_MDEPS1,$(filter-out $(ORDER_DEPS),$(call NORM_MAKEFILES,$1,-)))

# remember new value of ORDER_DEPS, without tracing calls to it because it is incremented
ifdef MCHECK
$(eval ADD_MDEPS1 = $(subst +=$$1,+=$$1$$(newline)$$(call SET_GLOBAL1,ORDER_DEPS,0),$(value ADD_MDEPS1)))
endif

# same as ADD_MDEPS, but accepts aliases of makefiles
# note: alias names are created via CREATE_MAKEFILE_ALIAS macro
ADD_ADEPS = $(call ADD_MDEPS1,$(filter-out $(ORDER_DEPS),$(patsubst %,MAKEFILE_ALIAS_%-,$1)))

# $(TARGET_MAKEFILE) is built if all $1 makefiles are built
# note: $(TARGET_MAKEFILE)- and other order-dependent makefile names - are .PHONY targets
# note: use order-only dependency, so normal dependencies of $(TARGET_MAKEFILE)-
#  will be only files - for the checks in $(CLEAN_BUILD_DIR)/core/all.mk
$(call define_prepend,CLEAN_BUILD_PARALLEL,.PHONY: $$(addsuffix \
  -,$$1)$(newline)$$(TARGET_MAKEFILE)-:| $$(addsuffix -,$$1)$(newline))

# show debug info
ifdef MDEBUG
$(call define_prepend,CLEAN_BUILD_PARALLEL,$$(info $$(subst \
  $$(space),,$$(CB_INCLUDE_LEVEL))$$(TARGET_MAKEFILE)$$(if $$(ORDER_DEPS), | $$(ORDER_DEPS))))
endif

else ifdef MDEBUG

# show debug info
$(call define_prepend,CLEAN_BUILD_PARALLEL,$$(info $$(subst \
  $$(space),,$$(CB_INCLUDE_LEVEL))$$(TARGET_MAKEFILE)))

endif # clean && MDEBUG

# PROCESS_SUBMAKES normally called with non-empty first argument $1,
# to not define variable 1 for next processed makefiles, this macro must
# be expanded by explicit $(call PROCESS_SUBMAKES_EVAL) without arguments
# note: call DEF_TAIL_CODE with @ - for the checks in CLEAN_BUILD_CHECK_AT_TAIL macro
#  (which is defined in $(CLEAN_BUILD_DIR)/core/protection.mk)
# note: process result of DEF_TAIL_CODE with separate $(eval) - for the checks performed while expanding $(eval argument)
PROCESS_SUBMAKES_EVAL = $(eval $(value CB_PARALLEL_CODE))$(eval $(call DEF_TAIL_CODE,@))

# generate code for including and processing given makefiles - in $(CB_PARALLEL_CODE),
#  then evaluate it via call without parameters - to hide $1 argument from makefiles
# at end, check if need to include $(CLEAN_BUILD_DIR)/core/all.mk
# note: make absolute paths to makefiles $1 to include
PROCESS_SUBMAKES = $(eval define CB_PARALLEL_CODE$(newline)$(call CLEAN_BUILD_PARALLEL,$(call \
  NORM_MAKEFILES,$1,))$(newline)endef)$(call PROCESS_SUBMAKES_EVAL)

# set CLEAN_BUILD_NEED_PARALLEL before including sub-makefiles:
# each of processed sub-makefiles must include $(CLEAN_BUILD_DIR)/parallel.mk or $(CLEAN_BUILD_DIR)/c.mk, etc...
# by including $(CLEAN_BUILD_DIR)/parallel.mk, sub-makefile will reset CLEAN_BUILD_NEED_PARALLEL
ifdef MCHECK
CLEAN_BUILD_PARALLEL_EVAL = $(eval CLEAN_BUILD_NEED_PARALLEL:=)
$(eval PROCESS_SUBMAKES = $$(if $$(CLEAN_BUILD_NEED_PARALLEL),$$(error \
  $$$$(CLEAN_BUILD_DIR)/parallel.mk was not included at head of makefile!))$(subst \
  eval ,eval CLEAN_BUILD_NEED_PARALLEL:=1$$(newline)$$(call \
  SET_GLOBAL1,CLEAN_BUILD_NEED_PARALLEL)$$(newline),$(value PROCESS_SUBMAKES)))
else
CLEAN_BUILD_PARALLEL_EVAL:=
endif

# protect variables from modifications in target makefiles
# note: do not complain about new ADD_MDEPS and ADD_ADEPS values
# - replace ADD_MDEPS and ADD_ADEPS values defined in $(CLEAN_BUILD_DIR)/core/_defs.mk with new ones
$(call SET_GLOBAL,NORM_MAKEFILES CB_INCLUDE_TEMPLATE=ORDER_DEPS;TOOL_MODE CLEAN_BUILD_PARALLEL \
  ADD_MDEPS1 ADD_MDEPS=ORDER_DEPS=ORDER_DEPS ADD_ADEPS=ORDER_DEPS=ORDER_DEPS \
  PROCESS_SUBMAKES_EVAL=CB_PARALLEL_CODE PROCESS_SUBMAKES CLEAN_BUILD_PARALLEL_EVAL)
