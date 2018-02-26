#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef cb_prepare_templ
$(error 'project.mk' of the project build system must be included prior this file)
endif

# as in $(cb_dir)/stub/submakes.mk
ifeq (,$(filter-out undefined environment,$(origin cb_submakes_prepare)))
include $(cb_dir)/core/_submakes.mk
endif

$(cb_submakes_prepare)

$(call process_submakes,buildnumber.mk version.mk)
