#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# normally, some project configuration file should be processed before this file
# tip: this file may be built individually via:
# make --eval 'include my_project.mk' -f <this makefile>

include $(dir $(lastword $(MAKEFILE_LIST)))../../parallel.mk

$(call PROCESS_SUBMAKES,buildnumber.mk version.mk)
