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
#   cl.exe /FIC:\project\include\xxx.h /YcC:\project\include\xxx.h /FpC:\build\obj\xxx_c.pch
#     /Yl_xxx /c /FoC:\build\obj\xxx_pch_c.obj /TC C:\project\include\xxx.h
# 2) compile source using precompiled header
#   cl.exe /FIC:\project\include\xxx.h /YuC:\project\include\xxx.h /FpC:\build\obj\xxx_c.pch
#     /c /FoC:\build\obj\src1.obj C:\project\src\src1.c
# 3) link application
#   link.exe /OUT:C:\build\bin\app.exe C:\build\obj\xxx_pch_c.obj C:\build\obj\src1.obj

ifeq (,$(filter-out undefined environment,$(origin PCH_TEMPLATE)))
include $(CLEAN_BUILD_DIR)/types/c/pch.mk
endif

ifndef TOCLEAN

# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH)), e.g. C:/project/include/xxx.h
# $3 - $(call FORM_OBJ_DIR,$1,$v)
# $4 - $(call FORM_TRG,$1,$v)
# $5 - pch compiler type: CC or CXX
# $6 - pch object (e.g. C:/build/obj/xxx_pch_c.obj or C:/build/obj/xxx_pch_cpp.obj)
# $7 - pch        (e.g. C:/build/obj/xxx_c.pch  or C:/build/obj/xxx_cpp.pch)
# $v - R,S,RU,SU
# target-specific: PCH
# note: while compiling pch header two objects are created: pch object - $6 and pch - $7
# note: define target-specific variable $5_PCH_BUILT to check if pch header was already built
# note: link pch object $6 to the target $4
# note: last line must be empty
define MSVC_PCH_RULE_TEMPL_BASE
$4:$5_PCH_BUILT:=
$4: $6
$7:| $6
$6 $7: $2 | $3 $$(ORDER_DEPS)
	$$(if $$($5_PCH_BUILT),,$$(eval $5_PCH_BUILT:=1)$$(call PCH_$5,$6,$$(PCH),$7,$1,$v))

endef
ifndef NO_DEPS
$(call define_prepend,MSVC_PCH_RULE_TEMPL,-include $$6.d$(newline))
endif

# objects can be built only after creating precompiled header
# $8 - sources to build with precompiled header
define MSVC_PCH_RULE_TEMPL
$(patsubst %,$3/%$(OBJ_SUFFIX),$(basename $(notdir $8))): $7 $6
$(MSVC_PCH_RULE_TEMPL_BASE)
endef

# do not start compiling sources of a target $4 until precompiled header $7 is created
define MSVC_PCH_RULE_TEMPL_MP
$4:| $7
$(MSVC_PCH_RULE_TEMPL_BASE)
endef

# optimization
ifndef CB_TRACING
$(call expand_partially,MSVC_PCH_RULE_TEMPL,MSVC_PCH_RULE_TEMPL_BASE)
$(call expand_partially,MSVC_PCH_RULE_TEMPL_MP,MSVC_PCH_RULE_TEMPL_BASE)
endif

# define rule for building precompiled header
# $1  - EXE,LIB,DLL,KLIB
# $2  - $(call fixpath,$(PCH))
# $3  - $(call FORM_OBJ_DIR,$1,$v)
# $4  - $(call FORM_TRG,$1,$v)
# $5  - $(basename $(notdir $2))
# $6  - pch compiler type: CC or CXX
# $7  - pch source type: c or cpp
# $8  - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#   or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $v  - R,S,RU,SU
# note: pch object: $3/$5_pch_$7$(OBJ_SUFFIX)
# note: pch:        $3/$5_$7.pch
MSVC_PCH_RULE    = $(call MSVC_PCH_RULE_TEMPL,$1,$2,$3,$4,$6,$3/$5_pch_$7$(OBJ_SUFFIX),$3/$5_$7.pch,$8)
MSVC_PCH_RULE_MP = $(call MSVC_PCH_RULE_TEMPL_MP,$1,$2,$3,$4,$6,$3/$5_pch_$7$(OBJ_SUFFIX),$3/$5_$7.pch)

# define rule for building C/C++ precompiled header, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $(call FORM_TRG,$1,$v)
# $v - R,S,RU,SU
# note: may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
MSVC_PCH_TEMPLATEv = $(if \
  $3,$(call MSVC_PCH_RULE,$1,$2,$5,$6,$5/$(basename $(notdir $2)),CC,c,$3))$(if \
  $4,$(call MSVC_PCH_RULE,$1,$2,$5,$6,$5/$(basename $(notdir $2)),CXX,cpp,$4))

# In /MP build it is assumed that compiler is invoked sequentially to compile all C/C++ sources of a module
#  - sources are split into groups and compiler internally parallelizes compilation of sources in each group.
# This is needed to avoid contention (e.g. fatal error C1041) when writing to one (per-module) .pdb file - if
#  compiler do not supports /FS option, also this will utilize processor more effectively.
# Because target module (EXE,DLL,LIB,...) depends on precompiled headers, sources are will be compiled only
#  after precompiled headers get created, but avoid compiling C and C++ precompiled headers in parallel.
MSVC_PCH_TEMPLATE_MPv = $(if \
  $3,$(call MSVC_PCH_RULE_MP,$1,$2,$5,$6,$5/$(basename $(notdir $2)),CC,c))$(if \
  $4,$(call MSVC_PCH_RULE_MP,$1,$2,$5,$6,$5/$(basename $(notdir $2)),CXX,cpp)$(if \
  $3,$(addprefix $5/$(basename $(notdir $2))_,pch_c$(OBJ_SUFFIX) c.pch:| pch_cpp$(OBJ_SUFFIX) cpp.pch)$(newline)))

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: defines target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH
MSVC_PCH_TEMPLATEt    = $(call PCH_TEMPLATE,$t,MSVC_PCH_TEMPLATEv)
MSVC_PCH_TEMPLATE_MPt = $(call PCH_TEMPLATE,$t,MSVC_PCH_TEMPLATE_MPv)

