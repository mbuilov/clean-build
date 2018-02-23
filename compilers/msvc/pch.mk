#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# msvc precompiled headers support

# included by $(cb_dir)/compilers/msvc.mk

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

ifeq (,$(filter-out undefined environment,$(origin pch_template)))
include $(cb_dir)/types/c/pch.mk
endif

# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch)), e.g. C:/project/include/xxx.h
# $3 - $(call form_obj_dir,$1,$v)
# $4 - $(call form_trg,$1,$v)
# $5 - pch header compiler: 'pch_cc' or 'pch_cxx'
# $6 - pch object (e.g. C:/build/obj/xxx_pch_c.obj or C:/build/obj/xxx_pch_cpp.obj)
# $7 - pch        (e.g. C:/build/obj/xxx_c.pch     or C:/build/obj/xxx_cpp.pch)
# $v - non-empty variant: R,S,RU,SU...
# target-specific: 'pch' - defined by 'pch_vars_templ' from $(cb_dir)/types/c/pch.mk
# note: when compiling pch header, two entities are created: pch object $6 and pch $7, so add order-only dependency of pch $7 on
#  pch object $6 - to avoid parallel compilation of $7 and $6, also define target-specific variable '$5_built' - to check if pch $7
#  has already been built while building pch object $6
# note: link pch object $6 to the target $4
# note: last line must be empty!
define msvc_pch_templ_base
$4:$5_built:=
$4: $6
$7:| $6
$6 $7: $2 | $3 $$(order_deps)
	$$(if $$($5_built),,$$(eval $5_built:=1)$$(call $5,$6,$$(pch),$7,$1,$v))

endef
# note: 'c_dep_suffix' - defined in $(cb_dir)/types/c/c_base.mk
ifdef c_dep_suffix
$(call define_prepend,msvc_pch_templ_base,-include $$(basename $$6)$(c_dep_suffix)$(newline))
endif

# objects can be built only after creating precompiled header
# $3 - $(call form_obj_dir,$1,$v)
# $8 - sources to build with precompiled header
# note: add dependency of objects created from sources $8 on pch object $6 - for the (odd) case when needed for the objects pch $7 is
#  up-to-date, but pch object $6 is not: then don't start compiling those objects until pch object $6 is recreated together with pch $7
define msvc_pch_rule_templ
$(patsubst %,$3/%$(obj_suffix),$(basename $(notdir $8))): $7 $6
$(msvc_pch_templ_base)
endef

# for compiling with /MP switch of cl.exe
# do not start compiling sources of the target $4 until precompiled header $7 is created
# note: though target $4 is not linked with the pch $7, all sources that depend on $7 must be recompiled - and then relinked
#  to the target $4, so add dependency of $4 on pch $7
define msvc_pch_rule_templ_mp
$4: $7
$(msvc_pch_templ_base)
endef

# optimization: replace $(msvc_pch_templ_base) with its value in templates
ifndef cb_tracing
$(call expand_partially,msvc_pch_rule_templ,msvc_pch_templ_base)
$(call expand_partially,msvc_pch_rule_templ_mp,msvc_pch_templ_base)
endif

# define a rule for building precompiled header
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch)), e.g. C:/project/include/xxx.h
# $3 - $(call form_obj_dir,$1,$v)
# $4 - $(call form_trg,$1,$v)
# $5 - $(basename $(notdir $2)), e.g. xxx
# $6 - pch header compiler: 'pch_cc' or 'pch_cxx'
# $7 - pch source type: 'c' or 'cpp'
# $8 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
#   or $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $v - non-empty variant: R,S,RU,SU...
# note: pch object: $3/$5_pch_$7$(obj_suffix)
# note: pch:        $3/$5_$7.pch
msvc_pch_rule    = $(call msvc_pch_rule_templ,$1,$2,$3,$4,$6,$3/$5_pch_$7$(obj_suffix),$3/$5_$7.pch,$8)
msvc_pch_rule_mp = $(call msvc_pch_rule_templ_mp,$1,$2,$3,$4,$6,$3/$5_pch_$7$(obj_suffix),$3/$5_$7.pch)

