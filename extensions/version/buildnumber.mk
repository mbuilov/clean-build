#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef cb_target_makefile
$(error 'defs.mk' must be included prior this file)
endif

tool_mode := 1

# as in $(cb_dir)/stub/c.mk
ifeq (,$(filter-out undefined environment,$(origin c_prepare_app_vars)))
include $(dir $(lastword $(MAKEFILE_LIST)))../../types/_c.mk
endif

# as in $(cb_dir)/stub/c.mk
$(call cb_prepare_templ,c_prepare_app_vars,c_define_app_rules)

exe := buildnumber S
src := buildnumber.c

$(define_targets)
