#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(CLEAN_BUILD_DIR)/core/_defs.mk before including $(CLEAN_BUILD_DIR)/core/functions.mk
# variables protection from accidental changes in target makefiles

# run via $(MAKE) C=1 to check makefiles
ifeq (command line,$(origin C))
MCHECK := $(C:0=)
else
MCHECK:=
endif

# run via $(MAKE) T=1 to trace most of macros
ifeq (command line,$(origin T))
TRACE := $(T:0=)
else
TRACE:=
endif

# reset - this variable is checked in trace_calls function in $(CLEAN_BUILD_DIR)/core/functions.mk
CLEAN_BUILD_PROTECTED_VARS:=

ifdef MCHECK

# reset
CLEAN_BUILD_OVERRIDDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=

# encode value of variable $1
CLEAN_BUILD_ENCODE_VAR_VALUE = <$(origin $1):$(if $(findstring undefined,$(origin $1)),,$(flavor $1):$(value $1))>

# encode variable name $x so that it may be used in $(eval name=...)
CLEAN_BUILD_ENCODE_VAR_NAME = $(subst $(close_brace),^c@,$(subst $(open_brace),^o@,$(subst :,^d@,$(subst !,^e@,$x)))).^p

# store values of clean-build protected variables which must not be changed in target makefiles
# note: after expansion, last line must be empty - callers of $(call SET_GLOBAL1,...,0) account on this
define CLEAN_BUILD_PROTECT_VARS2
CLEAN_BUILD_PROTECTED_VARS := $$(sort $$(CLEAN_BUILD_PROTECTED_VARS) $1)
$(foreach x,CLEAN_BUILD_PROTECTED_VARS $1,$(CLEAN_BUILD_ENCODE_VAR_NAME):=$$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$x)$(newline))
endef

# protect macros from modification in target makefiles
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for given macros (for example, if called from trace_calls_template)
# note: if $2 is not empty, expansion of $(call SET_GLOBAL1,...,0) will give an empty line at end of expansion
ifdef TRACE
SET_GLOBAL1 = $(if $2,$(foreach x=,$(filter $1,$(CLEAN_BUILD_PROTECTED_VARS)),$(info \
  override global: $(x=)))$(CLEAN_BUILD_PROTECT_VARS2),$$(call trace_calls,$1,1))
else
SET_GLOBAL1 = $(call CLEAN_BUILD_PROTECT_VARS2,$(foreach v,$1,$(firstword $(subst =, ,$v))))
endif

# protect macros from modification in target makefiles
# $1 - list of macros in form: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for given macros
SET_GLOBAL = $(eval $(SET_GLOBAL1))

# reset "local" variable $v
CLEAN_BUILD_RESET_LOCAL_VAR = $(if \
  $(filter file override environment,$(origin $v)),$(if \
  $(filter-out !$$$(open_brace)error$(space)%,$(value $v)),$(if \
  $(filter environment,$(origin $v)),$v=!$$(error \
  using environment variable: $v, use of environment variables is discouraged, please use only file variables),$(findstring \
  override,$(origin $v)) $v=!$$(error \
  using local varaible: $v, please use target-specific or global one))$(newline)))

# only protected global and target-specific variables may be used in rules,
#  so redefine non-protected global (i.e. "local") variables to produce access errors
# note: do not touch GNU Make automatic variable MAKEFILE_LIST
# note: do not reset %^saved variables here - they are needed for RESTORE_VARS, which will reset them
CLEAN_BUILD_RESET_LOCAL_VARS = $(foreach v,$(filter-out \
  MAKEFILE_LIST $(CLEAN_BUILD_PROTECTED_VARS) %^saved,$(.VARIABLES)),$(CLEAN_BUILD_RESET_LOCAL_VAR))

# called by RESTORE_VARS to reset %^saved variables
CLEAN_BUILD_RESET_SAVED_VARS = $(foreach v,$(filter %^saved,$(.VARIABLES)),$(CLEAN_BUILD_RESET_LOCAL_VAR))

# check and set CLEAN_BUILD_NEED_TAIL_CODE - $(DEF_TAIL_CODE) must be evaluated after $(DEF_HEAD_CODE)
define CLEAN_BUILD_CHECK_AT_HEAD
$(CLEAN_BUILD_RESET_LOCAL_VARS)$(if $(CLEAN_BUILD_NEED_TAIL_CODE),$(error \
  $$(DEFINE_TARGETS) was not evaluated at end of $(CLEAN_BUILD_NEED_TAIL_CODE)!))CLEAN_BUILD_NEED_TAIL_CODE := $(TARGET_MAKEFILE)
