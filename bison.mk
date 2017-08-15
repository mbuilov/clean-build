#-----------------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#-----------------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin BISON_COMPILER)))
include $(dir $(lastword $(MAKEFILE_LIST)))impl/_bison.mk
endif
