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

# Example how to use precompiled header:
#
# 1) create fake source /build/obj/xxx_pch.c
#   #include "/project/include/xxx.h"
#   #pragma hdrstop
# 2) compile precompiled header
#   cc -xpch=collect:/build/obj/xxx_c -c -o /build/obj/xxx_pch_c.o /build/obj/xxx_pch.c
# 3) generate source /build/obj/src1.c.c
#   #include "/project/include/xxx.h"
#   #pragma hdrstop
#   #include "/project/src/src1.c"
# 4) compile it using precompiled header
#   cc -xpch=use:/build/obj/xxx_c -c -o /build/obj/src1.o /build/obj/src1.c.c
# 5) link application
#   cc -o /build/bin/app /build/obj/xxx_pch_c.o /build/obj/src1.o

# $1  - EXE,LIB,DLL,KLIB
# $2  - $(call fixpath,$(PCH))
# $3  - sources to build with precompiled header
# $4  - $(call FORM_OBJ_DIR,$1,$v)
# $5  - $(call FORM_TRG,$1,$v)
# $6  - common objdir (for R-variant)
# $7  - pch compiler type: CC or CXX
# $8  - pch source (e.g. /build/obj/xxx_pch.c   or /build/obj/xxx_pch.cc)
# $9  - pch object (e.g. /build/obj/xxx_pch_c.o or /build/obj/xxx_pch_cc.o)
# $10 - pch        (e.g. /build/obj/xxx_c.cpch  or /build/obj/xxx_cc.Cpch)
# $11 - objects $(addprefix $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3))))
# $v  - R,P,D
# target-specific: PCH
# note: while compiling pch header two objects are created: pch object - $9 and pch - $(10)
# note: define target-specific variable $7_PCH_BUILT to check if pch header was already built
# note: define target-specific variable PCH_GEN_DIR used by CMN_PCC/CMN_PCXX
# note: link pch object $9 to the target $5
# note: last line must be empty
define SUNCC_PCH_RULE_TEMPL
$5:$7_PCH_BUILT:=
$5:PCH_GEN_DIR := $6
$5: $9
$(11): $(10) $9
$(10):| $9
$9 $(10): $2 | $8 $4 $$(ORDER_DEPS)
	$$(if $$($7_PCH_BUILT),,$$(eval $7_PCH_BUILT:=1)$$(call PCH_$1_$7,$9,$$(PCH),$8,$v))
$(subst $(space),$(newline),$(join $(addsuffix :|,$(11)),$(addprefix $6/,$(addsuffix $(suffix $8),$(notdir $3)))))

endef
ifndef NO_DEPS
$(call define_prepend,SUNCC_PCH_RULE_TEMPL,-include $$9.d$(newline))
endif

# define rule for building precompiled header
# $1  - EXE,LIB,DLL,KLIB
# $2  - $(call fixpath,$(PCH))
# $3  - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#   or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4  - $(call FORM_OBJ_DIR,$1,$v)
# $5  - $(call FORM_TRG,$1,$v)
# $6  - common objdir (for R-variant)
# $7  - $(basename $(notdir $2))
# $8  - pch compiler type: CC or CXX
# $9  - pch source suffix: c or cc
# $10 - compiled pch extension: .cpch or .Cpch (predefined by compiler)
# $v  - R,P,D
# note: pch souce:  $6/$7_pch.$9
# note: pch object: $4/$7_pch_$9$(OBJ_SUFFIX)
# note: pch:        $4/$7_$9$(10)
SUNCC_PCH_RULE = $(call SUNCC_PCH_RULE_TEMPL,$1,$2,$3,$4,$5,$6,$8,$6/$7_pch.$9,$4/$7_pch_$9$(OBJ_SUFFIX),$4/$7_$9$(10),$(addprefix \
  $4/,$(addsuffix $(OBJ_SUFFIX),$(basename $(notdir $3)))))

# define rule for building C/C++ precompiled header as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $(call FORM_TRG,$1,$v)
# $7 - common objdir (for R-variant)
# $8 - $(basename $(notdir $2))
# $v - R,P,D
PCH_TEMPLATEv1 = $(if \
  $3,$(call SUNCC_PCH_RULE,$1,$2,$3,$5,$6,$7,$8,CC,c,.cpch))$(if \
  $4,$(call SUNCC_PCH_RULE,$1,$2,$4,$5,$6,$7,$8,CXX,cc,.Cpch))

