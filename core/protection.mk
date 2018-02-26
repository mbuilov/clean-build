#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file is included by $(cb_dir)/core/_defs.mk, after including $(cb_dir)/core/functions.mk and $(cb_dir)/trace/trace.mk
# define macros for variables protection from accidental changes in target makefiles

# run via $(MAKE) C=1 to check the makefiles
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

ifneq (,$(cb_checking)$(cb_tracing))
# now all project-defined variables (except some of exported) have the 'override' attribute - protect these variables from modification
# note: trace namespace: project (*)
# note: filter-out %.^e - saved environment variables (see $(cb_dir)/stub/prepare.mk)
# note: filter-out $(project_exported_vars) - exported variables (e.g. command-line ones) should not be traced (to not change their value)
# note: 'cb_protected_vars' variable is used here temporary and will be redefined later
$(eval cb_protected_vars += $$(call set_global,$(foreach =,$(filter-out $(dump_max) %.^e $(project_exported_vars),$(.VARIABLES)),$(if \
  $(findstring override,$(origin $=)),$=)),project))
endif

ifdef cb_checking
# protect from changes $(project_exported_vars) (at least command-line variables), don't trace calls to them to avoid redefining values
#  of exported variables
# note: 'cb_protected_vars' variable is used here temporary and will be redefined later
cb_protected_vars += $(call set_global,$(project_exported_vars))
endif

ifdef cb_tracing

# macros to trace
# empty by default - trace all vars
CBLD_TRACE_VARS ?=

# macros those tracing is disabled
# empty by default - trace all vars
CBLD_TRACE_VARS_EXCEPT ?=

# namespaces to trace, e.g.: functions config
# empty by default - trace all namespaces
CBLD_TRACE_NAMESPACES ?=

# namespaces to not trace, e.g.: functions config
# empty by default - trace all namespaces
CBLD_TRACE_NAMESPACES_EXCEPT ?=

# check if cannot trace variables of given namespace
# $1 - optional namespace name
cb_check_cannot_trace = $(if $1,$(or $(filter $(CBLD_TRACE_NAMESPACES_EXCEPT),$1),$(if \
  $(CBLD_TRACE_NAMESPACES),$(filter-out $(CBLD_TRACE_NAMESPACES),$1))),1)

# check that not trying to trace expansion of CBLD_... variables (they are mostly taken from the environment and should not be changed)
# $1 - names of traced macros
# $2 - namespace
# note: do not check project-specific variables (like CBLD_ROOT, CBLD_OVERRIDES, etc.) - they are traced only if not exported
#  (i.e. not in $(project_exported_vars) list) - see above: trace namespace: project (*)
# note: traced project-specific variables have the 'override' $(origin)
cb_check_tracing_env = $(if $(filter CBLD_%,$1),$(if $(findstring file,$(foreach =,$(filter CBLD_%,$1),$(origin $=))),$(error \
  tracing [$2]: $(foreach =,$(filter CBLD_%,$1),$(if $(findstring file,$(origin $=)),$=))$(newline)By convention, \
  CBLD_... variables may be defined in the environment and so must not be redefined (or traced))))$(info \
  tracing [$2]: $1)$1

ifdef cb_checking

# patch 'trace_calls' macro so that it will protect redefined traced macros if they
#  were protected or it's specifically requested to protect them
# 'trace_calls' will pass second parameter to 'trace_calls_template' - if this parameter
#  is not empty, then forcibly protect new values of traced macros
$(eval trace_calls = $(subst =$(close_brace)$(close_brace)$(close_brace)$(close_brace),$(if \
  ,)=$(close_brace)$(close_brace)$(close_brace)$(comma)$$2$(close_brace),$(value trace_calls)))

# patch 'trace_calls_template' - check if traced macro is protected or second parameter of 'trace_calls' is not empty -
#  then protect new value of traced macro
# note: do not pass second parameter to the 'set_global1' macro to not try to trace already traced macro
trace_calls_template += $(if $(or $6,$(filter $1,$(cb_protected_vars))),$(newline)$(call set_global1,$1))

endif # cb_checking
endif # cb_tracing

# protect macros from modifications in target makefiles or just trace calls to these macros
# $1 - list of macro names for protection/tracking, in format:
#  AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (see description of 'trace_calls' macro)
#  note: list must be without names of variables to dump if not tracing - i.e. $2 is empty:
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
#  (applicable for counters - modified via operator +=, or variables used in ifdefs)
set_global = $(eval $(set_global1))

