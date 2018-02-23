#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin DO_TEST_JAR)))
include $(dir $(lastword $(MAKEFILE_LIST)))_jtest.mk
endif
