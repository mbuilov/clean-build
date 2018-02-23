#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin cmp_text_rule)))
include $(dir $(lastword $(MAKEFILE_LIST)))impl/_cmp.mk
endif
