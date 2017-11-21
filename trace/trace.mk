#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for tracing macro expansions, this file is self-contained and may be included alone

# this file defines next minor helpers:
#
# 1) infofn - wrap function call to print result of the call, example:
#   A := $(call infofn,$(call func,...))
#
# 2) dump - print values of the variables, example:
#   $(call dump,A B C...)
#
# 3) dump_args - print function arguments, example:
#   func = $(dump_args)fn_body
#
# 4) tracefn - print function name and its arguments, example:
#   func = $(tracefn)fn_body
#
# and the major tracing macro:
#
# 5) trace_calls - replace macros with their traced equivalents, example:
#   $(call trace_calls,macro1 macro2=b1;b2;b3;$$1=e1;e2 macro3 ...)
#
#  Note: trace_calls changes $(flavor) of traced macros - they are become 'recursive'
#  Note: trace_calls changes $(origin) of traced macros - 'command line' -> 'override'

empty:=
space:= $(empty) $(empty)
comma:= ,
define newline


endef
newline:= $(newline)
open_brace:= (
close_brace:= )
keyword_define:= define
keyword_endef:= endef

# print result $1 and return $1
# add prefix $2 before printed lines
infofn = $(info $2<$(subst $(newline),>$(newline)$2<,$1)>)$1

# dump variables
# $1 - list of variables to dump
# $2 - optional prefix
# $3 - optional pre-prefix
# $(call dump,VAR1,prefix,Q) -> print 'Qdump: prefix: VAR1=xxx'
# note: surround dump with fake $(if) to avoid any text in result of $(dump)
dump = $(if $(foreach dump=,$1,$(info $3dump: $(2:=: )$(dump=)$(if $(findstring \
  simple,$(flavor $(dump=))),:)=$(if $(findstring $(newline),$(value $(dump=))),\$(newline)d<$(subst \
  $(newline),>$(newline)d<,$(value $(dump=)))>,<$(value $(dump=))>))),)

# maximum number of arguments of any macro
dump_max := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40

# set default values for unspecified functions parameters
$(eval override $(subst $(space),:=$(newline)override ,$(dump_max)):=)

# dump function arguments
dump_args := $(foreach i,$(dump_max),:$$(if $$($i),$$(info \
  $$$$$i=$$(if $$(findstring $$(newline),$$($i)),\$$(newline)<$$(subst $$(newline),>$$(newline)<,$$($i))>,<$$($i)>))))
$(eval dump_args = $(subst $(space):,, $(dump_args)))

# trace function call - print function name and argument values
# - add $(tracefn) as the first statement of traced function body
# example: fun = $(tracefn)fn_body
tracefn = $(warning tracefn: $$($0) {)$(dump_args)$(info tracefn: } $$($0))

# trace level
cb_trace_level^:=

# encode variable name $v so that it may be used in $(eval $(encoded_name)=...)
encode_traced_var_name = $(subst $(close_brace),^c@,$(subst $(open_brace),^o@,$(subst :,^d@,$(subst !,^e@,$v)))).^t

# helper template for trace_calls macro
# $1 - macro name, must accept no more than $(dump_max) arguments
# $2 - result of $(encode_traced_var_name)
# $3 - override or <empty>
# $4 - names of variables to dump before traced call
# $5 - names of variables to dump after traced call
# $6 - if non-empty, then forcibly protect new values of traced macros (used by $(CLEAN_BUILD_DIR)/core/protection.mk)
# note: must use $$(call $2,_dump_params_): Gnu Make does not allows recursive calls: $(call a)->$(b)->$(call a)->$(b)->...
# note: first line must be empty
define trace_calls_template

ifdef $1
ifeq (simple,$(flavor $1))
$2:=$$($1)
$3 $(keyword_define) $1
$$(foreach w=,$$(words $$(cb_trace_level^)),$$(warning $$(cb_trace_level^) $$$$($1) $$(w=){)$$(call \
  infofn,$$($2),$$(w=))$$(info <------- }$$(w=) $$$$($1)))
$(keyword_endef)
else
$(keyword_define) $2
$(value $1)
$(keyword_endef)
$3 $(keyword_define) $1
$$(foreach w=,$$(words $$(cb_trace_level^)),$$(warning $$(cb_trace_level^) $$$$($1) $$(w=){)$$(dump_args)$$(call dump,$4,,$1: )$$(info \
  --- $1 value---->)$$(info <$$(subst $$(newline),>$$(newline)<,$$(value $2))>)$$(eval cb_trace_level^+=$1->)$$(info \
  --- $1 result--->)$$(call infofn,$$(call $2,_dump_params_),$$(w=))$$(call dump,$5,,$1: )$$(eval \
  cb_trace_level^:=$$(wordlist 1,$$(w=),$$(cb_trace_level^)))$$(info <------- }$$(w=) $$$$($1)))
$(keyword_endef)
endif
endif
endef

# protect traced macros
# $6 - if non-empty, then forcibly protect new values of traced macros (used by $(CLEAN_BUILD_DIR)/core/protection.mk)
# note: pass 0 as second parameter to SET_GLOBAL1 to not try to trace already traced macro
ifeq (,$(filter-out undefined environment,$(origin SET_GLOBAL1)))
$(eval define trace_calls_template$(newline)$(value trace_calls_template)$(newline)$$(call \
  SET_GLOBAL1,$$2 $$(if $$6,$$1,$$(if $$(filter $$1,$$(CLEAN_BUILD_PROTECTED_VARS)),$$1)),0)$(newline)endef)
endif

# replace _dump_params_ with: $(1),$(2),$(3...)
$(eval define trace_calls_template$(newline)$(subst _dump_params_,$$$$$(open_brace)$(subst \
  $(space),$(close_brace)$(comma)$$$$$(open_brace),$(dump_max))$(close_brace),$(value trace_calls_template))$(newline)endef)

# replace macros with their traced equivalents
# $1 - traced macros in form:
#   name=b1;b2;b3;$$1;b4=e1;e2
# ($$1 - special case, when macro argument $1 is the names of another macros - dump their values)
# $2 - if non-empty, then forcibly protect new values of traced macros (used by $(CLEAN_BUILD_DIR)/core/protection.mk)
# where
#   name            - macro name
#   b1;b2;b3;$$1;b4 - names of variables to dump before traced call
#   e1;e2           - names of variables to dump after traced call
trace_calls = $(eval $(foreach f,$1,$(foreach v,$(firstword $(subst =, ,$f)),$(if $(findstring undefined,$(origin $v)),,$(if $(findstring \
  ^.$$$(open_brace)foreach w=$(comma)$$(words $$(cb_trace_level^))$(comma)$$(warning $$(cb_trace_level^) $$$$($v) $$(w=){),^.$(value \
  $v)),,$(call trace_calls_template,$v,$(encode_traced_var_name),$(if $(findstring command line,$(origin $v)),override,$(findstring \
  override,$(origin $v))),$(subst ;, ,$(word 2,$(subst =, ,$f))),$(subst ;, ,$(word 3,$(subst =, ,$f))),$2))))))
