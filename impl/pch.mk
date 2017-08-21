#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic support for precompiled headers

# included by $(CLEAN_BUILD_DIR)/compilers/gcc_pch.mk

# define target-specific variables: PCH, CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call ALL_TRG,$t) or for each target variant: $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $t - EXE,LIB,DLL,KLIB
# note: last line must be empty
define PCH_VARS_TEMPL
$1:PCH := $2
$1:CC_WITH_PCH := $3
$1:CXX_WITH_PCH := $4

endef

# reset target-specific variables CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call ALL_TRG,$t) or for each target variant: $(call FORM_TRG,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# note: last line must be empty
define WITH_PCH_RESET
$1:CC_WITH_PCH:=
$1:CXX_WITH_PCH:=

endef

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PCH_VARS_TEMPL WITH_PCH_RESET)
