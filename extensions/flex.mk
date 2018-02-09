#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for flex compiler

ifeq (,$(filter-out undefined environment,$(origin flex_compiler)))

ifndef cb_target_makefile
$(error 'defs.mk' must be included prior this file)
endif

# flex compiler executable
FLEX ?= flex

# flex compiler flags
# -o specify output filename
FLEX_FLAGS ?= -o

# flex compiler
# $1 - target
# $2 - source
# example:
#  $(call add_generated_ret,$(gen_dir)/test/test.yy.c): $(call fixpath,test.l); $(call flex_compiler,$@,$<)
flex_compiler = $(call suppress,FLEX,$2)$(FLEX) $(FLEX_FLAGS) $(call ospath,$1 $2)

# tool color for the 'suppress' macro
CBLD_FLEX_COLOR ?= $(CBLD_GEN_COLOR)

# remember values of variables possibly taken from the environment
$(call config_remember_vars,FLEX FLEX_FLAGS)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,FLEX FLEX_FLAGS CBLD_FLEX_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: flex
$(call set_global,flex_compiler,flex)

endif # !flex_compiler