# get the value of a macro protected via 'set_global'
# $1 - macro name
# note: macro may be traced, get the real (i.e. non-traced) value of the macro
ifdef cb_tracing
get_global = $(value $(if $(check_if_traced),$(encode_traced_var_name),$1))
else
get_global = $(value $1)
endif

# list of environment variables modified in makefiles
# note: this list is updated via 'env_remember' macro
# note: this list is used by 'print_env' macro of $(utils.mk) - e.g. $(cb_dir)/utils/unix.mk
cb_changed_env_vars:=

# remember new values of variables possibly defined in the environment
# $1 - list of variable names
env_remember = $(call env_remember1,$(foreach =,$1,$(if $(findstring file,$(origin $=.^e)),$(eval $$=.^e:=$$(value $$=))$=)))

# update value of 'cb_changed_env_vars'
ifdef cb_checking
env_remember += $(set_global)
env_remember1 = $(if $1,$(eval cb_changed_env_vars+=$$1)$(call set_global,cb_changed_env_vars))
else
env_remember1 = $(eval cb_changed_env_vars+=$$1)
endif

# trace calls to macros, except those used in ifdefs, exported to the environment of called tools or modified via operator +=
# note: trace namespace: core
# note: 'cb_protected_vars' variable is used here temporary and will be redefined later
cb_protected_vars += $(call set_global,get_global env_remember env_remember1,core)

# show a warning about overwritten environment variable $=
# note: variable name may be non-standard, e.g. CommonProgramFiles(x86)
cb_env_var_ov = $(warning environment variable $= was overwritten:$(newline)--- old value:$(newline)$(value \
  $=.^e)$(newline)+++ new value:$(newline)$(value $=)$(newline)tip: \
  use 'env_remember' function to remember a new value of environment variable$(newline))

# check if an environment variable $= was accidentally overwritten
define cb_check_env_var
ifneq ("$$(value $$=)","$$(value $$=.^e)")
$$(cb_env_var_ov)
endif
endef

# at end of target makefile: check that environment variables are not accidentally overwritten
cb_check_env_vars = $(foreach =,$(patsubst %.^e,%,$(filter %.^e,$(.VARIABLES))),$(eval $(cb_check_env_var)))

ifndef cb_checking
ifndef cb_tracing

# reset if not tracing/checking
set_global:=
set_global1:=

else # cb_tracing

# trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;...
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
set_global3 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$(cb_check_tracing_env))))
set_global2 = $(call set_global3,$(if $(CBLD_TRACE_VARS),$(filter $(CBLD_TRACE_VARS) $(CBLD_TRACE_VARS:==%),$1),$1),$2)
set_global1 = $(if $(call cb_check_cannot_trace,$2),,$(call \
  set_global2,$(filter-out $(CBLD_TRACE_VARS_EXCEPT) $(CBLD_TRACE_VARS_EXCEPT:==%),$1),$2))

# 'cb_protected_vars' variable was temporary used to store calls to 'set_global' from $(cb_dir)/core/functions.mk and
#  $(cb_dir)/core/confsup.mk - now 'set_global1' macro is defined, so evaluate those calls
$(eval $(value cb_protected_vars))

endif # cb_tracing

# list of first-phase variables - these are will be reset before the rule-execution second phase
cb_first_phase_vars:=

else # cb_checking

# list of clean-build protected variables
# note: cannot reset 'cb_protected_vars' here - it temporary holds a protection code, will reset 'cb_protected_vars' below in $(eval ...)
#cb_protected_vars:=

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

