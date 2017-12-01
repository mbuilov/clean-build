#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for processing sub-makefiles

# Note: $(CLEAN_BUILD_DIR)/core/_defs.mk must be included prior this file

# name of file to look for if makefile is specified by directory path
DEFAULT_MAKEFILE_NAME := Makefile

# recognized extensions and names of makefiles
MAKEFILE_PATTERNS := .mk .mak /makefile /$(DEFAULT_MAKEFILE_NAME)

# generate code of NORM_MAKEFILES macro - multiple patsubsts, such as:
# $(patsubst %/Makefile/Makefile,%/Makefile,$(patsubst %.mak/Makefile,%.mak,...))
NORM_MAKEFILES = $(if $1,$(call NORM_MAKEFILES,$(wordlist 2,999999,$1),$$(patsubst \
  %$(firstword $1)/$(DEFAULT_MAKEFILE_NAME),%$(firstword $1),$2)),$2)

# NORM_MAKEFILES - make absolute paths to makefiles $1, assuming some of them may be specified by directory path:
# 1) add path to directory of $(TARGET_MAKEFILE) if makefile path is not absolute
# 2) add /Makefile if makefile path do not ends with any of $(MAKEFILE_PATTERNS) (i.e. specified by a directory)
# e.g.: $(call NORM_MAKEFILES,/d/aa bb.mk) -> /d/aa/Makefile /c/bb.mk
$(eval NORM_MAKEFILES = $(call NORM_MAKEFILES,$(MAKEFILE_PATTERNS),$$(addsuffix /$(DEFAULT_MAKEFILE_NAME),$$(call fixpath,$$1))))

# $m - absolute path to makefile to include
# $2 - current TOOL_MODE value
# note: TOOL_MODE value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
# note: last line must be empty to allow to join multiple $(CB_INCLUDE_TEMPLATE)s together
define CB_INCLUDE_TEMPLATE
TOOL_MODE:=$2
TARGET_MAKEFILE:=$m
include $m

endef

# remember new value of TARGET_MAKEFILE
# note: TOOL_MODE value will be saved in DEF_HEAD_CODE
ifdef SET_GLOBAL1
$(eval define CB_INCLUDE_TEMPLATE$(newline)$(subst include,$$(call \
  SET_GLOBAL1,TARGET_MAKEFILE)$(newline)include,$(value CB_INCLUDE_TEMPLATE))$(newline)endef)
endif

# generate code for processing given list of makefiles
# $1 - absolute paths to makefiles to include
# $2 - current TOOL_MODE value
define CLEAN_BUILD_PARALLEL
CB_INCLUDE_LEVEL+=.
$(foreach m,$1,$(CB_INCLUDE_TEMPLATE))
CB_INCLUDE_LEVEL:=$(CB_INCLUDE_LEVEL)
endef

# remember new value of CB_INCLUDE_LEVEL, without tracing calls to it because it is incremented
# note: assume result of $(call SET_GLOBAL1,...,0) will give an empty line at end of expansion
ifdef MCHECK
$(eval define CLEAN_BUILD_PARALLEL$(newline)$(subst \
  CB_INCLUDE_LEVEL+=.$(newline),CB_INCLUDE_LEVEL+=.$(newline)$$(call SET_GLOBAL1,CB_INCLUDE_LEVEL,0),$(value \
  CLEAN_BUILD_PARALLEL))$(newline)$$(call SET_GLOBAL1,CB_INCLUDE_LEVEL,0)$(newline)endef)
endif

ifndef TOCLEAN

# note: ORDER_DEPS value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
$(call define_prepend,CB_INCLUDE_TEMPLATE,ORDER_DEPS:=$$(ORDER_DEPS)$(newline))

# remember new value of ORDER_DEPS, without tracing calls to it because it is incremented
ifdef MCHECK
$(eval define CB_INCLUDE_TEMPLATE$(newline)$(subst include,$$(call \
  SET_GLOBAL1,ORDER_DEPS,0)include,$(value CB_INCLUDE_TEMPLATE))$(newline)endef)
endif

