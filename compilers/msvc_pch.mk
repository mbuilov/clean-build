#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc compiler precompiled headers support

# included by $(CLEAN_BUILD_DIR)/compilers/msvc.mk

# How to use precompiled header:
#
# 1) compile precompiled header
#   cl.exe /FIC:/project/include/xxx.h /YcC:/project/include/xxx.h /FpC:\build\obj\xxx_c.pch
#     /Yl_xxx /c /FoC:\build\obj\xxx_pch_c.obj /TC NUL
# 2) compile source using precompiled header
#   cl.exe /FIC:/project/include/xxx.h /YuC:/project/include/xxx.h /FpC:\build\obj\xxx_c.pch
#     /c /FoC:\build\obj\src1.obj C:\project\src\src1.c
# 3) link application
#   link.exe /OUT:C:\build\bin\app.exe C:\build\obj\xxx_pch_c.obj C:\build\obj\src1.obj

ifeq (,$(filter-out undefined environment,$(origin PCH_TEMPLATE)))
include $(CLEAN_BUILD_DIR)/impl/pch.mk
endif

ifndef TOCLEAN

# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - sources to build with precompiled header
# $4 - $(call FORM_OBJ_DIR,$1,$v)
# $5 - $(call FORM_TRG,$1,$v)
# $6 - pch compiler type: CC or CXX
# $7 - pch object (e.g. /build/obj/xxx_pch_c.obj or /build/obj/xxx_pch_cpp.obj)
# $8 - pch        (e.g. /build/obj/xxx_c.pch  or /build/obj/xxx_cpp.pch)
# $v - R,P,D
# target-specific: PCH
# note: while compiling pch header two objects are created: pch object - $7 and pch - $8
# note: define target-specific variable $6_PCH_BUILT to check if pch header was already built
# note: link pch object $7 to the target $5
# note: last line must be empty
define MSVC_PCH_RULE_TEMPL
$5:$6_PCH_BUILT:=
$5: $7
$(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))): $8 $7
$8:| $7
$7 $8: $2 | $4 $$(ORDER_DEPS)
	$$(if $$($6_PCH_BUILT),,$$(eval $6_PCH_BUILT:=1)$$(call PCH_$6,$7,$$(PCH),$8,$1,$v))

endef
ifndef NO_DEPS
$(call define_prepend,MSVC_PCH_RULE_TEMPL,-include $$7.d$(newline))
endif

# define rule for building precompiled header
# $1  - EXE,LIB,DLL,KLIB
# $2  - $(call fixpath,$(PCH))
# $3  - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#   or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4  - $(call FORM_OBJ_DIR,$1,$v)
# $5  - $(call FORM_TRG,$1,$v)
# $6  - $(basename $(notdir $2))
# $7  - pch compiler type: CC or CXX
# $8  - pch source type: c or cpp
# $v  - R,P,D
# note: pch object: $4/$6_pch_$8$(OBJ_SUFFIX)
# note: pch:        $4/$6_$8.pch
MSVC_PCH_RULE = $(call MSVC_PCH_RULE_TEMPL,$1,$2,$3,$4,$5,$7,$4/$6_pch_$8$(OBJ_SUFFIX),$4/$6_$8.pch)

# define rule for building C/C++ precompiled header, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $(call FORM_TRG,$1,$v)
# $v - R,P,D
# note: may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
MSVC_PCH_TEMPLATEv = $(if \
  $3,$(call MSVC_PCH_RULE,$1,$2,$3,$5,$6,$5/$(basename $(notdir $2)),CC,c))$(if \
  $4,$(call MSVC_PCH_RULE,$1,$2,$4,$5,$6,$5/$(basename $(notdir $2)),CXX,cpp))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: defines target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH
MSVC_PCH_TEMPLATEt = $(call PCH_TEMPLATE,$t,MSVC_PCH_TEMPLATEv)

else # clean

# return objects created while building with precompiled header to clean up, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P,D
MSVC_PCH_TEMPLATEv = $(if \
  $3,$(addprefix $5/,$2_pch_c$(OBJ_SUFFIX) $2_pch_c$(OBJ_SUFFIX).d $2_c.pch)) $(if \
  $4,$(addprefix $5/,$2_pch_cpp$(OBJ_SUFFIX) $2_pch_cpp$(OBJ_SUFFIX).d $2_cpp.pch))

# cleanup objects created while building with precompiled header
# $t - EXE,LIB,DLL,KLIB
MSVC_PCH_TEMPLATEt = $(call TOCLEAN,$(call PCH_TEMPLATE,$t,MSVC_PCH_TEMPLATEv))

endif # clean

# options for use precompiled header
# $1 - objdir/
# $2 - generated pch suffix: c or cpp
# target-specific: PCH
MSVC_USE_PCH = $(addsuffix $(call ospath,$(PCH)),/FI /Yu) /Fp$(ospath)$(basename $(notdir $(PCH)))_$2.pch

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,MSVC_PCH_RULE_TEMPL=v MSVC_PCH_RULE=v MSVC_PCH_TEMPLATEv=v MSVC_PCH_TEMPLATEt=t MSVC_USE_PCH)
