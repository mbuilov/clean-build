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
# -y emulate POSIX Yacc
# -d generate header (in the same directory as output file)
# -o output filename
# example:
#  $ bison.exe -y -d -o out/grammar.c src/grammar.y
# produces two files: out/grammar.c and out/grammar.h
BISON_FLAGS ?= -y -d -o

# bison compiler
# $1 - output filename (e.g.: out/grammar.c)
# $2 - source (e.g.: src/grammar.y)
# note: bison compiler called with default flags produces two files at once: header and source,
#  to avoid calling bison multiple times (one - for a header, second - for a source), use 'multi_target' macro:
#  $(call multi_target,gen/test/y.tab.h gen/test/y.tab.c,test.y,$$(call bison_compiler,gen/test/y.tab.c,$$<))
#  (note: cannot use automatic variable $@ in a rule passed to 'multi_target' - it may be any of gen/test/y.tab.c or gen/test/y.tab.h)
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
