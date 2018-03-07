#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for compiling objects from sources: one source -> one object

# include support for specifying source file dependencies (like headers)
ifeq (,$(filter-out undefined environment,$(origin form_sdeps)))
include $(dir $(lastword $(MAKEFILE_LIST)))sdeps.mk
endif

# add source-dependencies for object files
# $1 - source dependencies list, e.g. dir1/src1/| dir2/dep1| dep2 dir3/src2/| dep3
# $2 - objdir
# $3 - $(obj_suffix)
add_obj_sdeps = $(subst |, ,$(subst $(space),$(newline),$(join \
  $(patsubst %,$2/%$3:,$(basename $(notdir $(filter %/|,$1)))),$(subst | ,|,$(filter-out %/|,$1)))))

# call object compiler: obj_cxx,obj_cc,obj_asm,...
# $1 - object compiler: obj_cxx,obj_cc,obj_asm,...
# $2 - sources to compile
# $3 - sdeps (result of 'fix_sdeps')
# $4 - objdir
# $5 - $(obj_suffix)
# $6 - auxiliary parameter of $1 macro
# $7 - suffix of auto-generated dependencies (e.g. $(c_dep_suffix)), empty if dependencies generation is not supported
# $8 - objects: $(patsubst %,$4/%$5,$(basename $(notdir $2)))
# returns: list of object files
# note: postpone expansion of 'order_deps' to optimize parsing
define obj_rules_templ
$8
$(subst $(space),$(newline),$(join $(addsuffix :,$8),$2))
$(call add_obj_sdeps,$(subst |,| ,$(call filter_sdeps,$2,$3,$5)),$4)
$(call suppress_targets_ret,$8):| $4 $$(order_deps)
	$$(call $1,$$@,$$<,$6)
$(if $7,-include $(patsubst %$5,%$7,$8))
endef

# generate rules for building objects from sources
# $1 - object compiler: obj_cxx,obj_cc,obj_asm,...
# $2 - sources to compile
# $3 - sdeps (result of 'fix_sdeps')
# $4 - objdir
# $5 - $(obj_suffix)
# $6 - auxiliary parameter of $1 macro
# $7 - suffix of auto-generated dependencies (e.g. $(c_dep_suffix)), empty if dependencies generation is not supported
# returns: list of object files
# note: object compiler $1 should call 'suppress' macro to properly update percent of building targets
ifndef toclean
obj_rules = $(if $2,$(call obj_rules_templ,$1,$2,$3,$4,$5,$6,$7,$(patsubst %,$4/%$5,$(basename $(notdir $2)))))
else
# just drop the whole objects directory
# note: also cleanup auto-generated dependencies
obj_rules = $(call toclean,$4)
endif

# makefile parsing first phase variables
cb_first_phase_vars += add_obj_sdeps obj_rules_templ obj_rules

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect variables from modifications in target makefiles
# note: trace namespace: obj_rules
$(call set_global,add_obj_sdeps obj_rules_templ obj_rules,obj_rules)
