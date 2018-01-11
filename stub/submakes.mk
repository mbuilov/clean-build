#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/submakes.mk
# description:   support for processing sub-makefiles - define 'process_submakes' macro

# Note: This file should be copied AS IS to the directory of the project build system

ifeq (,$(filter-out undefined environment,$(origin cb_submakes_prepare)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(CBLD_ROOT)/core/_submakes.mk
endif

$(cb_submakes_prepare)
