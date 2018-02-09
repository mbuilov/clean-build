#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for tracing macro expansions

# NOTE: this file is self-contained and may be used alone
# NOTE: requires: Gnu Make 3.81 or later

# this file defines next minor helpers:
#
#  1) infofn - wrap function call to print and return result of the call, example:
#    A := $(call infofn,$(call func,...))
#
#  2) dump_vars - print values of the variables, example:
#    $(call dump_vars,A B C...)
#
#  3) tracefn - print function name and its arguments, example:
#    func = $(tracefn)fn_body
#
# and the major tracing macro:
#
#  4) trace_calls - replace macros with their traced equivalents, example:
#    $(call trace_calls,macro1 macro2=b1;b2;b3;$$1=e1;e2 macro3 ...)
#
#   Note: trace_calls changes $(flavor) of traced macros - they are become 'recursive'
#   Note: trace_calls changes $(origin) of traced macros - 'command line' -> 'override'
#   Note: command-line variables that are not also defined in the environment are unexported
#   Note: undefined macros or macros having an empty value are not traced

# to disable printing traces in colors, set MAKE_TRACE_IN_COLOR to empty or 0 value
ifneq (,$(filter /%,$(CURDIR)))
# assume UNIX terminal supports ANSI color escape sequences
MAKE_TRACE_IN_COLOR ?= 1
else
# WINDOWS terminal does not support ANSI color escape sequences (until Windows 10, where color support can be somehow enabled)
# note: 'ansi-colors' feature support is added to Gnu Make by this patch:
#  https://github.com/mbuilov/gnumake-windows/blob/master/make-4.2.1-win32-colors.patch
MAKE_TRACE_IN_COLOR ?= $(filter ansi-colors,$(.FEATURES))
endif

# for use in ifdefs
make_trace_in_color := $(MAKE_TRACE_IN_COLOR:0=)

empty:=
space:= $(empty) #
tab:= $(empty)	#
comment:= \#
backslash:= \\#
percent:= %
comma:= ,
define newline


endef
newline:= $(newline)
open_brace:= (
close_brace:= )
keyword_override:= override
keyword_define:= define
keyword_endef:= endef

