#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define 'suppress' macro - used to pretty-print commands executed by the makefiles

# run via $(MAKE) V=1 for commands echoing and verbose output
ifeq (command line,$(origin V))
verbose := $(V:0=)
else
# don't echo executed commands by default
verbose:=
endif

# @ in non-verbose build
quiet := $(if $(verbose),,@)

# run via $(MAKE) M=1 to print the name of the makefile the target defined in
ifeq (command line,$(origin M))
cb_infomf := $(M:0=)
else
# don't print makefile names by default
cb_infomf:=
endif

# colorize printed percents
# note: $(cb_dir)/utils/cmd.mk redefines: cb_print_percents = [$1]
cb_print_percents = [34m[[1;34m$1[34m][m

# print in color short name of the called tool $1 with the argument $2
# $1 - tool
# $2 - argument
# $3 - if empty, then colorize argument
# note: $(cb_dir)/utils/cmd.mk redefines: cb_colorize = $1$(padto)$2
cb_colorize = $(CBLD_$1_COLOR)$1[m$(padto)$(if $3,$2,$(join $(dir $2),$(addsuffix [m,$(addprefix $(CBLD_$1_COLOR),$(notdir $2)))))

ifeq (,$(filter distclean clean,$(MAKECMDGOALS)))

# suppress: suppress output of executed build tool, print some pretty message instead, like "CC  source.c"
# target-specific: F.^, C.^
# $1 - the tool
# $2 - tool arguments
# $3 - if empty, then colorize argument of the called tool
# note: 'cb_add_shown_percents' macro is checked in the $(cb_dir)/core/_defs.mk and $(cb_dir)/core/all.mk, so must always be defined
# note: 'cb_add_shown_percents' and 'cb_fomat_percents' macros - are used at second phase, after parsing the makefiles,
#  so no need to protect new values of 'cb_shown_percents' and 'cb_shown_remainder' variables
ifdef quiet

# used to hold current percents of executed target makefiles
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
# note: <TARGET_MAKEFILES_COUNT> and <TARGET_MAKEFILES_COUNT1> are replaced in the $(cb_dir)/core/all.mk
cb_add_shown_percents = $(if $(word <TARGET_MAKEFILES_COUNT>,$1),+ $(call \
  cb_add_shown_percents,$(wordlist <TARGET_MAKEFILES_COUNT1>,999999,$1)),$(newline)cb_shown_remainder:=$1)

# try to increment total percents count
cb_update_percents = $(eval cb_shown_percents += $(call cb_add_shown_percents,$(cb_shown_remainder) \
 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 \
 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1))

# format percents for printing
cb_fomat_percents = $(subst |,,$(subst \
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

# target-specific: F.^, C.^
ifdef cb_infomf
suppress = $(info $(call cb_print_percents,$(cb_fomat_percents))$(F.^)$(C.^):$(cb_colorize))@
else
suppress = $(info $(call cb_print_percents,$(cb_fomat_percents))$(cb_colorize))@
endif

else # !quiet (verbose)

# reset: do not need to replace <TARGET_MAKEFILES_COUNT> and <TARGET_MAKEFILES_COUNT1> in the $(cb_dir)/core/all.mk
cb_add_shown_percents:=

ifdef cb_infomf
# target-specific: F.^, C.^
suppress = $(info $(F.^)$(C.^):)
else
suppress:=
endif

endif # !quiet (verbose)

# not cleaning up: define 'cb_makefile_info_templ'
#  - for given target(s) $1, define target-specific variables for printing makefile info
# $(F.^) - makefile which specifies how to build the target
# $(C.^) - number of section in the makefile after a call to $(make_continue)
# note: $(cb_make_cont) list is empty or 1 1 1 .. 1 2 (inside 'make_continue') or 1 1 1 1... (before 'make_continue'):
# note: 'make_continue' is equivalent of: ... cb_make_cont+=2 $(TAIL) cb_make_cont=$(subst 2,1,$(cb_make_cont)) $(HEAD) ...
ifdef cb_infomf

define cb_makefile_info_templ
$1:F.^:=$(cb_target_makefile)
$1:C.^:=$(subst +0,,+$(words $(subst 2,,$(cb_make_cont))))
endef

else ifdef quiet

# remember $(cb_target_makefile) to properly update percents of executed makefiles in the 'suppress' macro
cb_makefile_info_templ = $1:F.^:=$(cb_target_makefile)

else # !quiet (verbose)

# reset
cb_makefile_info_templ:=

endif # !quiet (verbose)

else # distclean || clean

# reset: do not need to replace <TARGET_MAKEFILES_COUNT> and <TARGET_MAKEFILES_COUNT1> in the $(cb_dir)/core/all.mk
cb_add_shown_percents:=
cb_makefile_info_templ:=

endif # distclean || clean

# makefile parsing first phase variables
cb_first_phase_vars += cb_makefile_info_templ

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,verbose quiet cb_infomf cb_shown_percents cb_shown_remainder cb_add_shown_percents)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: suppress
$(call set_global,cb_print_percents cb_colorize cb_update_percents=cb_shown_percents=cb_shown_percents \
  cb_fomat_percents=cb_shown_percents suppress cb_makefile_info_templ,suppress)
