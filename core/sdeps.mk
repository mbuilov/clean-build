#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# macros for explicit adding source file dependencies, like header files, etc:
# - an object file must be recompiled if any of source file dependency is updated

# helper macro: make source dependencies list
# $1 - source(s), may be empty
# $2 - dependencies of the source(s), must be non-empty
# example: $(call FORM_SDEPS,s1 s2,d1 d2 d3/d4) -> s1/|d1|d2|d3/d4 s2/|d1|d2|d3/d4
FORM_SDEPS = $(addsuffix /|$(subst $(space),|,$(strip $2)),$1)

# get dependencies of all sources
# $1 - dependencies list (result of FORM_SDEPS)
# example: $(call ALL_SDEPS,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
ALL_SDEPS = $(filter-out %/,$(subst |, ,$1))

# filter dependencies list - get dependencies for given source(s)
# $1 - source(s)
# $2 - dependencies list (result of FORM_SDEPS)
FILTER_SDEPS = $(filter $(addsuffix /|%,$1),$2)

# get dependencies of the source(s)
# $1 - source(s)
# $2 - dependencies list (result of FORM_SDEPS)
# example: $(call EXTRACT_SDEPS,s8 s2,s8/|d1|d8 s2/|d1|d2|d3/d4) -> d1 d8 d1 d2 d3/d4
EXTRACT_SDEPS = $(call ALL_SDEPS,$(FILTER_SDEPS))

# fix source dependencies paths: add absolute path to directory of currently processing makefile to non-absolute paths
# $1 - source dependencies list (result of FORM_SDEPS)
# example: $(call FIX_SDEPS,s8/|d1|d8 s2/|d1|d2|d3/d4) -> /pr/s8/|/pr/d1|/pr/d8 /pr/s2/|/pr/d1|/pr/d2|/pr/d3/d4
FIX_SDEPS = $(subst | ,|,$(call fixpath,$(subst |,| ,$1)))

# reverse-filter dependencies list - get sources that depend on given dependencies
# $1 - dependencies to search in $2
# $2 - dependencies list (result of FORM_SDEPS)
R_FILTER_SDEPS1 = $(if $(filter $(wordlist 2,999999,$2),$1),$(firstword $2))
R_FILTER_SDEPS = $(patsubst %/,%,$(foreach d,$2,$(call R_FILTER_SDEPS1,$1,$(subst |, ,$d))))

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,FORM_SDEPS ALL_SDEPS FILTER_SDEPS EXTRACT_SDEPS FIX_SDEPS R_FILTER_SDEPS1 R_FILTER_SDEPS)
