#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# note: project configuration makefile should be already processed before this file

TOOL_MODE := 1

ifeq (,$(filter-out undefined environment,$(origin C_PREPARE_APP_VARS)))
include $(dir $(lastword $(MAKEFILE_LIST)))../../types/_c.mk
endif

# as in $(CLEAN_BUILD_DIR)/stub/c.mk
$(call CB_PREPARE_TARGET_TYPE,C_PREPARE_APP_VARS,C_DEFINE_APP_RULES)

EXE := buildnumber S
SRC := buildnumber.c

$(DEFINE_TARGETS)