# append makefiles (really PHONY targets created from them) to ORDER_DEPS list
# note: argument $1 - list of makefiles (or directories, where Makefile is searched)
# note: add empty rules for makefile dependencies (absolute paths of dependency makefiles with '-' suffix):
#  don't complain if order deps are not resolved when build started in sub-directory
ADD_MDEPS1 = $(if $1,$(eval $1:$(newline)ORDER_DEPS+=$1))
ADD_MDEPS = $(call ADD_MDEPS1,$(filter-out $(ORDER_DEPS),$(NORM_MAKEFILES:=-)))

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

else ifdef MDEBUG # clean

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

# generate code for including and processing given list of makefiles $1 - in $(CB_PARALLEL_CODE),
#  then evaluate it via call without parameters - to hide $1 argument from makefiles
# at end, check if need to include $(CLEAN_BUILD_DIR)/core/all.mk
# note: make absolute paths to makefiles to include
PROCESS_SUBMAKES = $(eval define CB_PARALLEL_CODE$(newline)$(call \
  CLEAN_BUILD_PARALLEL,$(NORM_MAKEFILES),$(TOOL_MODE))$(newline)endef)$(call PROCESS_SUBMAKES_EVAL)

# TOOL_MODE is reset to $(TOOL_MODE_ERROR) after reading it in $(CLEAN_BUILD_PARALLEL)/core/_defs.mk
ifdef MCHECK
$(eval PROCESS_SUBMAKES = $(subst $$(TOOL_MODE),$$(if $$(findstring \
  $$$$(TOOL_MODE_ERROR),$$(value TOOL_MODE)),$$(TMD),$$(TOOL_MODE)),$(value PROCESS_SUBMAKES)))
endif

# set CLEAN_BUILD_NEED_PARALLEL to non-empty value before including sub-makefiles - to check if a
#  sub-makefile calls PROCESS_SUBMAKES, it _must_ evaluate PROCESS_SUBMAKES_PREPARE prior PROCESS_SUBMAKES
#  (by including appropriate makefile of project build system - 'make/parallel.mk') before the call
ifdef MCHECK
PROCESS_SUBMAKES_PREPARE = $(eval CLEAN_BUILD_NEED_PARALLEL:=)
$(eval PROCESS_SUBMAKES = $$(if $$(CLEAN_BUILD_NEED_PARALLEL),$$(error \
  parallel.mk was not included at head of makefile!))$(subst \
  eval ,eval CLEAN_BUILD_NEED_PARALLEL:=1$$(newline)$$(call \
  SET_GLOBAL1,CLEAN_BUILD_NEED_PARALLEL)$$(newline),$(value PROCESS_SUBMAKES)))
else
PROCESS_SUBMAKES_PREPARE:=
endif

# makefile parsing first phase variables
CLEAN_BUILD_FIRST_PHASE_VARS += CB_INCLUDE_TEMPLATE CLEAN_BUILD_PARALLEL \
  ADD_MDEPS1 PROCESS_SUBMAKES_EVAL PROCESS_SUBMAKES PROCESS_SUBMAKES_PREPARE

# protect CLEAN_BUILD_FIRST_PHASE_VARS from modification in target makefiles,
# do not trace calls to CLEAN_BUILD_FIRST_PHASE_VARS because it's modified via += operator
$(call SET_GLOBAL,CLEAN_BUILD_FIRST_PHASE_VARS,0)

# protect variables from modifications in target makefiles
# note: do not complain about new ADD_MDEPS and ADD_ADEPS values
# - replace ADD_MDEPS and ADD_ADEPS values defined in $(CLEAN_BUILD_DIR)/core/_defs.mk with new ones
$(call SET_GLOBAL,DEFAULT_MAKEFILE_NAME MAKEFILE_PATTERNS NORM_MAKEFILES CB_INCLUDE_TEMPLATE=ORDER_DEPS;m \
  CLEAN_BUILD_PARALLEL ADD_MDEPS1 ADD_MDEPS=ORDER_DEPS=ORDER_DEPS ADD_ADEPS=ORDER_DEPS=ORDER_DEPS \
  PROCESS_SUBMAKES_EVAL=CB_PARALLEL_CODE PROCESS_SUBMAKES PROCESS_SUBMAKES_PREPARE)
