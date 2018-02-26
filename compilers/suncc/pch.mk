#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# suncc precompiled headers support

# included by $(cb_dir)/compilers/suncc.mk

# How to use precompiled header:
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

ifeq (,$(filter-out undefined environment,$(origin pch_template)))
include $(cb_dir)/types/c/pch.mk
endif

# $1  - target type: exe,lib,dll,klib...
# $2  - $(call fixpath,$(pch)), e.g. /project/include/xxx.h
# $3  - sources to build with precompiled header (without directory part)
# $4  - $(call form_obj_dir,$1,$v)
# $5  - $(call form_trg,$1,$v)
# $6  - common objdir (for R-variant)
# $7  - pch header compiler: 'pch_cc' or 'pch_cxx'
# $8  - pch source (e.g. /build/obj/xxx_pch.c   or /build/obj/xxx_pch.cc)
# $9  - pch object (e.g. /build/obj/xxx_pch_c.o or /build/obj/xxx_pch_cc.o)
# $10 - pch        (e.g. /build/obj/xxx_c.cpch  or /build/obj/xxx_cc.Cpch)
# $11 - objects to build with pch: $(patsubst %,$4/%$(obj_suffix),$(basename $3))
# $v  - non-empty variant: R,P,D...
# target-specific: 'pch' - defined by 'pch_vars_templ' from $(cb_dir)/types/c/pch.mk
# note: when compiling pch header, two entities are created: pch object $9 and pch $(10), so add order-only dependency of pch $(10)
#  on pch object $9 - to avoid parallel compilation of $(10) and $9, also define target-specific variable '$7_built' - to check if
#  pch $(10) has already been built while building pch object $9
# note: define target-specific variable 'pch_gen_dir' for use by cmn_pcc/cmn_pcxx in $(cb_dir)/compilers/suncc.mk
# note: link pch object $9 to the target $5
# note: add dependency of objects $(11) on pch object $9 - for the (odd) case when needed for the objects pch $(10) is up-to-date,
#  but pch object $9 is not: then don't start compiling objects $(11) until pch object $9 is recreated together with pch $(10)
# note: last line must be empty!
define suncc_pch_rule_templ
$5:$7_built:=
$5:pch_gen_dir := $6
$5: $9
$(11): $(10) $9
$(10):| $9
$9 $(10): $2 | $8 $4 $$(order_deps)
	$$(if $$($7_built),,$$(eval $7_built:=1)$$(call $7,$9,$$(pch),$8,$1,$v))
$(subst $(space),$(newline),$(join $(addsuffix :|,$(11)),$(patsubst %,$6/%$(suffix $8),$3)))

endef
# note: 'c_dep_suffix' - defined in $(cb_dir)/types/c/c_base.mk
ifdef c_dep_suffix
$(call define_prepend,suncc_pch_rule_templ,-include $$(basename $$9)$(c_dep_suffix)$(newline))
endif

# define a rule for building precompiled header
# $1  - target type: exe,lib,dll,klib...
# $2  - $(call fixpath,$(pch)), e.g. /project/include/xxx.h
# $3  - $(notdir $(filter $(cc_mask),$(call fixpath,$(with_pch))))
#    or $(notdir $(filter $(cxx_mask),$(call fixpath,$(with_pch))))
# $4  - $(call form_obj_dir,$1,$v)
# $5  - $(call form_trg,$1,$v)
# $6  - common objdir (for R-variant)
# $7  - $(basename $(notdir $2)), e.g. xxx
# $8  - pch header compiler: 'pch_cc' or 'pch_cxx'
# $9  - pch source suffix: 'c' or 'cc'
# $10 - compiled pch extension: .cpch or .Cpch (predefined by suncc)
# $v  - non-empty variant: R,P,D...
# note: pch souce:  $6/$7_pch.$9
# note: pch object: $4/$7_pch_$9$(obj_suffix)
# note: pch:        $4/$7_$9$(10)
suncc_pch_rule = $(call suncc_pch_rule_templ,$1,$2,$3,$4,$5,$6,$8,$6/$7_pch.$9,$4/$7_pch_$9$(obj_suffix),$4/$7_$9$(10),$(patsubst \
  %,$4/%$(obj_suffix),$(basename $3)))

# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $5 - $(call form_obj_dir,$1,$v)
# $6 - $(call form_trg,$1,$v)
# $7 - common objdir (for R-variant)
# $8 - $(basename $(notdir $2))
# $v - non-empty variant: R,P,D...
suncc_pch_templatev1 = $(if \
  $3,$(call suncc_pch_rule,$1,$2,$(notdir $3),$5,$6,$7,$8,pch_cc,c,.cpch))$(if \
  $4,$(call suncc_pch_rule,$1,$2,$(notdir $4),$5,$6,$7,$8,pch_cxx,cc,.Cpch))

# define a rule for building C/C++ precompiled header, as assumed by 'pch_template' macro from $(cb_dir)/types/c/pch.mk
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $5 - $(call form_obj_dir,$1,$v)
# $6 - $(call form_trg,$1,$v)
# $v - non-empty variant: R,P,D...
# note: in generated code, may use target-specific variables:
#  'pch', 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
# note: this callback is passed to 'pch_template' macro defined in $(cb_dir)/types/c/pch.mk
suncc_pch_templatev = $(call suncc_pch_templatev1,$1,$2,$3,$4,$5,$6,$(call form_obj_dir,$1),$(basename $(notdir $2)))

# generate a source file for compiling precompiled header
# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(pch)), e.g. /project/include/xxx.h
# $3 - pch source (e.g. /build/obj/xxx_pch.c or /build/obj/xxx_pch.cc)
# note: new value of 'cb_needed_dirs' will be accounted in the expanded next 'c_base_template' (see $(cb_dir)/types/c/c_base.mk)
# note: last line must be empty!
define suncc_pch_gen_templ
cb_needed_dirs+=$1
$3:| $1
	$$(call suppress,GEN,$$@)$$(call print_text,#include "$2"$(newline)#pragma hdrstop) > $$@

endef

# generate a source file for compiling it using precompiled header
# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(pch))
# $4 - source suffix: .c or .cc
# $s - full path to the source to build with precompiled header
# note: last line must be empty!
define suncc_pch_src_gen
$1/$(notdir $s)$4:| $1
	$$(call suppress,GEN,$$@)$$(call print_text,#include "$2"$(newline)#pragma hdrstop$(newline)#include "$s") > $$@

endef

# generate sources for compiling with precompiled header
# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
#   or $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $4 - source suffix: .c or .cc
# note: pch source: $1/$(basename $(notdir $2))_pch.$4
suncc_pch_gen_rule = $(call suncc_pch_gen_templ,$1,$2,$1/$(basename $(notdir $2))_pch$4)$(foreach s,$3,$(suncc_pch_src_gen))

# $1 - common objdir (for R-variant)
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
suncc_pch_templategen1 = $(if \
  $3,$(call suncc_pch_gen_rule,$1,$2,$3,.c))$(if \
  $4,$(call suncc_pch_gen_rule,$1,$2,$4,.cc))

# generate sources for compiling with precompiled header, as assumed by 'pch_template' macro from $(cb_dir)/types/c/pch.mk
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# note: this callback is passed to 'pch_template' macro defined in $(cb_dir)/types/c/pch.mk
suncc_pch_templategen = $(call suncc_pch_templategen1,$(call form_obj_dir,$1),$2,$3,$4)

# code to evaluate to build with precompiled headers
# $t - target type: exe,lib,dll,klib...
# note: defines target-specific variables: 'pch', 'cc_with_pch', 'cxx_with_pch'
# note: 'pch_template' macro is defined in $(cb_dir)/types/c/pch.mk
# note: called by 'c_define_app_rules' macro patched in $(cb_dir)/compilers/suncc.mk
suncc_pch_templatet = $(call pch_template,$t,suncc_pch_templatev,suncc_pch_templategen)

# makefile parsing first phase variables
cb_first_phase_vars += suncc_pch_rule_templ suncc_pch_rule suncc_pch_templatev1 suncc_pch_templatev suncc_pch_gen_templ \
  suncc_pch_src_gen suncc_pch_gen_rule suncc_pch_templategen1 suncc_pch_templategen suncc_pch_templatet

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: pch
$(call set_global,suncc_pch_rule_templ=v suncc_pch_rule=v suncc_pch_templatev1=v suncc_pch_templatev=v suncc_pch_gen_templ \
  suncc_pch_src_gen=s suncc_pch_gen_rule suncc_pch_templategen1 suncc_pch_templategen suncc_pch_templatet=t,pch)