# define rule for building C/C++ precompiled header, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $6 - $(call FORM_TRG,$1,$v)
# $v - R,P,D
# note: may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
PCH_TEMPLATEv = $(call PCH_TEMPLATEv1,$1,$2,$3,$4,$5,$6,$(call FORM_OBJ_DIR,$1),$(basename $(notdir $2)))

# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(PCH))
# $3 - pch source (e.g. /build/obj/xxx_pch.c or /build/obj/xxx_pch.cc)
# note: new value of NEEDED_DIRS will be accounted in expanded next C_BASE_TEMPLATE
# note: last line must be empty
define SUNCC_PCH_GEN_TEMPL
NEEDED_DIRS+=$1
$3:| $1
	$$(call ECHO_TEXT,#include "$2"$(newline)#pragma hdrstop) > $$@

endef

# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(PCH))
# $4 - pch source suffix: .c or .cc
# $s - full path to source to build with precompiled header
# note: last line must be empty
define SUNCC_PCH_SRC_GEN
$1/$(notdir $s)$4:| $1
	$$(call ECHO_TEXT,#include "$2"$(newline)#pragma hdrstop$(newline)#include "$s") > $$@

endef

# generate sources for compiling with precompiled header
# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#   or $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - pch source suffix: .c or .cc
# note: pch source: $1/$(basename $(notdir $2))_pch.$4
SUNCC_PCH_GEN_RULE = $(call SUNCC_PCH_GEN_TEMPL,$1,$2,$1/$(basename $(notdir $2))_pch$4)$(foreach s,$3,$(SUNCC_PCH_SRC_GEN))

# generate sources for compiling with precompiled header as assumed by PCH_TEMPLATE macro
# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
PCH_TEMPLATEt1 = $(if \
  $3,$(call SUNCC_PCH_GEN_RULE,$1,$2,$3,.c))$(if \
  $4,$(call SUNCC_PCH_GEN_RULE,$1,$2,$4,.cc))

# generate sources for compiling with precompiled header, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(call fixpath,$(PCH))
# $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
PCH_TEMPLATEgen = $(call PCH_TEMPLATEt1,$(call FORM_OBJ_DIR,$1),$2,$3,$4)

# code to eval to build with precompiled headers
# $t - EXE,LIB,DLL,KLIB
# note: defines target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH
SUNCC_PCH_TEMPLATEt = $(call PCH_TEMPLATE,$t)

else # clean

# return objects created while building with precompiled header to clean up, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# $5 - $(call FORM_OBJ_DIR,$1,$v)
# $v - R,P,D
PCH_TEMPLATEv = $(if \
  $3,$(addprefix $5/,$2_pch_c$(OBJ_SUFFIX) $2_pch_c.d $2_c.cpch)) $(if \
  $4,$(addprefix $5/,$2_pch_cc$(OBJ_SUFFIX) $2_pch_cc.d $2_cc.Cpch))

# return objects created while building with precompiled header to clean up
# $1 - common objdir (for R-variant)
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
PCH_TEMPLATEt1 = $(if \
  $3,$(addprefix $1/,$(addsuffix .c,$2_pch $(notdir $3)))) $(if \
  $4,$(addprefix $1/,$(addsuffix .cc,$2_pch $(notdir $4))))

# return files generated for building with precompiled header to clean up, as assumed by PCH_TEMPLATE macro
# $1 - EXE,LIB,DLL,KLIB
# $2 - $(basename $(notdir $(PCH)))
# $3 - $(filter $(CC_MASK),$(WITH_PCH))
# $4 - $(filter $(CXX_MASK),$(WITH_PCH))
PCH_TEMPLATEgen = $(call PCH_TEMPLATEt1,$(call FORM_OBJ_DIR,$1),$2,$3,$4)

# cleanup objects created while building with precompiled header
# $t - EXE,LIB,DLL,KLIB
SUNCC_PCH_TEMPLATEt = $(call TOCLEAN,$(call PCH_TEMPLATE,$t))

endif # clean

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,SUNCC_PCH_RULE_TEMPL=v SUNCC_PCH_RULE=v PCH_TEMPLATEv1=v PCH_TEMPLATEv=v \
  SUNCC_PCH_GEN_TEMPL SUNCC_PCH_SRC_GEN=s SUNCC_PCH_GEN_RULE PCH_TEMPLATEt1 PCH_TEMPLATEgen SUNCC_PCH_TEMPLATEt=t)
