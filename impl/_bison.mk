#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

ifeq (,$(filter-out undefined environment,$(origin DEF_HEAD_CODE)))
include $(dir $(lastword $(MAKEFILE_LIST)))_defs.mk
endif

# bison compiler executable
BISON := bison

# default bison flags
# -y emulate POSIX Yacc, output file name will be "y.tab.c"
# -d generate header
BISON_FLAGS := -y -d

# call bison compiler
# $1 - target
# $2 - source
# note: bison called with default flags produces two files: header and source, use MULTI_TARGET macro to call bison, example:
#  $(call MULTI_TARGET,$(GEN_DIR)/test/y.tab.h $(GEN_DIR)/test/y.tab.c,test.y,$$(call BISON_COMPILER,$$(@:h=c),$$<))
BISON_COMPILER = $(call SUP,BISON,$2)$(BISON) $(BISON_FLAGS) -o $(call ospath,$1 $2)

# tool colors
BISON_COLOR := $(GEN_COLOR)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,BISON BISON_FLAGS BISON_COMPILER BISON_COLOR)