# format traced value
# $1 - value text
# $2 - prefix: <
# $3 - suffix: >
# $4 - multiline continuation: \
# $5 - continuation prefix: d
#
# - if $4 is empty:
# <>
# <>
#
# - if $4 is non-empty:
# \
# d<>
# d<>
ifndef make_trace_in_color
format_traced_value = $(if $4,$(if $(findstring $(newline),$1),$4$(newline)$5))$2$(subst $(newline),$3$(newline)$5$2,$1)$3
else
format_traced_value = $(if $4,$(if $(findstring $(newline),$1),$4$(newline)$5))$2$(subst $(newline),$3$(newline)$5$2,$(subst \
  $(comma),[31;1m$(comma)[m,$(subst \
  $(close_brace),[36;1m$(close_brace)[m,$(subst \
  $(open_brace),[36;1m$(open_brace)[m,$(subst \
  $$$(open_brace),[32;1m$$$(open_brace)[m,$(subst \
  define ,[35mdefine[m ,$(subst \
  endef,[35mendef[m,$(subst \
  include ,[35minclude[m ,$(subst \
  ifeq ,[35mifeq[m ,$(subst \
  ifneq ,[35mifneq[m ,$(subst \
  ifdef ,[35mifdef[m ,$(subst \
  else,[35melse[m,$(subst \
  endif,[35mendif[m,$(subst \
  .PHONY,[33;1m.PHONY[m,$(subst \
  override ,[33;1moverride[m ,$(subst \
  $$$(open_brace)if ,$$$(open_brace)[33;1mif[m ,$(subst \
  $$$(open_brace)or ,$$$(open_brace)[33;1mor[m ,$(subst \
  $$$(open_brace)and ,$$$(open_brace)[33;1mand[m ,$(subst \
  $$$(open_brace)dir ,$$$(open_brace)[33;1mdir[m ,$(subst \
  $$$(open_brace)eval ,$$$(open_brace)[33;1meval[m ,$(subst \
  $$$(open_brace)call ,$$$(open_brace)[33;1mcall[m ,$(subst \
  $$$(open_brace)info ,$$$(open_brace)[33;1minfo[m ,$(subst \
  $$$(open_brace)join ,$$$(open_brace)[33;1mjoin[m ,$(subst \
  $$$(open_brace)sort ,$$$(open_brace)[33;1msort[m ,$(subst \
  $$$(open_brace)word ,$$$(open_brace)[33;1mword[m ,$(subst \
  $$$(open_brace)error ,$$$(open_brace)[33;1merror[m ,$(subst \
  $$$(open_brace)strip ,$$$(open_brace)[33;1mstrip[m ,$(subst \
  $$$(open_brace)shell ,$$$(open_brace)[33;1mshell[m ,$(subst \
  $$$(open_brace)subst ,$$$(open_brace)[33;1msubst[m ,$(subst \
  $$$(open_brace)value ,$$$(open_brace)[33;1mvalue[m ,$(subst \
  $$$(open_brace)words ,$$$(open_brace)[33;1mwords[m ,$(subst \
  $$$(open_brace)flavor ,$$$(open_brace)[33;1mflavor[m ,$(subst \
  $$$(open_brace)filter ,$$$(open_brace)[33;1mfilter[m ,$(subst \
  $$$(open_brace)notdir ,$$$(open_brace)[33;1mnotdir[m ,$(subst \
  $$$(open_brace)origin ,$$$(open_brace)[33;1morigin[m ,$(subst \
  $$$(open_brace)suffix ,$$$(open_brace)[33;1msuffix[m ,$(subst \
  $$$(open_brace)abspath ,$$$(open_brace)[33;1mabspath[m ,$(subst \
  $$$(open_brace)foreach ,$$$(open_brace)[33;1mforeach[m ,$(subst \
  $$$(open_brace)warning ,$$$(open_brace)[33;1mwarning[m ,$(subst \
  $$$(open_brace)basename ,$$$(open_brace)[33;1mbasename[m ,$(subst \
  $$$(open_brace)lastword ,$$$(open_brace)[33;1mlastword[m ,$(subst \
  $$$(open_brace)patsubst ,$$$(open_brace)[33;1mpatsubst[m ,$(subst \
  $$$(open_brace)realpath ,$$$(open_brace)[33;1mrealpath[m ,$(subst \
  $$$(open_brace)wildcard ,$$$(open_brace)[33;1mwildcard[m ,$(subst \
  $$$(open_brace)wordlist ,$$$(open_brace)[33;1mwordlist[m ,$(subst \
  $$$(open_brace)addprefix ,$$$(open_brace)[33;1maddprefix[m ,$(subst \
  $$$(open_brace)addsuffix ,$$$(open_brace)[33;1maddsuffix[m ,$(subst \
  $$$(open_brace)firstword ,$$$(open_brace)[33;1mfirstword[m ,$(subst \
  $$$(open_brace)findstring ,$$$(open_brace)[33;1mfindstring[m ,$(subst \
  $$$(open_brace)filter-out ,$$$(open_brace)[33;1mfilter-out[m ,$(subst \
  $$(newline),$$([34;1mnewline[m),$(subst \
  $$0,[35;1m$$0[m,$(subst \
  $$1,[35;1m$$1[m,$(subst \
  $$2,[35;1m$$2[m,$(subst \
  $$3,[35;1m$$3[m,$(subst \
  $$4,[35;1m$$4[m,$(subst \
  $$5,[35;1m$$5[m,$(subst \
  $$6,[35;1m$$6[m,$(subst \
  $$7,[35;1m$$7[m,$(subst \
  $$8,[35;1m$$8[m,$(subst \
  $$9,[35;1m$$9[m,$1)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))$3
endif

# print result $1 and return $1
# add prefix $2 before printed result
ifndef make_trace_in_color
infofn = $(info $(call format_traced_value,$1,$2<,>))$1
else
infofn = $(info $(call format_traced_value,$1,[32m$2<[m,[32m>[m))$1
endif

# dump variables
# $1 - list of variables to dump
# $2 - optional context
# $(call dump_vars,VAR1,Q: ) -> print 'Q: dump: VAR1=<xxx>'
# note: surround dump with fake $(if ...) to avoid any text in result of $(dump_vars)
ifndef make_trace_in_color
dump_vars = $(if $(foreach =,$1,$(warning $2dump: $=$(foreach \
  :,$(if $(call check_if_traced,$=),$(call encode_traced_var_name,$=),$=),$(if $(findstring \
  simple,$(flavor $:)),:)=$(call format_traced_value,$(value $:),<,>,\,)))),)
else
dump_vars = $(if $(foreach =,$1,$(warning $2[35;1mdump[m: [36;1m$=$(foreach \
  :,$(if $(call check_if_traced,$=),$(call encode_traced_var_name,$=),$=),$(if $(findstring \
  simple,$(flavor $:)),[31m:,[35m)=$(call format_traced_value,$(value $:),[36;1m<[m,[36;1m>[m,[36m\[m)))),)
endif

# maximum number of arguments of any macro
dump_max := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40

# set default values for unspecified functions parameters
$(eval override $(subst $(space),:=$(newline)override ,$(dump_max)):=)

# dump function arguments
ifndef make_trace_in_color
dump_args := $(foreach i,$(dump_max),:$$(if \
  $$($i),$$(newline)$$$$$i=$$(call format_traced_value,$$($i),<,>,\,)))
else
dump_args := $(foreach i,$(dump_max),:$$(if \
  $$($i),$$(newline)[34;1m$$$$$i=$$(call format_traced_value,$$($i),[36;1m<[m,[36;1m>[m,[36m\[m)))
endif

$(eval dump_args = $(subst $(space):,, $(dump_args)))

# trace function call - print function name and argument values
# - add $(tracefn) as the first statement of traced function body
# example: fun = $(tracefn)fn_body
ifndef make_trace_in_color
tracefn = $(warning tracefn: $$($0)$(subst $(newline),$(newline)|,$(dump_args)))
else
tracefn = $(warning [35;1mtracefn[m: [32m$$($0)$(subst $(newline),$(newline)[35;1m|[36m,$(dump_args)))
endif

# trace level
mk_trace_level.^l:=

# encode name of traced variable $1
encode_traced_var_name = $1.^t

# helper template for trace_calls macro
# $1 - macro name, must accept no more than $(dump_max) arguments
# $2 - result of $(encode_traced_var_name)
# $3 - override or <empty>
# $4 - names of variables to dump before the traced call
# $5 - names of variables to dump after the traced call
# note: must use $$(call $2,_dump_params_): Gnu Make do not allow recursive calls: $(call a)->$(b)->$(call a)->$(b)->...
ifndef make_trace_in_color
define trace_calls_template
ifdef $1
ifeq (simple,$(flavor $1))
$2:=$$($1)
$3 $1 = $$(warning $$(mk_trace_level.^l) $1:=$$(call \
  format_traced_value,$$($2),<,>,\,))$$($2)
else
$(keyword_define) $2
$(value $1)
$(keyword_endef)
$3 $(keyword_define) $1
$$(foreach tlvl=,$$(words $$(mk_trace_level.^l)),$$(warning \
  $$(mk_trace_level.^l) $1 $$(tlvl=){$$(dump_args))$$(call \
  dump_vars,$4,--> )$$(warning \
  --- $1 value---->$$(newline)$$(call format_traced_value,$$(value $2),<,>))$$(warning \
  --- $1 result--->)$$(eval mk_trace_level.^l+=$1->)$$(call \
  infofn,$$(call $2,_dump_params_),$$(tlvl=))$$(call dump_vars,$5,<-- )$$(eval \
  mk_trace_level.^l:=$$(wordlist 1,$$(tlvl=),$$(mk_trace_level.^l)))$$(warning \
  <===== }$$(tlvl=) $$$$($1)))
$(keyword_endef)
endif
endif
endef
else # make_trace_in_color
define trace_calls_template
ifdef $1
ifeq (simple,$(flavor $1))
$2:=$$($1)
$3 $1 = $$(warning $$(mk_trace_level.^l) [33;1m$1[36m:=$$(call \
  format_traced_value,$$($2),[31;1m<[m,[31;1m>[m,[31m\[m))$$($2)
else
$(keyword_define) $2
$(value $1)
$(keyword_endef)
$3 $(keyword_define) $1
$$(foreach tlvl=,$$(words $$(mk_trace_level.^l)),$$(warning \
  $$(mk_trace_level.^l) [32;1m$1 [;32m$$(tlvl=)[36m{[m$$(dump_args))$$(call \
  dump_vars,$4,[34;1m-->[m )$$(warning \
  [33;1m--- $1 [35mvalue---->[m$$(newline)$$(call format_traced_value,$$(value $2),[35;1m<[m,[35;1m>[m))$$(warning \
  [33;1m--- $1 [32mresult--->[m)$$(eval mk_trace_level.^l+=[36m$1[35;1m->[m)$$(call \
  infofn,$$(call $2,_dump_params_),$$(tlvl=))$$(call dump_vars,$5,[34;1m<--[m )$$(eval \
  mk_trace_level.^l:=$$(wordlist 1,$$(tlvl=),$$(mk_trace_level.^l)))$$(warning \
  [31m<===== [36;1m}[;32m$$(tlvl=)[31;1m $$$$($1)[m))
$(keyword_endef)
endif
endif
endef
endif # make_trace_in_color

# replace _dump_params_ with: $(1),$(2),$(3...)
$(eval define trace_calls_template$(newline)$(subst _dump_params_,$$$$$(open_brace)$(subst \
  $(space),$(close_brace)$(comma)$$$$$(open_brace),$(dump_max))$(close_brace),$(value trace_calls_template))$(newline)endef)

# check if a macro $1 is traced
check_if_traced = $(filter \
  ^$$$(open_brace)warning$$(space)$$(mk_trace_level.^l)% \
  ^$$$(open_brace)foreach$$(space)tlvl=$(comma)$$(words$$(space)$$(mk_trace_level.^l))%,^$(subst \
  $(space),$$(space),$(subst $(tab),$$(tab),$(value $1))))

# replace macros with their traced equivalents
# $1 - traced macros in the form:
#   name=b1;b2;b3;$$1;b4=e1;e2 name2=...
# ($$1 - special case, when macro argument $1 is the names of another macros - dump their values)
# where
#   name            - macro name
#   b1;b2;b3;$$1;b4 - names of variables to dump before traced call
#   e1;e2           - names of variables to dump after traced call
trace_calls = $(foreach =,$(subst ==,=;=,$1),$(foreach :,$(firstword $(subst =, ,$=)),$(if \
  $(findstring undefined,$(origin $:)),,$(if $(call check_if_traced,$:),$(warning warning: not tracing already traced macro: '$:'),$(eval \
  $(call trace_calls_template,$:,$(call encode_traced_var_name,$:),$(if $(findstring command line,$(origin $:)),override,$(findstring \
  override,$(origin $:))),$(subst ;, ,$(word 2,$(subst =, ,$=))),$(subst ;, ,$(word 3,$(subst =, ,$=)))))))))
