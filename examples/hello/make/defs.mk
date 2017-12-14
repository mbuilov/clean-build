#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(clean_build_dir)/stub/defs.mk
# description:   support for building generic targets - define define_targets macro

# Note: This file should be copied AS IS to the directory of the project build system

ifeq (,$(filter-out undefined environment,$(origin cb_prepare_target_type)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
endif

$(cb_prepare_target_type)
