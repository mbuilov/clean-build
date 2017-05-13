#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef DEF_HEAD_CODE_EVAL
include $(MTOP)/_defs.mk
endif

# reset
MDEPS:=

# make absolute paths to makefiles $1 with suffix $2:
# add path to directory of $(CURRENT_MAKEFILE) if makefile path is not absolute, add /Makefile if makefile path is a directory
NORM_MAKEFILES = $(patsubst %.mk/Makefile$2,%.mk$2,$(addsuffix /Makefile$2,$(patsubst %/Makefile,%,$(call FIXPATH,$1))))

# add empty rules for $(MDEPS): don't complain if order deps are not resolved when build started in sub-directory
# note: $(ORDER_DEPS) - absolute paths of dependency makefiles with '-' suffix
# note: reset MDEPS to not update ORDER_DEPS on each evaluation of STD_TARGET_VARS in target makefile
APPEND_MDEPS1 = $(if $1,$1:$(newline)ORDER_DEPS+=$1$(newline))
APPEND_MDEPS = $(call APPEND_MDEPS1,$(filter-out $(ORDER_DEPS),$(call NORM_MAKEFILES,$(MDEPS),-)))MDEPS:=

# overwrite code for adding $(MDEPS) - list of makefiles that need to be built before target makefile - to $(ORDER_DEPS)
FIX_ORDER_DEPS = $(APPEND_MDEPS)

# don't complain about new FIX_ORDER_DEPS value
# - replace old FIX_ORDER_DEPS value defined in $(MTOP)/defs.mk with a new one
$(call CLEAN_BUILD_PROTECT_VARS,FIX_ORDER_DEPS)

# $m - absolute path to makefile to include
# note: $(ORDER_DEPS) value may be changed in included makefile, so restore ORDER_DEPS before including next makefile
# note: $(TOOL_MODE) value may be changed (set) in included makefile, so restore TOOL_MODE before including next makefile
define CB_INCLUDE_TEMPLATE
$(empty)
CURRENT_MAKEFILE:=$m
ORDER_DEPS:=$(ORDER_DEPS)
TOOL_MODE:=$(TOOL_MODE)
include $m
endef

# note: $(TO_MAKE) - list of absolute paths to makefiles to include
ifdef REM_SHOWN_MAKEFILE

# non-verbose build
define CLEAN_BUILD_INCLUDE
INTERMEDIATE_MAKEFILES+=1
$(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))
endef

else # !REM_SHOWN_MAKEFILE

# verbose build
CLEAN_BUILD_INCLUDE = $(foreach m,$(TO_MAKE),$(CB_INCLUDE_TEMPLATE))

endif # !REM_SHOWN_MAKEFILE

# protect variables from modifications in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,NORM_MAKEFILES APPEND_MDEPS1 APPEND_MDEPS CB_INCLUDE_TEMPLATE CLEAN_BUILD_INCLUDE)