# 'set_global1' - protect macros from modification in target makefiles or just trace calls to macros
# $1 - list: AAA=b1;b2;$$1=e1;e2 BBB=b1;b2=e1;e2;... (must be without names of variables to dump if not tracing - i.e. $2 is empty)
# $2 - optional namespace name, if not specified, then do not trace calls for given macros
# note: if 'cb_checking' is defined and $2 is empty, expansion of $(call set_global1,...) must add an empty line at
#  end of expansion - $(cb_dir)/core/_defs.mk accounts on this
# 1.                                                       $(call set_global1,v) = just protect v, do not trace it
# 2.                            $(call trace_calls,v)                            = trace unprotected v
# 3.                            $(call trace_calls,v)   -> $(call set_global1,v) = trace protected v, protect new v
# 4. $(call set_global1,v,n) -> $(call trace_calls,v,!) -> $(call set_global1,v) = protect v and trace it
ifdef cb_tracing
set_global6 = $(if $1,$(call dump_vars,$1,overriding global: ))
set_global5 = $(call set_global6,$(filter $1,$(cb_protected_vars)))$(cb_protect_vars2)
set_global4 = $(if $1,$$(call trace_calls,$(subst $$,$$$$,$(cb_check_tracing_env)),$2))
set_global3 = $(if $(CBLD_TRACE_VARS),$(call set_global4,$(filter \
  $(CBLD_TRACE_VARS) $(CBLD_TRACE_VARS:==%),$1),$2,$3 $(filter-out \
  $(CBLD_TRACE_VARS) $(CBLD_TRACE_VARS:==%),$1)),$(set_global4))
set_global2 = $(call set_global3,$(filter-out $3,$1),$2,$3)
set_global1 = $(if $(call cb_check_cannot_trace,$2),$(set_global5),$(call \
  set_global2,$1,$2,$(filter $(CBLD_TRACE_VARS_EXCEPT) $(CBLD_TRACE_VARS_EXCEPT:==%),$1)))
else
set_global1 = $(call cb_protect_vars2,$(foreach =,$1,$(firstword $(subst =, ,$=))))
endif

# 'cb_protected_vars' variable was temporary used to store calls to 'set_global' from $(cb_dir)/core/functions.mk and
#  $(cb_dir)/core/confsup.mk - now 'set_global1' macro is defined, so evaluate those calls
# note: need to reset 'cb_protected_vars' to empty value just before the first call to 'set_global'
$(eval cb_protected_vars:=$(newline)$(value cb_protected_vars))

# redefine "local" variable $= to produce access error
# note: string "!$(error " is checked below in 'cb_reset_local_var' macro
cb_var_access_err = $(eval $(findstring override,$(origin $=)) $$==!$$(error \
  using local variable '$=', instead, define and use target-specific variable or register a global one via 'set_global' macro))

# reset "local" variable $=
# check if it is not already produces access error
cb_reset_local_var = $(if $(filter !$$$(open_brace)error$$(space)%,$(subst \
  $(space),$$(space),$(subst $(tab),$$(tab),$(value $=)))),,$(cb_var_access_err))

# only protected variables may remain its values between makefiles,
#  redefine non-protected (i.e. "local") variables to produce access errors
# note: do not touch GNU Make automatic variables (automatic, but, for example, $(origin CURDIR) gives 'file')
# note: do not reset %.^s variables here - they are needed for 'cb_restore_vars' macro, which will reset them
# note: do not reset %.^e variables - saved environment variables (see $(cb_dir)/stub/prepare.mk)
# note: do not reset trace variables %.^l, %.^t and protected variables %.^p
# note: do not touch automatic/default/environment/command-line and $(dump_max) variables
cb_reset_local_vars = $(foreach =,$(filter-out \
  CURDIR GNUMAKEFLAGS MAKECMDGOALS MAKEFILE_LIST MAKELEVEL MAKEOVERRIDES .SHELLSTATUS .DEFAULT_GOAL \
  $(cb_protected_vars) %.^s %.^e %.^l %.^t %.^p $(dump_max),$(.VARIABLES)),$(if \
  $(filter file override,$(origin $=)),$(cb_reset_local_var)))

# called by 'cb_restore_vars' macro to reset %.^s variables
cb_reset_saved_vars = $(foreach =,$(filter %.^s,$(.VARIABLES)),$(cb_var_access_err))

# called from $(cb_dir)/core/all.mk
cb_reset_first_phase = $(cb_reset_local_vars)$(foreach =,$(cb_first_phase_vars),$(if \
  $(findstring undefined,$(origin $=)),,<cb_reset_local_var>))

# note: don't call 'cb_reset_local_var' - it will be reset before we may call it
$(eval cb_reset_first_phase = $(subst <cb_reset_local_var>,$(value cb_reset_local_var),$(value cb_reset_first_phase)))

