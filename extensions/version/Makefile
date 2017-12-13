#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# note: project configuration makefile should be already processed before this file

ifeq (,$(filter-out undefined environment,$(origin PROCESS_SUBMAKES_PREPARE)))
include $(dir $(lastword $(MAKEFILE_LIST)))../../core/_submakes.mk
endif

# as in $(CLEAN_BUILD_DIR)/stub/submakes.mk
$(PROCESS_SUBMAKES_PREPARE)

$(call PROCESS_SUBMAKES,buildnumber.mk version.mk)
