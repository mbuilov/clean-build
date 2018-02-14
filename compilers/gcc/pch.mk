#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# gcc precompiled headers support

# included by $(cb_dir)/compilers/gcc.mk

# How to use precompiled header:
#
# 1) compile precompiled header
#   gcc -c -o /build/obj/xxx_pch_c.h.gch /project/include/xxx.h
# 2) compile source using precompiled header (include fake header xxx_pch_c.h)
#   gcc -c -I/build/obj -include xxx_pch_c.h -o /build/obj/src1.o /build/obj/src1.c
# 3) link application
#   gcc -o /build/bin/app /build/obj/src1.o

ifeq (,$(filter-out undefined environment,$(origin pch_template)))
include $(cb_dir)/types/c/pch.mk
endif

# define a rule for building precompiled header
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
#   or $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $4 - $(call form_obj_dir,$1,$v)
# $5 - $4/$(basename $(notdir $2))_pch_c.h
#   or $4/$(basename $(notdir $2))_pch_cxx.h
# $6 - pch header compiler: 'pch_cc' or 'pch_cxx'
# $v - non-empty variant: R,P,D...
# target-specific: 'pch' - defined by 'pch_vars_templ' from $(cb_dir)/types/c/pch.mk
# note: last line must be empty!
define gcc_pch_rule_templ
$(patsubst %,$4/%$(obj_suffix),$(basename $(notdir $3))): $5.gch
$5.gch: $2 | $4 $$(order_deps)
	$$(call $6,$$@,$$(pch),$1,$v)

endef
# note: 'c_dep_suffix' - defined in $(cb_dir)/types/c/c_base.mk
ifdef c_dep_suffix
$(call define_prepend,gcc_pch_rule_templ,-include $$5$(c_dep_suffix)$(newline))
endif

# define a rule for building C/C++ precompiled header, as assumed by 'pch_template' macro from $(cb_dir)/types/c/pch.mk
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $5 - $(call form_obj_dir,$1,$v)
# $6 - $(call form_trg,$1,$v) (not used in this template)
# $v - non-empty variant: R,P,D...
# note: in generated code, may use target-specific variables:
#  'pch', 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
# note: this callback is passed to 'pch_template' macro defined in $(cb_dir)/types/c/pch.mk
gcc_pch_templatev = $(if \
  $3,$(call gcc_pch_rule_templ,$1,$2,$3,$5,$5/$(basename $(notdir $2))_pch_c.h,pch_cc))$(if \
  $4,$(call gcc_pch_rule_templ,$1,$2,$4,$5,$5/$(basename $(notdir $2))_pch_cxx.h,pch_cxx))

# code to evaluate to build with precompiled headers
# $t - target type: exe,lib,dll,klib...
# note: defines target-specific variables: 'pch', 'cc_with_pch', 'cxx_with_pch' (in 'pch_template' macro)
# note: 'pch_template' macro is defined in $(cb_dir)/types/c/pch.mk
# note: called by 'c_define_app_rules' macro patched in $(cb_dir)/compilers/gcc.mk
gcc_pch_templatet = $(call pch_template,$t,gcc_pch_templatev)

# makefile parsing first phase variables
cb_first_phase_vars += gcc_pch_rule_templ gcc_pch_templatev gcc_pch_templatet

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: pch
$(call set_global,gcc_pch_rule_templ=v gcc_pch_templatev=v gcc_pch_templatet=t,pch)
