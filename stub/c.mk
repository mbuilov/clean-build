#-----------------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#-----------------------------------------------------------------------------------------

# add support for building application-level targets from C/C++ sources

# Note: this file should be copied AS IS to a custom project's build system directory 'make'

ifeq (,$(filter-out undefined environment,$(origin C_PREPARE_APP_VARS)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(MTOP)/types/_c.mk
endif

$(call CB_PREPARE_TARGET_TYPE,C_PREPARE_APP_VARS,C_DEFINE_APP_RULES)
