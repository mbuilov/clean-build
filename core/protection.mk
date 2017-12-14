#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file is included by $(clean_build_dir)/core/_defs.mk, before including $(clean_build_dir)/core/functions.mk
# define macros for variables protection from accidental changes in target makefiles

# run via $(MAKE) C=1 to check makefiles
ifeq (command line,$(origin C))
cb_checking := $(C:0=)
else
cb_checking:=
endif

# run via $(MAKE) T=1 to trace clean-build macros (most of them)
ifeq (command line,$(origin T))
cb_tracing := $(T:0=)
else
cb_tracing:=
endif

# list of clean-build protected variables
# reset - this variable is checked in trace_calls function in $(clean_build_dir)/trace/trace.mk
cb_protected_vars:=

# list of first-phase variables - these are will be reset before the rule-execution second phase
cb_first_phase_vars:=

ifdef cb_tracing

# list of macros that are should not be traced
#  (like counters - modified via operator +=, or variables used in ifdefs)
CB_NON_TRACEABLE ?=

# namespaces to trace, e.g. O P F T
# empty by default - trace all namespaces
CB_TRACE_FILTER ?=

# namespaces to not trace, e.g. O P F T
# empty by default - trace all namespaces
CB_TRACE_FILTER_OUT ?=

# check if cannot trace variables of given namespace
# $1 - optional namespace name
check_cannot_trace = $(if $1,$(or $(filter $(CB_TRACE_FILTER_OUT),$1),$(if \
  $(CB_TRACE_FILTER),$(filter-out $(CB_TRACE_FILTER),$1))),1)

# protect macros from modification in target makefiles or just trace calls to macros
# $1 - list of the names of the macros to protect/trace, in format:
#  AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (see description of trace_calls macro)
#  note: list must be without names of variables to dump if not tracing - i.e. $2 is empty:
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
set_global = $(eval $(set_global1))

endif # cb_tracing

ifdef cb_checking

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
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (must be without names of variables to dump if not tracing - i.e. $2 is 0)
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
# note: if cb_checking is defined and $2 is empty, expansion of $(call set_global1,...) must add an empty line at
#  end of expansion - $(clean_build_dir)/core/_defs.mk accounts on this
# 1.                                                       $(call set_global1,v) = just protect v, do not trace it
# 2.                            $(call trace_calls,v)                            = trace unprotected v
# 3.                            $(call trace_calls,v)   -> $(call set_global1,v) = trace protected v, protect new v
# 4. $(call set_global1,v,n) -> $(call trace_calls,v,!) -> $(call set_global1,v) = protect v and trace it
ifdef cb_tracing
set_global5 = $(if $1,$$(warning override global: $1))
set_global4 = $(call set_global5,$(filter $1,$(cb_protected_vars)))$(cb_protect_vars2)
set_global3 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1),!))
set_global2 = $(if $1,$(call set_global4,$(foreach =,$1,$(firstword $(subst =, ,$=)))))$(call set_global3,$(filter-out $1,$2))
set_global1 = $(if $(call check_cannot_trace,$2),$(set_global4),$(call \
  set_global2,$(filter $(CB_NON_TRACEABLE) $(CB_NON_TRACEABLE:==%),$1),$1))
else
set_global1 = $(call cb_protect_vars2,$(foreach =,$1,$(firstword $(subst =, ,$=))))
endif

# redefine 'local' variable to produce access error
# $1 - variable name
cb_var_access_err = $(eval $(findstring override,$(origin $1)) $$1=!$$(error \
  using local variable $1, please define instead target-specific variable or register a global one via 'set_global' macro))

# reset "local" variable $=:
# check if it is not already produces access error
cb_reset_local_var = $(if $(filter !$$$(open_brace)error$$(space)%,$(subst \
  $(space),$$(space),$(subst $(tab),$$(tab),$(value $=)))),,$$(call cb_var_access_err,$=))

# only protected variables may remain its values between makefiles,
#  redefine non-protected (i.e. "local") variables to produce access errors
# note: do not touch GNU Make automatic variables (automatic, but, for example, $(origin CURDIR) gives 'file')
# note: do not reset %.^s variables here - they are needed for restore_vars, which will reset them
# note: do not reset trace variables %.^l, %.^t and protected variables %.^p
# note: do not touch automatic/default and $(dump_max) variables
# note: exported variables (e.g. environment, command-line variables) must be protected, so will not reset them
cb_reset_local_vars = $(foreach =,$(filter-out \
  CURDIR GNUMAKEFLAGS MAKECMDGOALS MAKEFILE_LIST MAKELEVEL MAKEOVERRIDES .SHELLSTATUS .DEFAULT_GOAL \
  $(cb_protected_vars) %.^l %.^t %.^p %.^s $(dump_max),$(.VARIABLES)),$(if \
  $(filter file override,$(origin $=)),$(cb_reset_local_var)))

