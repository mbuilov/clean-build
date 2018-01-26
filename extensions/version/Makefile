#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifndef cb_submakes_prepare
$(error 'submakes.mk' must be included prior this file)
endif

# as in $(cb_dir)/stub/submakes.mk
$(cb_submakes_prepare)

$(call process_submakes,buildnumber.mk version.mk)
