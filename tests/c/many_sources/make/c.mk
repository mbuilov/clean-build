#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/c.mk
# description:   support for building application-level targets from C/C++ sources

# Note: This file should be copied AS IS to the directory of the project build system

ifeq (,$(filter-out undefined environment,$(origin c_define_app_rules)))
include $(dir $(lastword $(MAKEFILE_LIST)))c_project.mk
endif

$(call cb_prepare_templ,c_prepare_app_vars,c_define_app_rules)