# called by restore_vars to reset %.^s variables
cb_reset_saved_vars = $(foreach =,$(filter %.^s,$(.VARIABLES)),$$(call cb_var_access_err,$=))

# called from $(clean_build_dir)/core/all.mk
# note: reset cb_var_access_err at last, because it's used in the code generated by $(cb_reset_local_var)
cb_reset_first_phase = $(cb_reset_local_vars)$(foreach =,$(cb_first_phase_vars) cb_var_access_err,$(cb_reset_local_var))

# reset "local" variables, check and set cb_need_tail_code - $(def_tail_code) must be evaluated after $(def_head_code)
# note: reset cb_overridden_vars - it may be set before $(def_tail_code)
# note: expansion of $(call set_global1,cb_need_tail_code) gives an empty line at end of expansion
define cb_check_at_head
$(cb_reset_local_vars)$(if $(cb_need_tail_code),$(error $$(define_targets) was not evaluated at end of $(cb_need_tail_code)!))
cb_need_tail_code := $(target_makefile)
$(call set_global1,cb_need_tail_code)cb_overridden_vars:=
endef

# macro to check if clean-build protected $x variable value was changed in target makefile
# $1 - encoded name of variable $=
# note: use $(value) function to get the value of variable $1 - variable is simple,
#  but its name may be non-standard, e.g. CommonProgramFiles(x86)
# note: first line must be empty
define cb_check_protected_var

ifneq ($$(value $1),$$(call cb_encode_var_value,$=))
ifeq (,$$(filter $=,$$(cb_overridden_vars)))
$$(error $= value was changed:$$(newline)--- old value:$$(newline)$$(value \
  $1)$$(newline)+++ new value:$$(newline)$$(call cb_encode_var_value,$=)$$(newline))
endif
endif
endef

# check that values of protected variables are not changed
# note: error is suppressed (only once) if variable name is specified in $(cb_overridden_vars)
# note: cb_need_tail_code is cleared after the checks to mark that $(def_tail_code) was evaluated
# note: $(clean_build_dir)/core/_submakes.mk calls $(def_tail_code) with $1=@
# remember new value of cb_need_tail_code
define cb_check_at_tail
$(if $1,$$(if $$(cb_need_tail_code),$$(error \
  $$$$(define_targets) was not evaluated at end of $$(cb_need_tail_code))),$(if \
  $(cb_need_tail_code),,$(error $$(def_head_code) was not evaluated at head of makefile!)))$(foreach \
  =,$(cb_protected_vars),$(call cb_check_protected_var,$(cb_encode_var_name)))
cb_need_tail_code:=
endef

# protect variables from modifications in target makefiles
# note: do not trace calls to these macros
# note: target_makefile variable is used here temporary and will be redefined later
target_makefile = $(call set_global,cb_checking cb_tracing cb_protected_vars \
  CB_NON_TRACEABLE CB_TRACE_FILTER CB_TRACE_FILTER_OUT check_cannot_trace set_global \
  cb_encode_var_value cb_encode_var_name \
  cb_protect_vars2 set_global5 set_global4 set_global3 set_global2 set_global1 \
  cb_var_access_err \
  cb_reset_local_var cb_reset_local_vars cb_reset_saved_vars cb_reset_first_phase \
  cb_check_at_head cb_check_protected_var cb_check_at_tail)

# these macros must not be used in rule execution second phase
cb_first_phase_vars += cb_checking cb_tracing cb_protected_vars cb_first_phase_vars \
  CB_NON_TRACEABLE CB_TRACE_FILTER CB_TRACE_FILTER_OUT check_cannot_trace set_global \
  cb_overridden_vars cb_need_tail_code cb_encode_var_value cb_encode_var_name \
  cb_protect_vars2 set_global5 set_global4 set_global3 set_global2 set_global1 \
  cb_reset_local_var cb_reset_local_vars cb_reset_saved_vars cb_reset_first_phase \
  cb_check_at_head cb_check_protected_var cb_check_at_tail target_makefile

else # !cb_checking

# reset
cb_reset_first_phase:=
cb_reset_saved_vars:=
cb_check_at_head:=
cb_check_at_tail:=
target_makefile:=

ifdef cb_tracing

# trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - optional namespace name, if not specified, then O (other), namespace 0 means: do not trace calls for given macros
set_global2 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$1),))
set_global1 = $(if $(call check_cannot_trace,$2),,$(call set_global2,$(filter-out $(CB_NON_TRACEABLE) $(CB_NON_TRACEABLE:==%),$1)))

else # !cb_tracing

# reset
set_global:=
set_global1:=

endif # !cb_tracing

endif # !cb_checking
