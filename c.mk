#-----------------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPLv2+, see COPYING
#-----------------------------------------------------------------------------------------

ifndef MAKE_C_EVAL
include $(MTOP)/_c.mk
endif
$(MAKE_C_EVAL)
