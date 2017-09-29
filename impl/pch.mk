#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic support for precompiled headers

# included by:
#  $(CLEAN_BUILD_DIR)/compilers/gcc_pch.mk
#  $(CLEAN_BUILD_DIR)/compilers/suncc_pch.mk
#  $(CLEAN_BUILD_DIR)/compilers/msvc_pch.mk

ifndef TOCLEAN

# define target-specific variables: PCH, CC_WITH_PCH and CXX_WITH_PCH
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - $(call fixpath,$(PCH))
# $4 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $6 - $(call FORM_OBJ_DIR,$1,$v)
# $7 - $(call FORM_TRG,$1,$v)
# $v - variant - one of $(GET_VARIANTS)
# note: last line must be empty
define PCH_VARS_TEMPL
$7:PCH := $3
$7:CC_WITH_PCH := $4
$7:CXX_WITH_PCH := $5

endef

# define empty target-specific variables CC_WITH_PCH and CXX_WITH_PCH
# $1 - $(call ALL_TARGETS,$t) where $t - one of EXE,LIB,DLL,KLIB
# note: last line must be empty
define WITH_PCH_RESET
$1:CC_WITH_PCH:=
$1:CXX_WITH_PCH:=

endef

# call externally defined compiler-specific template $2, which must generate code for compiling precompiled header
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - $(call fixpath,$(PCH))
# $4 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $5 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# $6 - $(call FORM_OBJ_DIR,$1,$v)
# $7 - $(call FORM_TRG,$1,$v)
# $v - variant - one of $(GET_VARIANTS)
# -- parameters for pch rule generator $2:
#  $1 - EXE,LIB,DLL,KLIB
#  $2 - $(call fixpath,$(PCH))
#  $3 - $(filter $(CC_MASK),$(WITH_PCH))
#  $4 - $(filter $(CXX_MASK),$(WITH_PCH))
#  $5 - $(call FORM_OBJ_DIR,$1,$v)
#  $6 - $(call FORM_TRG,$1,$v)
#  $v - variant - one of $(GET_VARIANTS)
# note: PCH_TEMPLATEv may use target-specific variables: PCH, CC_WITH_PCH, CXX_WITH_PCH in generated code
PCH_TEMPLATE3 = $(PCH_VARS_TEMPL)$(call $2,$1,$3,$4,$5,$6,$7)

# call externally defined compiler-specific generators $2 and $3
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(call fixpath,$(PCH))
# $5 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
# $6 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
# -- parameters for sources generator $3:
#  $1 - EXE,LIB,DLL,KLIB
#  $2 - $(call fixpath,$(PCH))
#  $3 - $(filter $(CC_MASK),$(call fixpath,$(WITH_PCH)))
#  $4 - $(filter $(CXX_MASK),$(call fixpath,$(WITH_PCH)))
PCH_TEMPLATE2 = $(call $3,$1,$4,$5,$6)$(foreach v,$(GET_VARIANTS),$(call \
  PCH_TEMPLATE3,$1,$2,$4,$5,$6,$(call FORM_OBJ_DIR,$1,$v),$(call FORM_TRG,$1,$v)))

# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(call fixpath,$(WITH_PCH))
PCH_TEMPLATE1 = $(call PCH_TEMPLATE2,$1,$2,$3,$(call fixpath,$(PCH)),$(filter $(CC_MASK),$4),$(filter $(CXX_MASK),$4))

# generate code to eval to build with precompiled headers
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# use global variables: PCH, WITH_PCH
# note: must reset target-specific variables CC_WITH_PCH and CXX_WITH_PCH if not using precompiled header
#  for the target, otherwise dependent DLL or LIB target may inherit these values from EXE or DLL
PCH_TEMPLATE = $(if $(word 2,$(PCH) $(WITH_PCH)),$(call \
  PCH_TEMPLATE1,$1,$2,$3,$(call fixpath,$(WITH_PCH))),$(call WITH_PCH_RESET,$(ALL_TARGETS)))

else # clean

# call externally defined compiler-specific generators $2 and $3, which must return objects to clean up
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(basename $(notdir $(PCH)))
# $5 - $(filter $(CC_MASK),$(WITH_PCH))
# $6 - $(filter $(CXX_MASK),$(WITH_PCH))
# -- parameters for sources generator $3 and rule generator $2:
#  $1 - EXE,LIB,DLL,KLIB
#  $2 - $(basename $(notdir $(PCH)))
#  $3 - $(filter $(CC_MASK),$(WITH_PCH))
#  $4 - $(filter $(CXX_MASK),$(WITH_PCH))
# -- more parameters for pch rule generator $2:
#  $5 - $(call FORM_OBJ_DIR,$1,$v)
#  $v - variant - one of $(GET_VARIANTS)
PCH_TEMPLATE1 = $(call $3,$1,$4,$5,$6)$(foreach v,$(GET_VARIANTS),$(call $2,$1,$4,$5,$6,$(call FORM_OBJ_DIR,$1,$v)))

# return objects created while building with precompiled header to clean up
# $1 - EXE,LIB,DLL,KLIB
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# use global variables: PCH, WITH_PCH
PCH_TEMPLATE = $(if $(PCH),$(if $(WITH_PCH),$(strip $(call PCH_TEMPLATE1,$1,$2,$3,$(basename \
  $(notdir $(PCH))),$(filter $(CC_MASK),$(WITH_PCH)),$(filter $(CXX_MASK),$(WITH_PCH))))))

endif # clean

# tools colors:

# compile precompiled header
PCHCC_COLOR   := $(CC_COLOR)
PCHCXX_COLOR  := $(CXX_COLOR)
TPCHCC_COLOR  := $(PCHCC_COLOR)
TPCHCXX_COLOR := $(PCHCXX_COLOR)

# compile using precompiled header
PCC_COLOR   := $(CC_COLOR)
PCXX_COLOR  := $(CXX_COLOR)
TPCC_COLOR  := $(PCC_COLOR)
TPCXX_COLOR := $(PCXX_COLOR)

# protect variables from modifications in target makefiles
$(call SET_GLOBAL,PCH_VARS_TEMPL WITH_PCH_RESET PCH_TEMPLATE3 PCH_TEMPLATE2 PCH_TEMPLATE1 PCH_TEMPLATE \
  PCHCC_COLOR PCHCXX_COLOR TPCHCC_COLOR TPCHCXX_COLOR PCC_COLOR PCXX_COLOR TPCC_COLOR TPCXX_COLOR)
