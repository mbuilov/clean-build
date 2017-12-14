#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(clean_build_dir)/stub/submakes.mk
# description:   support for processing sub-makefiles - define process_submakes macro

# Note: This file should be copied AS IS to the directory of the project build system

ifeq (,$(filter-out undefined environment,$(origin process_submakes_prepare)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(CLEAN_BUILD)/core/_submakes.mk
endif

$(process_submakes_prepare)