# reset "local" variables, check and set 'cb_need_tail_code' - $(cb_def_tail) must be evaluated after $(cb_def_head)
# note: reset 'temporary_overridden' variable - it may be set before previous $(cb_def_tail)
# note: expansion of $(call set_global1,cb_need_tail_code) gives an empty line at end of expansion
define cb_check_at_head
$(if $(cb_need_tail_code),$(error $$(define_targets) was not expanded at end of $(cb_need_tail_code)!))$$(cb_reset_local_vars)
cb_need_tail_code := $(cb_target_makefile)
$(call set_global1,cb_need_tail_code)temporary_overridden:=
endef

# show an error about overwritten protected variable $=
cb_protected_var_ov = $(error protected variable '$=' was overwritten:$(newline)--- old value:$(newline)$(value \
  $1)$(newline)+++ new value:$(newline)$(call cb_encode_var_value,$=)$(newline)tip: \
  use 'set_global' function to set a new value for the global variable$(newline))

# check if a value of clean-build protected variable $= was changed in the target makefile
# $1 - encoded name of the variable $=
# note: use the $(value) function to get a value of variable $1 - variable is simple, but its name may be
#  non-standard, e.g. CommonProgramFiles(x86)
define cb_check_protected_var
ifneq ("$$(value $1)","$$(call cb_encode_var_value,$$=)")
ifeq (,$$(filter $$=,$$(temporary_overridden)))
$$(call cb_protected_var_ov,$1)
endif
endif
endef

# check that values of protected variables were not changed,
# check that environment variables were not accidentally overwritten - their values are saved in $(cb_dir)/stub/prepare.mk
# note: error is suppressed if variable name is specified in $(temporary_overridden) ('cb_check_at_head' resets it)
# note: 'cb_need_tail_code' is cleared after the checks to mark that $(cb_def_tail) was evaluated
# note: $(cb_dir)/core/_submakes.mk calls 'cb_check_at_tail' with $1=@
# note: remember value of 'cb_need_tail_code' to pass checks in $(cb_check_protected_var)
cb_check_at_tail = $(if $1,$(if $(cb_need_tail_code),$(error \
  $$(define_targets) was not expanded at end of $(cb_need_tail_code)),$(call set_global,cb_need_tail_code)),$(if \
  $(cb_need_tail_code),cb_need_tail_code:=,$(error $$(cb_def_head) was not evaluated at head of target makefile!)))$(if \
  $(cb_check_env_vars)$(foreach =,$(cb_protected_vars),$(eval $(call cb_check_protected_var,$(cb_encode_var_name)))),)

# protect variables from modifications in target makefiles
# note: do not trace calls to these macros
$(call set_global,cb_checking cb_tracing \
  CBLD_TRACE_VARS CBLD_TRACE_VARS_EXCEPT CBLD_TRACE_NAMESPACES CBLD_TRACE_NAMESPACES_EXCEPT \
  cb_check_cannot_trace cb_check_tracing_env set_global cb_changed_env_vars cb_env_var_ov cb_check_env_var cb_check_env_vars \
  set_global1 set_global3 set_global2 cb_protected_vars cb_encode_var_value cb_encode_var_name cb_protect_vars2 \
  set_global6 set_global5 set_global4 cb_var_access_err cb_reset_local_var cb_reset_local_vars cb_reset_saved_vars \
  cb_reset_first_phase cb_check_at_head cb_protected_var_ov cb_check_protected_var cb_check_at_tail)

# these macros must not be used in rule execution second phase
# note: do not reset 'cb_var_access_err' and 'cb_reset_first_phase' macros - this causes problems with Gnu Make 3.81, which doesn't
#  like when a macro redefines itself
cb_first_phase_vars := cb_checking cb_tracing cb_check_cannot_trace cb_check_tracing_env set_global \
  cb_changed_env_vars env_remember env_remember1 cb_env_var_ov cb_check_env_var cb_check_env_vars \
  set_global1 set_global3 set_global2 cb_protected_vars cb_encode_var_value cb_encode_var_name cb_protect_vars2 \
  set_global6 set_global5 set_global4 cb_reset_local_var cb_reset_local_vars cb_reset_saved_vars \
  cb_check_at_head cb_protected_var_ov cb_check_protected_var cb_check_at_tail cb_first_phase_vars \
  temporary_overridden cb_need_tail_code

endif # cb_checking
