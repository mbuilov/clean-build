#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# generic support for C/C++ precompiled headers

# included by:
#  $(cb_dir)/compilers/gcc/pch.mk
#  $(cb_dir)/compilers/suncc/pch.mk
#  $(cb_dir)/compilers/msvc/pch.mk

# reset additional makefile variables at beginning of the target makefile
# 'pch' - either absolute or makefile-related path to C/C++ header file to precompile
c_prepare_pch_vars := $(newline)pch:=

ifndef toclean

# define target-specific variables: 'pch', 'cc_with_pch' and 'cxx_with_pch'
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - $(call fixpath,$(pch))
# $4 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $5 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $6 - $(call form_obj_dir,$1,$v)
# $7 - $(call form_trg,$1,$v)
# $v - variant - one of $(get_variants)
# note: last line must be empty!
define pch_vars_templ
$7:pch := $3
$7:cc_with_pch := $4
$7:cxx_with_pch := $5

endef

# define empty target-specific variables 'cc_with_pch' and 'cxx_with_pch'
# $1 - $(call all_targets,$t) where $t - target type: one of exe,lib,dll,klib
# note: last line must be empty!
define with_pch_reset
$1:cc_with_pch:=
$1:cxx_with_pch:=

endef

# call externally defined compiler-specific template $2, which must generate code for precompiled header compilation
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - $(call fixpath,$(pch))
# $4 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $5 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $6 - $(call form_obj_dir,$1,$v)
# $7 - $(call form_trg,$1,$v)
# $v - variant - one of $(get_variants)
# -- parameters for pch rule generator $2:
#  $1 - target type: exe,lib,dll,klib
#  $2 - $(call fixpath,$(pch))
#  $3 - $(filter $(cc_mask),$(with_pch))
#  $4 - $(filter $(cxx_mask),$(with_pch))
#  $5 - $(call form_obj_dir,$1,$v)
#  $6 - $(call form_trg,$1,$v)
#  $v - variant - one of $(get_variants)
# note: 'pch_templatev' may use target-specific variables: 'pch', 'cc_with_pch' and 'cxx_with_pch' in generated code
pch_template3 = $(pch_vars_templ)$(call $2,$1,$3,$4,$5,$6,$7)

# call externally defined compiler-specific generators $2 and $3
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(call fixpath,$(pch))
# $5 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $6 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# -- parameters for sources generator $3:
#  $1 - target type: exe,lib,dll,klib
#  $2 - $(call fixpath,$(pch))
#  $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
#  $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
pch_template2 = $(call $3,$1,$4,$5,$6)$(foreach v,$(get_variants),$(call \
  pch_template3,$1,$2,$4,$5,$6,$(call form_obj_dir,$1,$v),$(call form_trg,$1,$v)))

# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(call fixpath,$(with_pch))
pch_template1 = $(call pch_template2,$1,$2,$3,$(call fixpath,$(pch)),$(filter $(cc_mask),$4),$(filter $(cxx_mask),$4))

# generate code to evaluate to build with precompiled header (generate sources, compile pch, compile generated sources)
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# use target makefile variables: 'pch' and 'with_pch'
# note: must reset target-specific variables 'cc_with_pch' and 'cxx_with_pch' if not using precompiled header for the target,
#  otherwise dependent dll or lib may inherit these values from the target exe or dll
# note: another option - use of 'keyed_redefine' macro with the target-specific variable 'trg' as a key, which is defined by
#  'c_base_template' macro in the $(cb_dir)/types/c/c_base.mk
pch_template = $(if $(and $(pch),$(with_pch)),$(call \
  pch_template1,$1,$2,$3,$(call fixpath,$(with_pch))),$(call with_pch_reset,$(all_targets)))

else # toclean

# call externally defined compiler-specific generators $2 and $3, which must return objects to clean up
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# $4 - $(basename $(notdir $(pch)))
# $5 - $(filter $(cc_mask),$(with_pch))
# $6 - $(filter $(cxx_mask),$(with_pch))
# -- parameters for sources generator $3 and rule generator $2:
#  $1 - target type: exe,lib,dll,klib
#  $2 - $(basename $(notdir $(pch)))
#  $3 - $(filter $(cc_mask),$(with_pch))
#  $4 - $(filter $(cxx_mask),$(with_pch))
# -- more parameters for pch rule generator $2:
#  $5 - $(call form_obj_dir,$1,$v)
#  $v - variant - one of $(get_variants)
pch_template1 = $(call $3,$1,$4,$5,$6)$(foreach v,$(get_variants),$(call $2,$1,$4,$5,$6,$(call form_obj_dir,$1,$v)))

# return objects to clean up created while building with precompiled header (objects of generated sources, pch object file)
# $1 - target type: exe,lib,dll,klib
# $2 - name of pch rule generator macro
# $3 - name of sources generator macro
# use target makefile variables: 'pch' and 'with_pch'
pch_template = $(if $(pch),$(if $(with_pch),$(strip $(call pch_template1,$1,$2,$3,$(basename \
  $(notdir $(pch))),$(filter $(cc_mask),$(with_pch)),$(filter $(cxx_mask),$(with_pch))))))

endif # toclean

# tools colors:

# compile precompiled header
CBLD_PCHCC_COLOR   ?= $(CBLD_CC_COLOR)
CBLD_PCHCXX_COLOR  ?= $(CBLD_CXX_COLOR)
CBLD_TPCHCC_COLOR  ?= $(CBLD_PCHCC_COLOR)
CBLD_TPCHCXX_COLOR ?= $(CBLD_PCHCXX_COLOR)

# compile sources using precompiled header
CBLD_PCC_COLOR   := $(CBLD_CC_COLOR)
CBLD_PCXX_COLOR  := $(CBLD_CXX_COLOR)
CBLD_TPCC_COLOR  := $(CBLD_PCC_COLOR)
CBLD_TPCXX_COLOR := $(CBLD_PCXX_COLOR)

# makefile parsing first phase variables
cb_first_phase_vars += c_prepare_pch_vars pch_vars_templ with_pch_reset pch_template3 pch_template2 pch_template1 pch_template

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,CBLD_PCHCC_COLOR CBLD_PCHCXX_COLOR CBLD_TPCHCC_COLOR CBLD_TPCHCXX_COLOR \
  CBLD_PCC_COLOR CBLD_PCXX_COLOR CBLD_TPCC_COLOR CBLD_TPCXX_COLOR cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: pch
$(call set_global,c_prepare_pch_vars pch_vars_templ with_pch_reset pch_template3 pch_template2 pch_template1 pch_template,pch)