# define a rule for building C/C++ precompiled header, as assumed by 'pch_template' macro from $(cb_dir)/types/c/pch.mk
# $1 - target type: exe,lib,dll,klib...
# $2 - $(call fixpath,$(pch))
# $3 - $(filter $(cc_mask),$(call fixpath,$(with_pch)))
# $4 - $(filter $(cxx_mask),$(call fixpath,$(with_pch)))
# $5 - $(call form_obj_dir,$1,$v)
# $6 - $(call form_trg,$1,$v)
# $v - non-empty variant: R,S,RU,SU...
# note: in generated code, may use target-specific variables:
#  'pch', 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
# note: this callback is passed to 'pch_template' macro defined in $(cb_dir)/types/c/pch.mk
msvc_pch_templatev = $(if \
  $3,$(call msvc_pch_rule,$1,$2,$5,$6,$5/$(basename $(notdir $2)),pch_cc,c,$3))$(if \
  $4,$(call msvc_pch_rule,$1,$2,$5,$6,$5/$(basename $(notdir $2)),pch_cxx,cpp,$4))

# In the build with /MP cl.exe switch, it is assumed that compiler is invoked sequentially to compile all C/C++ sources of a module
#  - sources are split into groups and compiler internally parallelizes compilation of the sources in each group.
# This is needed to avoid contentions (e.g. fatal error C1041) when writing to the same one (per-module) .pdb file - if
#  the compiler do not supports /FS option, also this will utilize processor more effectively.
# Because target module (exe,dll,lib,...) depends on precompiled headers (one header for each type of the sources: C and C++),
#  sources are will be compiled (in the rule of the target exe,dll,lib,...) only after precompiled headers get created, but also to
#  not compile C and C++ precompiled headers in parallel (to avoid fatal error C1041), add order-only dependency between them.
# note: parameters - the same as for 'msvc_pch_templatev' defined above
# note: last line in the result must be empty!
msvc_pch_template_mpv = $(if \
  $3,$(call msvc_pch_rule_mp,$1,$2,$5,$6,$5/$(basename $(notdir $2)),pch_cc,c))$(if \
  $4,$(call msvc_pch_rule_mp,$1,$2,$5,$6,$5/$(basename $(notdir $2)),pch_cxx,cpp)$(if \
  $3,$(addprefix $5/$(basename $(notdir $2))_,pch_c$(obj_suffix) c.pch:| pch_cpp$(obj_suffix) cpp.pch)$(newline)))

# code to evaluate to build with precompiled headers
# $t - target type: exe,lib,dll,klib...
# note: defines target-specific variables: 'pch', 'cc_with_pch', 'cxx_with_pch'
# note: 'pch_template' macro is defined in $(cb_dir)/types/c/pch.mk
# note: called by 'c_define_app_rules' macro patched in $(cb_dir)/compilers/msvc.mk
msvc_pch_templatet    = $(call pch_template,$t,msvc_pch_templatev)
msvc_pch_template_mpt = $(call pch_template,$t,msvc_pch_template_mpv)

# msvc options for use precompiled header
# $1 - objdir/
# $2 - generated pch suffix: 'c' or 'cpp'
# target-specific: 'pch' (e.g. C:/project/include/xxx.h) - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
msvc_use_pch = $(addsuffix $(call ospath,$(pch)),/FI /Yu) /Fp$(ospath)$(basename $(notdir $(pch)))_$2.pch

# msvc options to create precompiled header
# $1 - pch object (e.g. C:/build/obj/xxx_pch_c.obj or C:/build/obj/xxx_pch_cpp.obj) (unused)
# $2 - pch header (e.g. C:/project/include/xxx.h)
# $3 - pch        (e.g. C:/build/obj/xxx_c.pch or C:/build/obj/xxx_cpp.pch)
msvc_create_pch = $(addsuffix $(call ospath,$2),/FI /Yc) /Fp$(call ospath,$3) /Yl_$(basename $(notdir $3))