else # clean

# return objects created while building with precompiled header to clean up, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,S,RU,SU
MSVC_PCH_TEMPLATEv = $(if \
  $3,$(addprefix $5/$2_,pch_c$(OBJ_SUFFIX) pch_c$(OBJ_SUFFIX).d c.pch)) $(if \
  $4,$(addprefix $5/$2_,pch_cpp$(OBJ_SUFFIX) pch_cpp$(OBJ_SUFFIX).d cpp.pch))

# cleanup objects created while building with precompiled header
# $t - EXE,LIB,DLL,KLIB
MSVC_PCH_TEMPLATEt    = $(call TOCLEAN,$(call PCH_TEMPLATE,$t,MSVC_PCH_TEMPLATEv))
MSVC_PCH_TEMPLATE_MPt = $(MSVC_PCH_TEMPLATEt)

endif # clean

# options for use precompiled header
# $1 - objdir/
# $2 - generated pch suffix: c or cpp
# target-specific: PCH (e.g. C:/project/include/xxx.h)
MSVC_USE_PCH = $(addsuffix $(call ospath,$(PCH)),/FI /Yu) /Fp$(ospath)$(basename $(notdir $(PCH)))_$2.pch

# options to create precompiled header
# $1 - pch object (e.g. C:/build/obj/xxx_pch_c.obj or C:/build/obj/xxx_pch_cpp.obj)
# $2 - pch header (e.g. C:/project/include/xxx.h)
# $3 - pch        (e.g. C:/build/obj/xxx_c.pch or C:/build/obj/xxx_cpp.pch)
MSVC_CREATE_PCH = $(addsuffix $(call ospath,$2),/FI /Yc) /Fp$(call ospath,$3) /Yl_$(basename $(notdir $3))

# compile multiple sources at once, some of them using precompiled header
# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro to compile not using precompiled header, e.g. OBJ_MCC
# $4 - C++ compiler macro to compile not using precompiled header, e.g. OBJ_MCXX
# $5 - C compiler macro to compile with precompiled header, e.g. OBJ_PMCC
# $6 - C++ compiler macro to compile with precompiled header, e.g. OBJ_PMCXX
# target-specific: OBJ_DIR, PCH, CC_WITH_PCH, CXX_WITH_PCH
# note: recompile all $(CC_WITH_PCH) or $(CXX_WITH_PCH) if corresponding pch header is newer than the target module
# note: compiler macros called with parameters:
#  $1 - sources
#  $2 - target type: EXE,DLL,LIB,...
#  $3 - non-empty variant: R,S,RU,SU,...
CMN_PMCL = $(call CMN_PMCL1,$1,$2,$3,$4,$5,$6,$(sort $(NEWER_SOURCES) $(if \
  $(filter $(OBJ_DIR)/$(basename $(notdir $(PCH)))_c$(OBJ_SUFFIX),$?),$(CC_WITH_PCH)) $(if \
  $(filter $(OBJ_DIR)/$(basename $(notdir $(PCH)))_cpp$(OBJ_SUFFIX),$?),$(CXX_WITH_PCH))))

# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro to compile not using precompiled header, e.g. OBJ_MCC
# $4 - C++ compiler macro to compile not using precompiled header, e.g. OBJ_MCXX
# $5 - C compiler macro to compile with precompiled header, e.g. OBJ_PMCC
# $6 - C++ compiler macro to compile with precompiled header, e.g. OBJ_PMCXX
# $7 - sources (result of $(NEWER_SOURCES))
# target-specific: CC_WITH_PCH, CXX_WITH_PCH
CMN_PMCL1 = $(call CMN_PMCL2,$1,$2,$3,$4,$5,$6,$7,$(filter $7,$(CC_WITH_PCH)),$(filter $7,$(CXX_WITH_PCH)))

# $1 - target type: EXE,DLL,LIB,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro to compile not using precompiled header, e.g. OBJ_MCC
# $4 - C++ compiler macro to compile not using precompiled header, e.g. OBJ_MCXX
# $5 - C compiler macro to compile with precompiled header, e.g. OBJ_PMCC
# $6 - C++ compiler macro to compile with precompiled header, e.g. OBJ_PMCXX
# $7 - sources (result of $(NEWER_SOURCES))
# $8 - $(filter $7,$(CC_WITH_PCH))
# $9 - $(filter $7,$(CXX_WITH_PCH))
CMN_PMCL2 = $(call CMN_MCL1,$1,$2,$3,$4,$(filter-out $8 $9,$7))$(call CMN_MCL2,$1,$2,$5,$6,$8,$9)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,MSVC_PCH_RULE_TEMPL_BASE=v MSVC_PCH_RULE_TEMPL=v MSVC_PCH_RULE_TEMPL_MP=v MSVC_PCH_RULE=v MSVC_PCH_RULE_MP=v \
  MSVC_PCH_TEMPLATEv=v MSVC_PCH_TEMPLATE_MPv=v MSVC_PCH_TEMPLATEt=t MSVC_PCH_TEMPLATE_MPt=t MSVC_USE_PCH MSVC_CREATE_PCH \
  CMN_PMCL CMN_PMCL1 CMN_PMCL2)
