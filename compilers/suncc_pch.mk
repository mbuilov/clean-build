#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc compiler precompiled headers support

# included by $(CLEAN_BUILD_DIR)/compilers/suncc.mk

ifeq (,$(filter-out undefined environment,$(origin PCH_TEMPLATE)))
include $(CLEAN_BUILD_DIR)/impl/pch.mk
endif

ifndef TOCLEAN

# define rule for building precompiled header
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#   or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(call FORM_OBJ_DIR,$1,$v)
# $5 - $4/$(basename $(notdir $2))_pch_c.h
#   or $4/$(basename $(notdir $2))_pch_cxx.h
# $6 - pch compiler type: CC or CXX
# $v - R,P
# target-specific: PCH
# note: last line must be empty
define GCC_PCH_RULE_TEMPL
$(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))): $5.gch
$5.gch: $2 | $4 $$(ORDER_DEPS)
	$$(call PCH_$1_$6,$$@,$$(PCH),$v)

endef
ifndef NO_DEPS
$(call define_prepend,GCC_PCH_RULE_TEMPL,-include $$5.d$(newline))
endif

# define rule for building C/C++ precompiled header as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P
# note: may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
PCH_TEMPLATEv = $(if \
  $3,$(call GCC_PCH_RULE_TEMPL,$1,$2,$3,$5,$5/$(basename $(notdir $2))_pch_c.h,CC))$(if \
  $4,$(call GCC_PCH_RULE_TEMPL,$1,$2,$4,$5,$5/$(basename $(notdir $2))_pch_cxx.h,CXX))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: defines target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH
GCC_PCH_TEMPLATEt = $(call PCH_TEMPLATE,$t)

else # clean

# return objects created while building with precompiled header to clean up as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P
PCH_TEMPLATEv = $(if \
  $3,$(addprefix $5/$2_pch_c.h,.gch .d)) $(if \
  $4,$(addprefix $5/$2_pch_cxx.h,.gch .d))

# return objects created while building with precompiled header to clean up
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt = $(call TOCLEAN,$(call PCH_TEMPLATE,$t))

endif # clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,GCC_PCH_RULE_TEMPL=v PCH_TEMPLATEv=v GCC_PCH_TEMPLATEt=t)

