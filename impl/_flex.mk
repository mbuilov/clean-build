#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin DEF_HEAD_CODE)))
include $(dir $(lastword $(MAKEFILE_LIST)))_defs.mk
endif

# flex compiler executable
FLEX := flex

# default flex flags
FLEX_FLAGS:=

# call flex compiler
# $1 - target
# $2 - source
# example:
#  $(call ADD_GENERATED_RET,$(GEN_DIR)/test/test.yy.c): $(call fixpath,test.l); $(call FLEX_COMPILER,$@,$<)
FLEX_COMPILER = $(call SUP,FLEX,$2)$(FLEX) $(FLEX_FLAGS) -o$(call ospath,$1 $2)

# tool colors
FLEX_COLOR := $(GEN_COLOR)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,FLEX FLEX_FLAGS FLEX_COMPILER FLEX_COLOR)
