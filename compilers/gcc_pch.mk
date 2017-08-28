#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler precompiled headers support

# included by $(CLEAN_BUILD_DIR)/compilers/gcc.mk

ifndef TOCLEAN

ifeq (,$(filter-out undefined environment,$(origin PCH_VARS_TEMPL)))
include $(CLEAN_BUILD_DIR)/impl/pch.mk
endif

# define rule for building precompiled header
# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH))) or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(call FORM_OBJ_DIR,$t,$v)
# $4 - $3/$(basename $(notdir $1))_pch_c.h or $3/$(basename $(notdir $1))_pch_cxx.h
# $5 - pch compiler type: CC or CXX
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
# target-specific: PCH
# note: last line must be empty
define GCC_PCH_RULE_TEMPL
$(addprefix $3/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2)))): $4.gch
$4.gch: $1 | $3 $$(ORDER_DEPS)
	$$(call PCH_$t_$5,$$@,$$(PCH),$v)

endef
ifndef NO_DEPS
$(call define_prepend,GCC_PCH_RULE_TEMPL,-include $$4.d$(newline))
endif

# define rule for building C/C++ precompiled header
# define target-specific variables: PCH, CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call FORM_TRG,$t,$v)
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
GCC_PCH_TEMPLATEv = $(PCH_VARS_TEMPL)$(if \
  $3,$(call GCC_PCH_RULE_TEMPL,$2,$3,$5,$5/$(basename $(notdir $2))_pch_c.h,CC))$(if \
  $4,$(call GCC_PCH_RULE_TEMPL,$2,$4,$5,$5/$(basename $(notdir $2))_pch_cxx.h,CXX))

# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt2 = $(foreach v,$(call GET_VARIANTS,$t),$(call \
  GCC_PCH_TEMPLATEv,$(call FORM_TRG,$t,$v),$1,$2,$3,$(call FORM_OBJ_DIR,$t,$v)))

# $1 - $(call fixpath,$(WITH_PCH))
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt1 = $(call GCC_PCH_TEMPLATEt2,$(call fixpath,$(PCH)),$(filter $(CC_MASK),$1),$(filter $(CXX_MASK),$1))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: must reset target-specific variables CC_WITH_PCH and CXX_WITH_PCH if not using precompiled header
#  for the target, otherwise dependent DLL or LIB target may inherit these values from EXE or DLL
GCC_PCH_TEMPLATEt = $(if $(and $(PCH),$(WITH_PCH)),$(call \
  GCC_PCH_TEMPLATEt1,$(call fixpath,$(WITH_PCH))),$(call WITH_PCH_RESET,$(call ALL_TARGETS,$t)))

else # clean

# $1 - $(basename $(notdir $(PCH)))
# $2 - $(filter $(CC_MASK),$(WITH_PCH))
# $3 - $(filter $(CXX_MASK),$(WITH_PCH))
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
GCC_PCH_TEMPLATEcv = $(if \
  $2,$(addprefix $4/$1_pch_c.h,.gch .d)) $(if \
  $3,$(addprefix $4/$1_pch_cxx.h,.gch .d))

# $1 - $(basename $(notdir $(PCH)))
# $2 - $(filter $(CC_MASK),$(WITH_PCH))
# $3 - $(filter $(CXX_MASK),$(WITH_PCH))
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEc = $(foreach v,$(call GET_VARIANTS,$t),$(call GCC_PCH_TEMPLATEcv,$1,$2,$3,$(call FORM_OBJ_DIR,$t,$v)))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt = $(if $(PCH),$(if $(WITH_PCH)),$(call TOCLEAN,$(call \
  GCC_PCH_TEMPLATEc,$(basename $(notdir $(PCH))),$(filter $(CC_MASK),$(WITH_PCH)),$(filter $(CXX_MASK),$(WITH_PCH)))))

endif # clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,GCC_PCH_RULE_TEMPL=t;v GCC_PCH_TEMPLATEv=t;v GCC_PCH_TEMPLATEt2=t \
  GCC_PCH_TEMPLATEt1=t GCC_PCH_TEMPLATEt=t GCC_PCH_TEMPLATEcv=t;v GCC_PCH_TEMPLATEc=t)
