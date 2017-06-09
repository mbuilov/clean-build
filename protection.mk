#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/defs.mk before including $(CLEAN_BUILD_DIR)/functions.mk
# variables protection from accidental changes in target makefiles

# run via $(MAKE) C=1 to check makefiles
ifeq (command line,$(origin C))
MCHECK := $(C:0=)
else
MCHECK:=
endif

# run via $(MAKE) T=1 to trace all macros (with some exceptions)
ifeq (command line,$(origin T))
TRACE := $(T:0=)
else
TRACE:=
endif

ifdef MCHECK

# reset
CLEAN_BUILD_PROTECTED_VALUES_SAVED:=
CLEAN_BUILD_OVERRIDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=

# save value of variable $1 to $1.v?
CLEAN_BUILD_ENCODE_VAR_VALUE = $(origin $1):$(if $(filter-out undefined,$(origin $1)),$(flavor \
  $1):$(subst $(comment),$$(comment),$(subst $(newline),$$(newline),$(subst $$(newline),$$$$(newline),$(value $1)))))

# store values of clean-build protected variables which must not be changed in target makefiles
# check and set CLEAN_BUILD_NEED_TAIL_CODE - $(DEF_TAIL_CODE) must be evaluated after $(DEF_HEAD_CODE)
define CLEAN_BUILD_CHECK_AT_HEAD
ifndef CLEAN_BUILD_PROTECTED_VALUES_SAVED
$$(foreach x,$$(CLEAN_BUILD_PROTECTED_VARS),$$(eval $$x.v? = $$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$$x)))
CLEAN_BUILD_PROTECTED_VALUES_SAVED:=1
endif
ifdef CLEAN_BUILD_NEED_TAIL_CODE
$$(error $$$$(DEFINE_TARGETS) was not evaluated at end of $$(CLEAN_BUILD_NEED_TAIL_CODE)!)
endif
CLEAN_BUILD_NEED_TAIL_CODE := $(CURRENT_MAKEFILE)
endef

# replace values of clean-build protected vars in list $1
# NOTE: if CLEAN_BUILD_PROTECTED_VALUES_SAVED is not defined yet - then $(DEF_HEAD_CODE) was never executed yet:
# - when it will be executed, it will save initial values of protected vars, so nothing to do here,
# else - replace old values of protected vars with current ones
define CLEAN_BUILD_PROTECT_VARS2
CLEAN_BUILD_PROTECTED_VARS := $$(sort $$(CLEAN_BUILD_PROTECTED_VARS) $1)
ifdef CLEAN_BUILD_PROTECTED_VALUES_SAVED
$$(foreach x,CLEAN_BUILD_PROTECTED_VARS $1,$$(eval $$x.v? = $$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$$x)))
endif
endef

# list $1: AAA=b1,b2=e1,e2 BBB=b1,b2=e1,e2,...
CLEAN_BUILD_PROTECT_VARS1 = $(call CLEAN_BUILD_PROTECT_VARS2,$(foreach v,$1,$(firstword $(subst =, ,$v))))
CLEAN_BUILD_PROTECT_VARS = $(eval $(CLEAN_BUILD_PROTECT_VARS1))

# macro to check if clean-build protected $x variable value was changed in target makefile
define CLEAN_BUILD_CHECK_PROTECTED_VAR
$(empty)
ifneq ($$(value $x.v?),$$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$x))
ifeq (,$(filter $x,$(CLEAN_BUILD_OVERRIDEN_VARS)))
$$(error $x value was changed:$$(newline)--- old value:$$(newline)$$(subst \
  $$$$(comment),$$(comment),$(subst $$$$$$$$(newline),$$$$(newline),$$(subst \
  $$$$(newline),$$(newline),$$(value $x.v?)))$$(newline)+++ new value:$$(newline)$$(origin \
  $x):$$(if $$(filter-out undefined,$$(origin $x)),$$(flavor $x):$$(value $x)))$$(newline))
endif
endif
$(empty)
endef

# check that values of protected vars were not changed
# note: error is suppressed (only once) if variable name is specified in $(CLEAN_BUILD_OVERRIDEN_VARS) list
# note: $(CLEAN_BUILD_OVERRIDEN_VARS) list is cleared after checks
# note: $(CLEAN_BUILD_NEED_TAIL_CODE) value is cleared after checks to mark that $(DEF_TAIL_CODE) was evaluated
# note: normally, $(CLEAN_BUILD_NEED_TAIL_CODE) is checked at head of next included by $(CLEAN_BUILD_DIR)/parallel.mk target makefile,
# but for the last included target makefile - need to check $(CLEAN_BUILD_NEED_TAIL_CODE) here
# - $(CLEAN_BUILD_DIR)/parallel.mk calls $(DEF_TAIL_CODE) with $1=@
define CLEAN_BUILD_CHECK_AT_TAIL
$(if $(filter @,$1),ifdef CLEAN_BUILD_NEED_TAIL_CODE$(newline)$$(error \
  $$$$(DEFINE_TARGETS) was not evaluated at end of $$(CLEAN_BUILD_NEED_TAIL_CODE)!)$(newline)endif)
ifneq (x$(space)x,x x)
$$(error $$$$(space) value was changed)
endif
ifneq (x$(tab)x,x	x)
$$(error $$$$(tab) value was changed)
endif
$(foreach x,$(CLEAN_BUILD_PROTECTED_VARS),$(CLEAN_BUILD_CHECK_PROTECTED_VAR))
CLEAN_BUILD_OVERRIDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=
endef

# protect variables from modifications in target makefiles
CLEAN_BUILD_PROTECTED_VARS := CLEAN_BUILD_PROTECTED_VARS MCHECK CLEAN_BUILD_ENCODE_VAR_VALUE CLEAN_BUILD_CHECK_AT_HEAD \
  CLEAN_BUILD_PROTECT_VARS2 CLEAN_BUILD_PROTECT_VARS1 CLEAN_BUILD_PROTECT_VARS CLEAN_BUILD_CHECK_PROTECTED_VAR CLEAN_BUILD_CHECK_AT_TAIL

else # !MCHECK

# reset
CLEAN_BUILD_CHECK_AT_HEAD:=
CLEAN_BUILD_CHECK_AT_TAIL:=
CLEAN_BUILD_PROTECT_VARS1:=
CLEAN_BUILD_PROTECT_VARS:=

endif # !MCHECK
