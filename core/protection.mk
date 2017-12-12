#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file is included by $(CLEAN_BUILD_DIR)/core/_defs.mk, before including $(CLEAN_BUILD_DIR)/core/functions.mk
# define different macros for variables protection from accidental changes in target makefiles

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

# list of clean-build protected variables
# reset - this variable is checked in trace_calls function in $(CLEAN_BUILD_DIR)/trace/trace.mk
CLEAN_BUILD_PROTECTED_VARS:=

# list of first-phase variables
#  - protected variables that change their values in makefile parsing first phase,
#  but whose values are reset immediately before rule execution second phase
CLEAN_BUILD_FIRST_PHASE_VARS:=

ifdef TRACE
# list of user-defined variables that should not be traced
#  (like counters - modified via operator += or variables used in ifdefs)
# reset, may be overridden in project configuration makefile or in command line
NON_TRACEABLE_VARS:=
endif

ifdef MCHECK

# reset
CLEAN_BUILD_OVERRIDDEN_VARS:=
CLEAN_BUILD_NEED_TAIL_CODE:=

# encode value of variable $1
CLEAN_BUILD_ENCODE_VAR_VALUE = <$(origin $1):$(if $(findstring undefined,$(origin $1)),,$(flavor $1):$(value $1))>

# encode variable name $= so that it may be used in $(eval name=...)
CLEAN_BUILD_ENCODE_VAR_NAME = $(subst $(close_brace),^c@,$(subst $(open_brace),^o@,$(subst :,^d@,$(subst !,^e@,$=)))).^p

# store values of clean-build protected variables which must not be changed in target makefiles
# note: after expansion, last line must be empty - callers of $(call SET_GLOBAL1,...,0) account on this
define CLEAN_BUILD_PROTECT_VARS2
CLEAN_BUILD_PROTECTED_VARS := $$(sort $$(CLEAN_BUILD_PROTECTED_VARS) $1)
$(foreach =,CLEAN_BUILD_PROTECTED_VARS $1,$(CLEAN_BUILD_ENCODE_VAR_NAME):=$$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$=)$(newline))
endef

# SET_GLOBAL1 - protect macros from modification in target makefiles
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...  (must be without names of variables to dump if not tracing - i.e. $2 is not empty)
# $2 - if not empty, then do not trace calls for given macros (for example, if called from trace_calls_template)
# note: if MCHECK is defined and $2 is not empty, expansion of $(call SET_GLOBAL1,...,0) must add an empty line
#  at end of expansion - $(CLEAN_BUILD_DIR)/core/_defs.mk accounts on this
# 1.                                                     $(call SET_GLOBAL1,v,0) = just protect v, do not trace it
# 2.                          $(call trace_calls,v)                              = trace unprotected v
# 3.                          $(call trace_calls,v)   -> $(call SET_GLOBAL1,v,0) = trace protected v, protect new v
# 4. $(call SET_GLOBAL1,v) -> $(call trace_calls,v,1) -> $(call SET_GLOBAL1,v,0) = protect v and trace it
ifdef TRACE
SET_GLOBAL5 = $(if $1,$$(warning override global: $1))
SET_GLOBAL4 = $(call SET_GLOBAL5,$(filter $1,$(CLEAN_BUILD_PROTECTED_VARS)))$(CLEAN_BUILD_PROTECT_VARS2)
SET_GLOBAL3 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1),1))
SET_GLOBAL2 = $(if $1,$(call SET_GLOBAL4,$(foreach =,$1,$(firstword $(subst =, ,$=)))))$(call SET_GLOBAL3,$(filter-out $1,$2))
SET_GLOBAL1 = $(if $2,$(SET_GLOBAL4),$(call SET_GLOBAL2,$(filter $(NON_TRACEABLE_VARS) $(NON_TRACEABLE_VARS:==%),$1),$1))
else
SET_GLOBAL1 = $(call CLEAN_BUILD_PROTECT_VARS2,$(foreach =,$1,$(firstword $(subst =, ,$=))))
endif

# protect macros from modification in target makefiles
# $1 - list of macros in form: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for given macros
SET_GLOBAL = $(eval $(SET_GLOBAL1))

# redefine variable to produce access error
# $1 - variable name
CB_VAR_ACCESS_ERR = $(eval $(if $(filter environment,$(origin $1)),$$1=!$$(error \
  using environment variable: $1, use of environment variables is discouraged, please use only file variables),$(findstring \
  override,$(origin $1)) $$1=!$$(error \
  using local variable $1, please define instead target-specific variable or register a global one via SET_GLOBAL macro)))

# reset "local" variable $=:
# check if it is not already produces access error
CLEAN_BUILD_RESET_LOCAL_VAR = $(if $(filter !$$$(open_brace)error$$(space)%,$(subst \
  $(space),$$(space),$(value $=))),,$$(call CB_VAR_ACCESS_ERR,$=)$(newline))

# only protected variables may remain its values between makefiles,
#  redefine non-protected (i.e. "local") variables to produce access errors
# note: do not touch GNU Make automatic variables (automatic, but, for example, $(origin CURDIR) gives 'file')
# note: do not reset %.^s variables here - they are needed for RESTORE_VARS, which will reset them later
# note: do not reset trace variables %.^l %.^t and %.^p - variables which store original values of protected variables
# note: do not touch automatic/default variables
# note: do not reset $(dump_max) variables
CLEAN_BUILD_RESET_LOCAL_VARS = $(foreach =,$(filter-out \
  CURDIR GNUMAKEFLAGS MAKECMDGOALS MAKEFILE_LIST MAKELEVEL MAKEOVERRIDES .SHELLSTATUS .DEFAULT_GOAL \
  $(CLEAN_BUILD_PROTECTED_VARS) %.^l %.^t %.^p %.^s $(dump_max),$(.VARIABLES)),$(if \
  $(filter file override environment,$(origin $=)),$(CLEAN_BUILD_RESET_LOCAL_VAR)))

