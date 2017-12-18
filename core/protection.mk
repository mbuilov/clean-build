#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file is included by $(cb_dir)/core/_defs.mk, after including $(cb_dir)/core/functions.mk and $(cb_dir)/trace/trace.mk
# define macros for variables protection from accidental changes in target makefiles

# run via $(MAKE) C=1 to check makefiles
ifeq (command line,$(origin C))
cb_check := $(C:0=)
# do not pollute environment variables namespace
unexport C
else
cb_check:=
endif

# run via $(MAKE) T=1 to trace clean-build macros (most of them)
ifeq (command line,$(origin T))
cb_trace := $(T:0=)
# do not pollute environment variables namespace
unexport T
else
cb_trace:=
endif

ifdef cb_trace

# list of macros that are should not be traced
#  (like counters - modified via operator +=, or variables used in ifdefs)
CBBS_NON_TRACEABLE_VARS ?=

# namespaces to trace, e.g. O P F T
# empty by default - trace all namespaces
CBBS_TRACE_FILTER ?=

# namespaces to not trace, e.g. O P F T
# empty by default - trace all namespaces
CBBS_TRACE_FILTER_OUT ?=

# check if cannot trace variables of given namespace
# $1 - optional namespace name
cb_check_cannot_trace = $(if $1,$(or $(filter $(CBBS_TRACE_FILTER_OUT),$1),$(if \
  $(CBBS_TRACE_FILTER),$(filter-out $(CBBS_TRACE_FILTER),$1))),1)

ifdef cb_check

# patch trace_calls macro so that it will protect redefined traced macros if it they
#  were protected or it's specifically requested to protect them
# trace_calls will pass second parameter to the trace_calls_template -
#  if this parameter is not empty, then forcibly protect new values of traced macros
$(eval trace_calls = $(subst :$(close_brace)$(close_brace)$(close_brace)$(close_brace),\
  :$(close_brace)$(close_brace)$(close_brace)$(comma)$$2$(close_brace),$(value trace_calls)))

# patch trace_calls_template - check if traced macro is protected or second parameter of trace_calls is not empty -
#  then protect new value of traced macro
# note: do not pass second parameter to set_global1 to not try to trace already traced macro
trace_calls_template += $(if $(or $6,$(filter $1,$(cb_protected_vars))),$(newline)$(call set_global1,$1))

endif # cb_check
endif # cb_trace

# protect macros from modifications in target makefiles or just trace calls to these macros
# $1 - list of the names of the macros to protect/trace, in format:
#  AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (see description of trace_calls macro)
#  note: list must be without names of variables to dump if not tracing - i.e. $2 is empty:
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
set_global = $(eval $(set_global1))

# get value of a macro protected via set_global
# $1 - macro name
# note: macro may be traced, get the real (i.e. non-traced) value of the macro
ifdef cb_trace
get_global = $(value $(if $(check_if_traced),$(encode_traced_var_name),$1))
else
get_global = $(value $1)
endif

ifndef cb_check
ifndef cb_trace

# reset if not tracing/checking
set_global:=
set_global1:=

else # cb_trace

# trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
set_global2 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1)))
set_global1 = $(if $(call cb_check_cannot_trace,$2),,$(call \
  set_global2,$(filter-out $(CBBS_NON_TRACEABLE_VARS) $(CBBS_NON_TRACEABLE_VARS:==%),$1)))

endif # cb_trace

# reset
cb_reset_first_phase:=
cb_reset_saved_vars:=
cb_check_at_head:=
cb_check_at_tail:=

# list of first-phase variables - these are will be reset before the rule-execution second phase
cb_first_phase_vars:=

else # cb_check

# list of clean-build protected variables
cb_protected_vars:=

# reset
cb_need_tail_code:=

# encode value of variable $1
cb_encode_var_value = <$(origin $1):$(if $(findstring undefined,$(origin $1)),,$(flavor $1):$(value $1))>

# encode name of protected variable $=
cb_encode_var_name = $=.^p

# store values of clean-build protected variables which must not be changed in target makefiles
# note: after expansion, last line must be empty - callers of $(call set_global1,...) account on this
define cb_protect_vars2
cb_protected_vars := $$(sort $$(cb_protected_vars) $1)
$(foreach =,cb_protected_vars $1,$(cb_encode_var_name):=$$(call cb_encode_var_value,$=)$(newline))
endef

# set_global1 - protect macros from modification in target makefiles or just trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (must be without names of variables to dump if not tracing - i.e. $2 is empty)
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
# note: if cb_check is defined and $2 is empty, expansion of $(call set_global1,...) must add an empty line at
#  end of expansion - $(cb_dir)/core/_defs.mk accounts on this
# 1.                                                       $(call set_global1,v) = just protect v, do not trace it
# 2.                            $(call trace_calls,v)                            = trace unprotected v
# 3.                            $(call trace_calls,v)   -> $(call set_global1,v) = trace protected v, protect new v
# 4. $(call set_global1,v,n) -> $(call trace_calls,v,!) -> $(call set_global1,v) = protect v and trace it
ifdef cb_trace
set_global5 = $(if $1,$$(warning override global: $1))
set_global4 = $(call set_global5,$(filter $1,$(cb_protected_vars)))$(cb_protect_vars2)
set_global3 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1),!))
set_global2 = $(if $1,$(call set_global4,$(foreach =,$1,$(firstword $(subst =, ,$=)))))$(call set_global3,$(filter-out $1,$2))
set_global1 = $(if $(call cb_check_cannot_trace,$2),$(set_global4),$(call \
  set_global2,$(filter $(CBBS_NON_TRACEABLE_VARS) $(CBBS_NON_TRACEABLE_VARS:==%),$1),$1))
