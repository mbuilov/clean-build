#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc compiler precompiled headers support

# included by $(CLEAN_BUILD_DIR)/compilers/gcc.mk

# How to use precompiled header:
#
# 1) complie precompiled header
#   gcc -c -o /build/obj/xxx_pch_c.h.gch /project/include/xxx.h
# 2) compile source using precompiled header (include fake header xxx_pch_c.h)
#   gcc -c -I/build/obj -include xxx_pch_c.h -o /build/obj/src1.o /build/obj/src1.c
# 3) link application
#   gcc -o /build/bin/app /build/obj/src1.o

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
# $v - R,P,D
# target-specific: PCH
# note: last line must be empty
define GCC_PCH_RULE_TEMPL
$(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))): $5.gch
$5.gch: $2 | $4 $$(ORDER_DEPS)
	$$(call PCH_$6,$$@,$$(PCH),$1,$v)

endef
ifndef NO_DEPS
$(call define_prepend,GCC_PCH_RULE_TEMPL,-include $$5.d$(newline))
endif

# define rule for building C/C++ precompiled header, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $(call FORM_TRG,$1,$v) (not used)
# $v - R,P,D
# note: may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
GCC_PCH_TEMPLATEv = $(if \
  $3,$(call GCC_PCH_RULE_TEMPL,$1,$2,$3,$5,$5/$(basename $(notdir $2))_pch_c.h,CC))$(if \
  $4,$(call GCC_PCH_RULE_TEMPL,$1,$2,$4,$5,$5/$(basename $(notdir $2))_pch_cxx.h,CXX))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: defines target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH
GCC_PCH_TEMPLATEt = $(call PCH_TEMPLATE,$t,GCC_PCH_TEMPLATEv)

else # clean

# return objects created while building with precompiled header to clean up, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P,D
GCC_PCH_TEMPLATEv = $(if \
  $3,$(addprefix $5/$2_pch_c.h,.gch .d)) $(if \
  $4,$(addprefix $5/$2_pch_cxx.h,.gch .d))

# cleanup objects created while building with precompiled header
# $t - EXE,LIB,DLL,KLIB
GCC_PCH_TEMPLATEt = $(call TOCLEAN,$(call PCH_TEMPLATE,$t,GCC_PCH_TEMPLATEv))

endif # clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,GCC_PCH_RULE_TEMPL=v GCC_PCH_TEMPLATEv=v GCC_PCH_TEMPLATEt=t)
