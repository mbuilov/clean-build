#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# add support for processing sub-makefiles
include $(dir $(lastword $(MAKEFILE_LIST)))make/submakes.mk

to_make:=

ifneq (distclean,$(MAKECMDGOALS))
to_make += gen.mk lib.mk exe.mk dll.mk
endif

$(call process_submakes,$(to_make))