else
set_global1 = $(call cb_protect_vars2,$(foreach =,$1,$(firstword $(subst =, ,$=))))
endif

# redefine "local" variable to produce access error
# $1 - variable name
cb_var_access_err = $(eval $(findstring override,$(origin $1)) $$1=!$$(error \
  using local variable $1, please define instead target-specific variable or register a global one via 'set_global' macro))

# reset "local" variable $=
# check if it is not already produces access error
cb_reset_local_var = $(if $(filter !$$$(open_brace)error$$(space)%,$(subst \
  $(space),$$(space),$(subst $(tab),$$(tab),$(value $=)))),,$$(call cb_var_access_err,$=))

# only protected variables may remain its values between makefiles,
#  redefine non-protected (i.e. "local") variables to produce access errors
# note: do not touch GNU Make automatic variables (automatic, but, for example, $(origin CURDIR) gives 'file')
# note: do not reset %.^s variables here - they are needed for restore_vars macro, which will reset them
# note: do not reset trace variables %.^l, %.^t and protected variables %.^p
# note: do not touch automatic/default and $(dump_max) variables
# note: exported variables (environment and command-line variables) must be protected, so will not reset them
cb_reset_local_vars = $(foreach =,$(filter-out \
  CURDIR GNUMAKEFLAGS MAKECMDGOALS MAKEFILE_LIST MAKELEVEL MAKEOVERRIDES .SHELLSTATUS .DEFAULT_GOAL \
  $(cb_protected_vars) %.^l %.^t %.^p %.^s $(dump_max),$(.VARIABLES)),$(if \
  $(filter file override,$(origin $=)),$(cb_reset_local_var)))

# called by restore_vars macro to reset %.^s variables
cb_reset_saved_vars = $(foreach =,$(filter %.^s,$(.VARIABLES)),$$(call cb_var_access_err,$=))

# called from $(cb_dir)/core/all.mk
# note: reset cb_var_access_err at last, because it's used in the code generated by $(cb_reset_local_var)
cb_reset_first_phase = $(cb_reset_local_vars)$(foreach =,$(cb_first_phase_vars) cb_var_access_err,$(cb_reset_local_var))

# reset "local" variables, check and set cb_need_tail_code - $(cb_def_tail_code) must be evaluated after $(cb_def_head_code)
# note: reset temporary_overridden - it may be set before $(cb_def_tail_code)
# note: expansion of $(call set_global1,cb_need_tail_code) gives an empty line at end of expansion
define cb_check_at_head
$(if $(cb_need_tail_code),$(error $$(define_targets) was not evaluated at end of $(cb_need_tail_code)!))$(cb_reset_local_vars)
cb_need_tail_code := $(cb_target_makefile)
$(call set_global1,cb_need_tail_code)temporary_overridden:=
endef

# macro to check if a value of clean-build protected variable $x was changed in target makefile
# $1 - encoded name of variable $=
# note: use $(value) function to get a value of variable $1 - variable is simple,
#  but its name may be non-standard, e.g. CommonProgramFiles(x86)
# note: first line must be empty
define cb_check_protected_var

ifneq ($$(value $1),$$(call cb_encode_var_value,$=))
ifeq (,$$(filter $=,$$(temporary_overridden)))
$$(error $= value was changed:$$(newline)--- old value:$$(newline)$$(value \
  $1)$$(newline)+++ new value:$$(newline)$$(call cb_encode_var_value,$=)$$(newline))
endif
endif
endef

# check that values of protected variables are not changed
# note: error is suppressed (only once) if variable name is specified in $(temporary_overridden)
# note: cb_need_tail_code is cleared after the checks to mark that $(cb_def_tail_code) was evaluated
# note: $(cb_dir)/core/_submakes.mk calls $(cb_def_tail_code) with $1=@
define cb_check_at_tail
$(if $1,$$(if $$(cb_need_tail_code),$$(error \
  $$$$(define_targets) was not evaluated at end of $$(cb_need_tail_code))),$(if \
  $(cb_need_tail_code),,$(error $$(cb_def_head_code) was not evaluated at head of makefile!)))$(foreach \
  =,$(cb_protected_vars),$(call cb_check_protected_var,$(cb_encode_var_name)))
cb_need_tail_code:=
endef

# protect variables from modifications in target makefiles
# note: do not trace calls to these macros
# note: cb_target_makefile variable is used here temporary and will be redefined later
cb_target_makefile += $(call set_global,cb_check cb_trace CBBS_NON_TRACEABLE_VARS CBBS_TRACE_FILTER CBBS_TRACE_FILTER_OUT \
  cb_check_cannot_trace set_global get_global set_global1 cb_reset_first_phase cb_reset_saved_vars cb_check_at_head cb_check_at_tail \
  cb_protected_vars cb_encode_var_value cb_encode_var_name cb_protect_vars2 set_global5 set_global4 set_global3 set_global2 \
  cb_var_access_err cb_reset_local_var cb_reset_local_vars cb_check_protected_var)

# these macros must not be used in rule execution second phase
cb_first_phase_vars := cb_check cb_trace CBBS_NON_TRACEABLE_VARS CBBS_TRACE_FILTER CBBS_TRACE_FILTER_OUT \
  cb_check_cannot_trace set_global set_global1 cb_reset_first_phase cb_reset_saved_vars cb_check_at_head cb_check_at_tail \
  cb_protected_vars cb_encode_var_value cb_encode_var_name cb_protect_vars2 set_global5 set_global4 set_global3 set_global2 \
  cb_reset_local_var cb_reset_local_vars cb_check_protected_var \
  cb_first_phase_vars temporary_overridden cb_need_tail_code cb_target_makefile

endif # cb_check