$(call SET_GLOBAL1,CLEAN_BUILD_NEED_TAIL_CODE)
endef

# macro to check if clean-build protected $x variable value was changed in target makefile
# $1 - encoded name of variable $x
# note: first line must be empty
define CLEAN_BUILD_CHECK_PROTECTED_VAR

ifneq ($$($1),$$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$x))
ifeq (,$(filter $x,$(CLEAN_BUILD_OVERRIDDEN_VARS)))
$$(error $x value was changed:$$(newline)--- old value:$$(newline)$$($1)$$(newline)+++ new value:$$(newline)$$(call \
  CLEAN_BUILD_ENCODE_VAR_VALUE,$x)$$(newline))
endif
endif
endef

# check that values of protected vars were not changed
# note: error is suppressed (only once) if variable name is specified in $(CLEAN_BUILD_OVERRIDDEN_VARS)
# note: CLEAN_BUILD_OVERRIDDEN_VARS is cleared after the checks
# note: CLEAN_BUILD_NEED_TAIL_CODE is cleared after the checks to mark that $(DEF_TAIL_CODE) was evaluated
# note: $(CLEAN_BUILD_DIR)/core/_parallel.mk calls $(DEF_TAIL_CODE) with $1=@
# remember new values of CLEAN_BUILD_OVERRIDDEN_VARS and CLEAN_BUILD_NEED_TAIL_CODE
define CLEAN_BUILD_CHECK_AT_TAIL
$(if $1,$$(if $$(CLEAN_BUILD_NEED_TAIL_CODE),$$(error \
  $$$$(DEFINE_TARGETS) was not evaluated at end of $$(CLEAN_BUILD_NEED_TAIL_CODE))),$(if \
  $(CLEAN_BUILD_NEED_TAIL_CODE),,$(error $$(DEF_HEAD_CODE) was not evaluated at head of makefile!)))$(foreach \
  x,$(CLEAN_BUILD_PROTECTED_VARS),$(call CLEAN_BUILD_CHECK_PROTECTED_VAR,$(CLEAN_BUILD_ENCODE_VAR_NAME)))
CLEAN_BUILD_OVERRIDDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=
$(call SET_GLOBAL1,CLEAN_BUILD_OVERRIDDEN_VARS CLEAN_BUILD_NEED_TAIL_CODE)
endef

# protect variables from modifications in target makefiles
# note: TARGET_MAKEFILE variable is used here temporary and will be redefined later
TARGET_MAKEFILE = $(call SET_GLOBAL,CLEAN_BUILD_OVERRIDDEN_VARS CLEAN_BUILD_NEED_TAIL_CODE)

# protect variables from modifications in target makefiles
# note: do not trace calls to these macros
# note: TARGET_MAKEFILE variable is used here temporary and will be redefined later
TARGET_MAKEFILE += $(call SET_GLOBAL,CLEAN_BUILD_PROTECTED_VARS \
  MCHECK TRACE CLEAN_BUILD_ENCODE_VAR_VALUE CLEAN_BUILD_ENCODE_VAR_NAME \
  CLEAN_BUILD_PROTECT_VARS2 SET_GLOBAL1 SET_GLOBAL \
  CLEAN_BUILD_RESET_LOCAL_VAR CLEAN_BUILD_RESET_LOCAL_VARS CLEAN_BUILD_RESET_SAVED_VARS \
  CLEAN_BUILD_CHECK_AT_HEAD CLEAN_BUILD_CHECK_PROTECTED_VAR CLEAN_BUILD_CHECK_AT_TAIL,0)

else # !MCHECK

# reset
CLEAN_BUILD_RESET_LOCAL_VARS:=
CLEAN_BUILD_RESET_SAVED_VARS:=
CLEAN_BUILD_CHECK_AT_HEAD:=
CLEAN_BUILD_CHECK_AT_TAIL:=

ifdef TRACE

# trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for given macros (for example, if called from trace_calls_template)
SET_GLOBAL1 = $(if $2,,$$(call trace_calls,$1,))

# trace calls to macros
# $1 - list of macros in form: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for given macros
SET_GLOBAL = $(eval $(SET_GLOBAL1))

else # !TRACE

# reset
SET_GLOBAL1:=
SET_GLOBAL:=

endif # !TRACE

endif # !MCHECK
