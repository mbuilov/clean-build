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
# -o output file
# example:
#  $ bison.exe -y -d -o out/y.tab.c src/y.tab.y
# produces two files: out/y.tab.c and out/y.tab.h
BISON_FLAGS ?= -y -d -o

# bison compiler
# $1 - absolute path to output file, e.g.: /build/out/y.tab.c
# $2 - absolute path to the source, e.g.: /project/src/grammar.y
# note: bison compiler called with default flags produces two files at once: header and source, to avoid calling bison multiple
#  times (one - for a header, second - for a source), use 'multi_target' macro - e.g. use 'bison_rule' defined below
bison_compiler = $(call suppress,BISON,$2)$(BISON) $(BISON_FLAGS) $(call ospath,$1 $2)

# define a rule for calling 'bison_compiler', which generates both source & header
# $1 - output file, simple path relative to virtual $(out_dir), e.g.: out/y.tab.c
# $2 - absolute path to the source, e.g.: /project/src/grammar.y
# note: cannot use automatic variable $@ in a rule passed to 'multi_target' - it may be either: /build/out/y.tab.c or /build/out/y.tab.h
ifndef cb_namespaces
bison_rule = $(call multi_target,$1 $(1:.c=.h),$2,$$(call bison_compiler,$(o_path),$$<))

else # cb_namespaces

# rule passed to 'multi_target' template _must_ generate each file in its own namespace
bison_rule = $(call bison_rule1,$1,$2,$(1:.c=.h),$(o_path))

# $1 - output file, simple path relative to virtual $(out_dir), e.g.: out/y.tab.c
# $2 - absolute path to the source, e.g.: /project/src/grammar.y
# $3 - generated header, simple path relative to virtual $(out_dir), $(1:.c=.h), e.g.: out/y.tab.h
# $4 - absolute path to the generated source: $(o_path), e.g.: /build/out/y.tab.c
bison_rule1 = $(call multi_target,$1 $3,$2,$$(call bison_compiler,$4,$$<)$$(newline)$$(quiet)$$(call \
  sh_simlink_files,$(4:.c=.h),$(call o_path,$3)))

ifdef cleaning
cb_target_vars1 = $(call toclean1,$(patsubst $(cb_build)/%,%,$1))
endif

endif # cb_namespaces

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
