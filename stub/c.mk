#-----------------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#-----------------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/c.mk
# description:   support for building application-level targets from C/C++ sources

# Note: This file should be copied to the directory of the project build system

ifeq (,$(filter-out undefined environment,$(origin cb_c_prepare_app_vars)))
include $(dir $(lastword $(MAKEFILE_LIST)))project.mk
include $(CBLD_ROOT)/types/_c.mk
# Note: if needed, override clean-build definitions here
endif

$(call cb_prepare_templ,cb_c_prepare_app_vars,cb_c_define_app_rules)
