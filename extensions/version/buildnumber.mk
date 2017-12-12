#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# note: some project configuration makefile should be already processed before this file,
#  variable TOP must be overridden.
# tip: this file may be built individually via:
# make --eval 'include my_project.mk' -f <this makefile>

TOOL_MODE := 1

include $(dir $(lastword $(MAKEFILE_LIST)))../../stub/c.mk

EXE := buildnumber S
SRC := buildnumber.c

$(DEFINE_TARGETS)
