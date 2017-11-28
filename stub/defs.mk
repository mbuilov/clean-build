#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for building generic targets - define DEFINE_TARGETS macro

# Note: this file should be copied AS IS to a custom project's build system directory 'make'

ifeq (,$(filter-out undefined environment,$(origin PREPARE_TARGET_TYPE)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
endif

$(PREPARE_TARGET_TYPE)