# called by RESTORE_VARS to reset %.^s variables
CLEAN_BUILD_RESET_SAVED_VARS = $(foreach =,$(filter %.^s,$(.VARIABLES)),$(CLEAN_BUILD_RESET_LOCAL_VAR))

# called from $(CLEAN_BUILD_DIR)/core/all.mk
# note: reset CB_VAR_ACCESS_ERR at end, because it's used in the code generated by $(CLEAN_BUILD_RESET_LOCAL_VAR)
CLEAN_BUILD_RESET_FIRST_PHASE = $(CLEAN_BUILD_RESET_LOCAL_VARS)$(foreach \
  =,$(CLEAN_BUILD_FIRST_PHASE_VARS) CB_VAR_ACCESS_ERR,$(CLEAN_BUILD_RESET_LOCAL_VAR))

# reset "local" variables, check and set CLEAN_BUILD_NEED_TAIL_CODE - $(DEF_TAIL_CODE) must be evaluated after $(DEF_HEAD_CODE)
define CLEAN_BUILD_CHECK_AT_HEAD
$(CLEAN_BUILD_RESET_LOCAL_VARS)$(if $(CLEAN_BUILD_NEED_TAIL_CODE),$(error \
  $$(DEFINE_TARGETS) was not evaluated at end of $(CLEAN_BUILD_NEED_TAIL_CODE)!))CLEAN_BUILD_NEED_TAIL_CODE := $(TARGET_MAKEFILE)
$(call SET_GLOBAL1,CLEAN_BUILD_NEED_TAIL_CODE)
endef

# macro to check if clean-build protected $x variable value was changed in target makefile
# $1 - encoded name of variable $=
# note: first line must be empty
define CLEAN_BUILD_CHECK_PROTECTED_VAR

ifneq ($$($1),$$(call CLEAN_BUILD_ENCODE_VAR_VALUE,$=))
ifeq (,$(filter $=,$(CLEAN_BUILD_OVERRIDDEN_VARS)))
$$(error $= value was changed:$$(newline)--- old value:$$(newline)$$($1)$$(newline)+++ new value:$$(newline)$$(call \
  CLEAN_BUILD_ENCODE_VAR_VALUE,$=)$$(newline))
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
  =,$(CLEAN_BUILD_PROTECTED_VARS),$(call CLEAN_BUILD_CHECK_PROTECTED_VAR,$(CLEAN_BUILD_ENCODE_VAR_NAME)))
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
TARGET_MAKEFILE += $(call SET_GLOBAL,MCHECK TRACE CLEAN_BUILD_PROTECTED_VARS NON_TRACEABLE_VARS \
  CLEAN_BUILD_ENCODE_VAR_VALUE CLEAN_BUILD_ENCODE_VAR_NAME \
  CLEAN_BUILD_PROTECT_VARS2 SET_GLOBAL5 SET_GLOBAL4 SET_GLOBAL3 SET_GLOBAL2 SET_GLOBAL1 SET_GLOBAL CB_VAR_ACCESS_ERR \
  CLEAN_BUILD_RESET_LOCAL_VAR CLEAN_BUILD_RESET_LOCAL_VARS CLEAN_BUILD_RESET_SAVED_VARS CLEAN_BUILD_RESET_FIRST_PHASE \
  CLEAN_BUILD_CHECK_AT_HEAD CLEAN_BUILD_CHECK_PROTECTED_VAR CLEAN_BUILD_CHECK_AT_TAIL,0)

# these macros must not be used in rule execution second phase
CLEAN_BUILD_FIRST_PHASE_VARS += MCHECK TRACE CLEAN_BUILD_PROTECTED_VARS CLEAN_BUILD_FIRST_PHASE_VARS NON_TRACEABLE_VARS \
  CLEAN_BUILD_OVERRIDDEN_VARS CLEAN_BUILD_NEED_TAIL_CODE \
  CLEAN_BUILD_ENCODE_VAR_VALUE CLEAN_BUILD_ENCODE_VAR_NAME \
  CLEAN_BUILD_PROTECT_VARS2 SET_GLOBAL5 SET_GLOBAL4 SET_GLOBAL3 SET_GLOBAL2 SET_GLOBAL1 SET_GLOBAL \
  CLEAN_BUILD_RESET_LOCAL_VAR CLEAN_BUILD_RESET_LOCAL_VARS CLEAN_BUILD_RESET_SAVED_VARS CLEAN_BUILD_RESET_FIRST_PHASE \
  CLEAN_BUILD_CHECK_AT_HEAD CLEAN_BUILD_CHECK_PROTECTED_VAR CLEAN_BUILD_CHECK_AT_TAIL TARGET_MAKEFILE

else # !MCHECK

# reset
CLEAN_BUILD_RESET_FIRST_PHASE:=
CLEAN_BUILD_RESET_SAVED_VARS:=
CLEAN_BUILD_CHECK_AT_HEAD:=
CLEAN_BUILD_CHECK_AT_TAIL:=

ifdef TRACE

# trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - if not empty, then do not trace calls for the given macros (for example, if called from trace_calls_template)
SET_GLOBAL2 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1),))
SET_GLOBAL1 = $(if $2,,$(call SET_GLOBAL2,$(filter-out $(NON_TRACEABLE_VARS) $(NON_TRACEABLE_VARS:==%),$1)))

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
