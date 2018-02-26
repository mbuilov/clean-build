#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef c_define_app_rules
$(error 'c_project.mk' of the project build system must be included prior this file)
endif

# will build 'buildnumber' tool
tool_mode := T

# as in $(cb_dir)/stub/c.mk
$(call cb_prepare_templ,c_prepare_app_vars,c_define_app_rules)

exe := buildnumber S
src := buildnumber.c

$(define_targets)
