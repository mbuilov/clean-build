#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# macros for specifying source file dependencies, like header files, etc:
# - an object file must be recompiled if any of source file dependency get updated

# helper macro: make source dependencies list (simple database, used later for extracting dependencies of given sources)
# $1 - source(s), may be empty
# $2 - dependencies of the source(s), must be non-empty
# example: $(call form_sdeps,s1 s2,d1 d2 d3/d4) -> s1/|d1|d2|d3/d4 s2/|d1|d2|d3/d4
form_sdeps = $(addsuffix /|$(subst $(space),|,$(strip $2)),$1)

# get dependencies of all sources
# $1 - dependencies list (result of 'form_sdeps')
# example: $(call all_sdeps,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
all_sdeps = $(filter-out %/,$(subst |, ,$1))

# filter dependencies list - get dependencies for given source(s)
# $1 - source(s)
# $2 - dependencies list (result of 'form_sdeps')
filter_sdeps = $(filter $(addsuffix /|%,$1),$2)

# get dependencies of the source(s)
# $1 - source(s)
# $2 - dependencies list (result of 'form_sdeps')
# example: $(call extract_sdeps,s8 s2,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
extract_sdeps = $(call all_sdeps,$(filter_sdeps))

# fix source dependencies paths: add absolute path to directory of currently processing makefile to non-absolute paths
# $1 - source dependencies list (result of 'form_sdeps')
# example: $(call fix_sdeps,s8/|d1|d8 s2/|d1|d2|d3/d4) -> /pr/s8/|/pr/d1|/pr/d8 /pr/s2/|/pr/d1|/pr/d2|/pr/d3/d4
fix_sdeps = $(subst | ,|,$(call fixpath,$(subst |,| ,$1)))

# reverse-filter dependencies list - get sources that depend on given dependencies
# $1 - dependencies to search in $2
# $2 - dependencies list (result of 'form_sdeps')
r_filter_sdeps1 = $(if $(filter $(wordlist 2,999999,$2),$1),$(firstword $2))
r_filter_sdeps = $(patsubst %/,%,$(foreach d,$2,$(call r_filter_sdeps1,$1,$(subst |, ,$d))))

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: sdeps
$(call set_global,form_sdeps all_sdeps filter_sdeps extract_sdeps fix_sdeps r_filter_sdeps1 r_filter_sdeps,sdeps)
