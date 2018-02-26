#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for bison compiler

ifeq (,$(filter-out undefined environment,$(origin bison_compiler)))

ifndef cb_target_makefile
$(error 'defs.mk' must be included prior this file)
endif

# bison compiler executable
BISON ?= bison

# default bison flags
# -y emulate POSIX Yacc, output file name will be "y.tab.c"
# -d generate header
# -o specify output filename
BISON_FLAGS ?= -y -d -o

# bison compiler
# $1 - target
# $2 - source
# note: bison compiler called with default flags produces two files at once: header and source,
#  to avoid calling bison multiple times (one - for a header, second - for a source), use 'multi_target' macro:
#  $(call multi_target,$(gen_dir)/test/y.tab.h $(gen_dir)/test/y.tab.c,test.y,$$(call bison_compiler,$(gen_dir)/test/y.tab.c,$$<))
bison_compiler = $(call suppress,BISON,$2)$(BISON) $(BISON_FLAGS) $(call ospath,$1 $2)

# tool color for the 'suppress' macro
CBLD_BISON_COLOR ?= $(CBLD_GEN_COLOR)

# remember values of variables possibly taken from the environment
$(call config_remember_vars,BISON BISON_FLAGS)

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,BISON BISON_FLAGS CBLD_BISON_COLOR)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: bison
$(call set_global,bison_compiler,bison)

endif # !bison_compiler