# form commands to compile multiple sources at once, some of them using a precompiled header
# $1 - target type: exe,dll,lib,...
# $2 - non-empty variant: R,S,RU,SU,...
# $3 - C compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcc'
# $4 - C++ compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcxx'
# $5 - C compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcc'
# $6 - C++ compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcxx'
# target-specific: 'objdir' - defined by 'c_base_template' from $(cb_dir)/types/c/c_base.mk
# target-specific: 'pch', 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
# note: recompile all $(cc_with_pch) or $(cxx_with_pch) sources if corresponding pch header or its object is newer than the target module
# note: compiler macros ('obj_mcc', 'obj_mcxx', 'obj_pmcc', 'obj_pmcxx') are called with parameters:
#  $1 - sources
#  $2 - target type: exe,dll,lib...
#  $3 - non-empty variant: R,S,RU,SU...
# note: 'newer_sources' - defined in $(cb_dir)/compilers/msvc/cmn.mk
cmn_pmcl = $(call cmn_pmcl1,$1,$2,$3,$4,$5,$6,$(sort $(newer_sources) $(if \
  $(filter $(addprefix $(objdir)/$(basename $(notdir $(pch)))_,pch_c$(obj_suffix) c.pch),$?),$(cc_with_pch)) $(if \
  $(filter $(addprefix $(objdir)/$(basename $(notdir $(pch)))_,pch_cpp$(obj_suffix) cpp.pch),$?),$(cxx_with_pch))))

# form commands to compile multiple sources at once, some of them using a precompiled header
# $1 - target type: exe,dll,lib...
# $2 - non-empty variant: R,S,RU,SU...
# $3 - C compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcc'
# $4 - C++ compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcxx'
# $5 - C compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcc'
# $6 - C++ compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcxx'
# $7 - sources - result of $(newer_sources) + ... (list may be empty)
# target-specific: 'cc_with_pch', 'cxx_with_pch' - defined by 'pch_vars_templ' macro from $(cb_dir)/types/c/pch.mk
cmn_pmcl1 = $(call cmn_pmcl2,$1,$2,$3,$4,$5,$6,$7,$(filter $7,$(cc_with_pch)),$(filter $7,$(cxx_with_pch)))

# form commands to compile multiple sources at once, some of them using a precompiled header
# $1 - target type: exe,dll,lib...
# $2 - non-empty variant: R,S,RU,SU...
# $3 - C compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcc'
# $4 - C++ compiler macro to compile sources _not_ using a precompiled header, e.g. 'obj_mcxx'
# $5 - C compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcc'
# $6 - C++ compiler macro to compile sources using a precompiled header, e.g. 'obj_pmcxx'
# $7 - sources - result of $(newer_sources) + ... (list may be empty)
# $8 - $(filter $7,$(cc_with_pch))
# $9 - $(filter $7,$(cxx_with_pch))
# note: 'cmn_mcl1' and 'cmn_mcl2' - defined in $(cb_dir)/compilers/msvc/cmn.mk
cmn_pmcl2 = $(call cmn_mcl1,$1,$2,$3,$4,$(filter-out $8 $9,$7))$(call cmn_mcl2,$1,$2,$5,$6,$8,$9)

# makefile parsing first phase variables
cb_first_phase_vars += msvc_pch_templ_base msvc_pch_rule_templ msvc_pch_rule_templ_mp msvc_pch_rule msvc_pch_rule_mp \
  msvc_pch_templatev msvc_pch_template_mpv msvc_pch_templatet msvc_pch_template_mpt

# protect variables from modifications in target makefiles
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: pch
$(call set_global,msvc_pch_templ_base=v msvc_pch_rule_templ=v msvc_pch_rule_templ_mp=v msvc_pch_rule=v msvc_pch_rule_mp=v \
  msvc_pch_templatev=v msvc_pch_template_mpv=v msvc_pch_templatet=t msvc_pch_template_mpt=t,pch)

# protect variables from modifications in target makefiles
# note: trace namespace: msvc
$(call set_global,msvc_use_pch msvc_create_pch cmn_pmcl cmn_pmcl1 cmn_pmcl2,msvc)
