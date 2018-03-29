#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'suppress' macro - used to pretty-print commands executed in rules

# run via "$(MAKE) V=1" for commands echoing and verbose output
ifeq (command line,$(origin V))
verbose := $(V:0=)
else
# don't echo executed commands by default
verbose:=
endif

# @ in non-verbose build
quiet := $(if $(verbose),,@)

# run via "$(MAKE) M=1" to print makefiles where targets were defined
ifeq (command line,$(origin M))
cb_infomf := $(M:0=)
else
# don't print makefile names by default
cb_infomf:=
endif

# print percents
# note: 'make_trace_in_color' - defined in $(cb_dir)/trace/trace.mk
ifndef make_trace_in_color
cb_print_percents = [$1]
else
cb_print_percents = [34m[[1m$1[;34m][m
endif

# print tool arguments
# $1 - color name, e.g. GEN
# $2 - arguments (e.g. generated files)
# note: 'make_trace_in_color' - defined in $(cb_dir)/trace/trace.mk
ifndef make_trace_in_color
cb_colorize = $2
else
cb_colorize = $(patsubst %,$(CBLD_$1_COLOR)%[m,$2)
endif

# print short name of a called tool $1 with argument $2
# $1 - tool, e.g. GEN
# $2 - arguments (e.g. generated files)
# $3 - if empty, then colorize arguments
# note: 'make_trace_in_color' - defined in $(cb_dir)/trace/trace.mk
ifndef make_trace_in_color
cb_show_tool = $1$(padto)$2
else
cb_show_tool = $(CBLD_$1_COLOR)$1[m$(padto)$(if $3,$2,$(join $(dir $2),$(call cb_colorize,$1,$(notdir $2))))
endif

ifeq (,$(filter distclean clean,$(MAKECMDGOALS)))

# define macros:
# a) 'suppress' - suppress output of executed build tool - print some pretty message instead, like "CC  source.c", update percent
#   of building targets
#  $1 - a tool
#  $2 - tool arguments
#  $3 - if empty, then colorize argument of the called tool
#  $4 - if empty, then update percent of building targets
# b) 'suppress_targets' - register (leaf) targets in those rules 'suppress' macro is used (for updating percent of building targets)
#  $1 - targets
# c) 'suppress_more' - to call 'suppress' without updating percent of building targets
#  $1 - a tool
#  $2 - tool arguments
#  $3 - if empty, then colorize argument of the called tool
# note: 'cb_add_shown_percents' and 'cb_fmt_percents' macros - are used at second phase, after parsing makefiles, so no need to protect
#  new values of 'cb_shown_percents' and 'cb_shown_remainder' variables
ifdef quiet

# define 'cb_seq' macro - used by 'suppress_targets' macro defined below
# 'z' - sequence generator prefix
z := cb_
include $(cb_dir)/core/seq.mk

# 'suppress_targets' - register (leaf) targets in those rules 'suppress' macro is used (for updating percent of building targets)
# note: here 'cb_seq' is used to count all targets while first "makefiles parsing" phase - this value will be used in
#  $(cb_dir)/core/all.mk for replacing placeholders <TRG_COUNT> and <TRG_COUNT1> in defined below 'cb_add_shown_percents'
suppress_targets = $(if $(foreach =,$1,$(cb_seq)),)

# same as 'suppress_targets', but return passed targets $1
suppress_targets_r = $(suppress_targets)$1

# used to hold current percent of building targets
cb_shown_percents:=
cb_shown_remainder:=

# general formula: percents = current*100/total
# but we need percents value incrementally: 0*100/total, 1*100/total, 2*100/total, ...
# so just remember previous percent value and remainder of prev*100/total:
# 1) current = 0, percents0 = 0, remainder0 = 0
# 2) current = 1, percents1 = int(100/total), remainder1 = rem(100/total)
# 3) current = 2, percents2 = percents1 + int((remainder1 + 100)/total), remainder2 = rem((remainder1 + 100)/total)
# 4) current = 3, percents3 = percents2 + int((remainder2 + 100)/total), remainder3 = rem((remainder2 + 100)/total)
# ...
# note: <TRG_COUNT> and <TRG_COUNT1> are replaced in $(cb_dir)/core/all.mk
cb_add_shown_percents = $(if $(word <TRG_COUNT>,$1),+ $(call \
  cb_add_shown_percents,$(wordlist <TRG_COUNT1>,999999,$1)),$(newline)cb_shown_remainder:=$1)

# try to increment total percents count
# note: this macro should be expanded exactly once for each building target - previously registered via 'suppress_targets'
cb_update_percents = $(eval cb_shown_percents += $(call cb_add_shown_percents,$(cb_shown_remainder) \
 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 \
 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1))

# format percents for printing
# $4 - if empty, then update percent of building targets
cb_fmt_percents = $(if $4,,$(cb_update_percents))$(subst |,,$(subst \
  |0%,00%,$(subst \
  |1%,01%,$(subst \
  |2%,02%,$(subst \
  |3%,03%,$(subst \
  |4%,04%,$(subst \
  |5%,05%,$(subst \
  |6%,06%,$(subst \
  |7%,07%,$(subst \
  |8%,08%,$(subst \
  |9%,09%,$(subst \
  |100%,FIN,|$(words $(cb_shown_percents))%))))))))))))

ifdef cb_infomf
# target-specific: C.^ - defined by 'cb_makefile_info' macro (below)
suppress = $(info $(call cb_print_percents,$(cb_fmt_percents))$(C.^):$(cb_show_tool))@
else
suppress = $(info $(call cb_print_percents,$(cb_fmt_percents))$(cb_show_tool))@
endif

else # !quiet (verbose)

# do not need to replace <TRG_COUNT> and <TRG_COUNT1> in $(cb_dir)/core/all.mk
suppress_targets:=
suppress_targets_r = $1

ifdef cb_infomf
# target-specific: C.^ - defined by 'cb_makefile_info' macro (below)
suppress = $(info $(C.^):$(cb_show_tool))
else
suppress:=
endif

endif # !quiet (verbose)

# 'suppress' macro should be used only once in a rule of a target registered via 'suppress_targets', to show next commands of the rule
#  - use 'suppress_more' macro, which do not updates percent of building targets
# $1 - a tool
# $2 - tool arguments
# $3 - if empty, then colorize argument of the called tool
ifdef suppress
suppress_more = $(call suppress,$1,$2,$3,1)
else
suppress_more:=
endif

# not cleaning up, define 'cb_makefile_info' macro - for given targets $1, define target-specific variable:
# $(C.^) - makefile which specifies how to build the targets and a number of section in the makefile after a call to $(make_continue)
# note: $(cb_make_cont) list is empty or 1 1 1 .. 1 ~ (inside 'make_continue') or 1 1 1 1... (before 'make_continue'):
# note: 'make_continue' is equivalent of: ... cb_make_cont+=~ $(TAIL) cb_make_cont=$(subst ~,1,$(cb_make_cont)) $(HEAD) ...
ifdef cb_infomf
cb_makefile_info = $1:C.^:=$(cb_target_makefile)$(subst +0,,+$(words $(subst ~,,$(cb_make_cont))))
else
cb_makefile_info:=
endif

else # distclean || clean

# do not need to replace <TRG_COUNT> and <TRG_COUNT1> in $(cb_dir)/core/all.mk
suppress_targets:=
suppress_targets_r = $1

endif # distclean || clean

# makefile parsing first phase variables
cb_first_phase_vars += suppress_targets suppress_targets_r cb_makefile_info

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
# note: do not trace calls to 'cb_makefile_info' - its value is used for $(eval ...)
$(call set_global,verbose quiet cb_infomf cb_shown_percents cb_shown_remainder cb_add_shown_percents cb_makefile_info)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: suppress
$(call set_global,cb_print_percents cb_colorize cb_show_tool suppress_targets suppress_targets_r \
  cb_update_percents=cb_shown_percents=cb_shown_percents cb_fmt_percents=cb_shown_percents suppress suppress_more,suppress)
