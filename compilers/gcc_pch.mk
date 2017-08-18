#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler precompiled headers support

# included by $(CLEAN_BUILD_DIR)/compilers/gcc.mk

ifndef TOCLEAN

# define target-specific variables: PCH, CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(call FORM_TRG,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
# note: last line must be empty
define PCH_VARS_TEMPL
$4:PCH := $1
$4:CC_WITH_PCH := $2
$4:CXX_WITH_PCH := $3

endef

# define rule for building precompiled header
# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH))) or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(call FORM_OBJ_DIR,$t,$v)
# $4 - $3/$(basename $(notdir $1))_pch_c.h or $3/$(basename $(notdir $1))_pch_cxx.h
# $5 - compiler: PCH_$t_$v_CC or PCH_$t_$v_CXX
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
# target-specific: PCH
# note: last line must be empty
define PCH_RULE_TEMPL
$(addprefix $3/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $2)))): $4.gch
$4.gch: $1 | $3 $$(ORDER_DEPS)
	$$(call $5,$$@,$$(PCH))

endef
ifndef NO_DEPS
$(call define_prepend,PCH_RULE_TEMPL,-include $4.d$(newline))
endif

# define rule for building C/C++ precompiled header
# define target-specific variables: PCH, CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(call FORM_TRG,$t,$v)
# $5 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
PCH_TEMPLATEv = $(PCH_VARS_TEMPL)$(if \
  $2,$(call PCH_RULE_TEMPL,$1,$2,$5,$5/$(basename $(notdir $1))_pch_c.h,PCH_$t_$v_CC))$(if \
  $3,$(call PCH_RULE_TEMPL,$1,$3,$5,$5/$(basename $(notdir $1))_pch_cxx.h,PCH_$t_$v_CXX))

# $1 - $(call fixpath,$(PCH))
# $2 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $3 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $t - EXE,LIB,DLL,KLIB
PCH_TEMPLATEt2 = $(foreach v,$(call GET_VARIANTS,$t),$(call PCH_TEMPLATEv,$1,$2,$3,$(call FORM_TRG,$t,$v),$(call FORM_OBJ_DIR,$t,$v)))

# $1 - $(call fixpath,$(WITH_PCH))
# $t - EXE,LIB,DLL,KLIB
PCH_TEMPLATEt1 = $(call PCH_TEMPLATEt2,$(call fixpath,$(PCH)),$(filter $(CC_MASK),$1),$(filter $(CXX_MASK),$1))

# reset target-specific variables CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call ALL_TRG,$t)
# $t - EXE,LIB,DLL,KLIB
# note: last line must be empty
define WITH_PCH_RESET
$1:CC_WITH_PCH:=
$1:CXX_WITH_PCH:=

endef

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: must reset target-specific variables CC_WITH_PCH and CXX_WITH_PCH if not using precompiled header
#  for the target, otherwise dependent DLL or LIB target may inherit these values from EXE or DLL
GCC_PCH_TEMPLATEt = $(if $(word 2,$(PCH) $(firstword $(WITH_PCH))),$(call \
  PCH_TEMPLATEt1,$(call fixpath,$(WITH_PCH))),$(call WITH_PCH_RESET,$(call ALL_TRG,$t)))

else # clean

# $1 - $(basename $(notdir $(PCH)))
# $2 - $(filter $(CC_MASK),$(WITH_PCH))
# $3 - $(filter $(CXX_MASK),$(WITH_PCH))
# $4 - $(call FORM_OBJ_DIR,$t,$v)
# $t - EXE,LIB,DLL,KLIB
# $v - R,P
PCH_TEMPLATEcv = $(if \
  $2,$(addprefix $4/$1_pch_c.h,.gch .d)) $(if \
  $3,$(addprefix $4/$1_pch_cxx.h,.gch .d))

# $1 - $(basename $(notdir $(PCH)))
# $2 - $(filter $(CC_MASK),$(WITH_PCH))
# $3 - $(filter $(CXX_MASK),$(WITH_PCH))
# $t - EXE,LIB,DLL,KLIB
PCH_TEMPLATEc = $(foreach v,$(call GET_VARIANTS,$t),$(call PCH_TEMPLATEcv,$1,$2,$3,$(call FORM_OBJ_DIR,$t,$v)))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt = $(if $(word 2,$(PCH) $(firstword $(WITH_PCH))),$(call TOCLEAN,$(call \
  PCH_TEMPLATEc,$(basename $(notdir $(PCH))),$(filter $(CC_MASK),$(WITH_PCH)),$(filter $(CXX_MASK),$(WITH_PCH)))))

endif # clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PCH_VARS_TEMPL=t;v PCH_RULE_TEMPL=t;v PCH_TEMPLATEv=t;v PCH_TEMPLATEt2=t \
  PCH_TEMPLATEt1=t WITH_PCH_RESET GCC_PCH_TEMPLATEt=t PCH_TEMPLATEcv=t;v PCH_TEMPLATEc=t)
