#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for processing sub-makefiles

# Note: $(cb_dir)/core/_defs.mk must be included prior this file - this is done by the $(cb_dir)/stub/submakes.mk

# the name of a file to look for, if sub-makefile is specified by its directory path
CBLD_MAKEFILE_NAME ?= Makefile

# recognized extensions and names of sub-makefiles
CBLD_MAKEFILE_PATTERNS ?= .mk .mak /makefile /$(CBLD_MAKEFILE_NAME)

# generate code of 'cb_norm_makefiles' macro - multiple patsubsts in $2, such as:
# $(patsubst %/Makefile/Makefile,%/Makefile,$(patsubst %.mak/Makefile,%.mak,...,$2))
cb_norm_makefiles = $(if $1,$(call cb_norm_makefiles,$(wordlist 2,999999,$1),$$(patsubst \
  %$(firstword $1)/$(CBLD_MAKEFILE_NAME),%$(firstword $1),$2)),$2)

# 'cb_norm_makefiles' - make absolute paths to sub-makefiles $1, assuming some of them may be specified by directory path:
# 1) add path to directory of $(cb_target_makefile) if makefile path is not absolute
# 2) add /Makefile if makefile path do not ends with any of $(CBLD_MAKEFILE_PATTERNS) (i.e. specified by a directory)
# e.g.: $(call cb_norm_makefiles,/d/aa bb.mk) -> /d/aa/Makefile /c/bb.mk
$(eval cb_norm_makefiles = $(call cb_norm_makefiles,$(CBLD_MAKEFILE_PATTERNS),$$(addsuffix /$(CBLD_MAKEFILE_NAME),$$(call fixpath,$$1))))

# $m - absolute path to sub-makefile to include
# $2 - current 'tool_mode' value
# note: 'tool_mode' value may be changed (set) in included sub-makefile, so restore 'tool_mode' before including next sub-makefile
# note: last line must be empty to allow to join multiple $(cb_include_template)s together
define cb_include_template
tool_mode:=$2
cb_target_makefile:=$m
include $m

endef

# remember new value of 'cb_target_makefile'
# note: 'tool_mode' value will be processed in 'cb_def_head'
# note: trace namespace: core
ifdef set_global1
$(eval define cb_include_template$(newline)$(subst include,$$(call \
  set_global1,cb_target_makefile,core)$(newline)include,$(value cb_include_template))$(newline)endef)
endif

# generate code for processing given list of sub-makefiles
# $1 - absolute paths to sub-makefiles to include
# $2 - current value of 'tool_mode'
define cb_include_submakes
cb_include_level+=.
$(foreach m,$1,$(cb_include_template))cb_include_level:=$(cb_include_level)
endef

# remember new value of 'cb_include_level', without tracing calls to it because it is incremented
# note: assume result of $(call set_global1,...) will give an empty line at end of expansion
ifdef cb_checking
$(eval define cb_include_submakes$(newline)$(subst \
  cb_include_level+=.$(newline),cb_include_level+=.$(newline)$$(call set_global1,cb_include_level),$(value \
  cb_include_submakes))$(newline)$$(call set_global1,cb_include_level)$(newline)endef)
endif

ifndef toclean

# note: 'order_deps' value may be changed in included sub-makefile, so restore 'order_deps' before including next sub-makefile
$(call define_prepend,cb_include_template,order_deps:=$$(order_deps)$(newline))

# remember new value of 'order_deps', without tracing calls to it because it is incremented
# note: assume result of $(call set_global1,...) will give an empty line at end of expansion
ifdef cb_checking
$(eval define cb_include_template$(newline)$(subst include,$$(call \
  set_global1,order_deps)include,$(value cb_include_template))$(newline)endef)
endif

# append makefiles of the modules (really PHONY targets created from them) to 'order_deps' list
# note: argument $1 - list of module makefiles (or directories, where Makefile file is searched)
add_mdeps = $(call add_mdeps1,$(filter-out $(order_deps),$(cb_norm_makefiles:=-)))
add_mdeps1 = $(if $1,$(eval order_deps+=$$1)$(add_mdeps2))

# add empty rules for makefile dependencies (which are absolute paths to dependency makefiles with appended '-' suffix):
#  don't complain if order dependencies cannot be resolved if build was started in some inner sub-directory
ifneq (file,$(origin cb_target_makefiles))
add_mdeps2 = $(eval $$1:$(newline))
else
# filter-out already processed dependent target makefiles
add_mdeps2 = $(call add_mdeps3,$(filter-out $(cb_target_makefiles:=-),$1))
add_mdeps3 = $(if $1,$(eval $$1:$(newline)))
endif

ifdef cb_checking

# remember new value of 'order_deps', without tracing calls to it because it is incremented
$(eval add_mdeps1 = $(subst +=$$1,+=$$1$$(newline)$$(call set_global1,order_deps),$(value add_mdeps1)))

# check that dependent makefiles exist
# note: use fake $(if ...) around $(foreach ...) so 'add_mdeps3' will not produce any text output
$(eval add_mdeps3 = $$(if $$(foreach m,$$1,$$(if $$(wildcard $$(m:-=)),,$$(error \
  $$(cb_target_makefile): dependent makefile does not exist: $$(m:-=)))))$(value add_mdeps3))

endif # cb_checking

# $(cb_target_makefile) is built if all sub-makefiles in list $1 are built
# note: $(cb_target_makefile)- and other order-dependent makefile names - are .PHONY targets
# note: use order-only dependency, so normal dependencies of $(cb_target_makefile)-
#  will be only files - for the checks in $(cb_dir)/core/_defs.mk (where automatic variable $^ is used)
$(call define_prepend,cb_include_submakes,.PHONY: $$(addsuffix \
  -,$$1)$(newline)$$(cb_target_makefile)-:| $$(addsuffix -,$$1)$(newline))

# show debug info
ifdef cb_mdebug
$(call define_prepend,cb_include_submakes,$$(info $$(subst \
  $$(space),,$$(cb_include_level))$$(cb_target_makefile)$$(if $$(order_deps), | $$(order_deps))))
endif

else ifdef cb_mdebug # clean

# show debug info when cleaning up
# note: do not show 'order_deps' because it is not defined
$(call define_prepend,cb_include_submakes,$$(info $$(subst \
  $$(space),,$$(cb_include_level))$$(cb_target_makefile)))

endif # clean && cb_mdebug

# macro 'process_submakes' normally called with non-empty first argument $1, but to avoid defining global variable 1 for the
#  next processed sub-makefiles, macro 'cb_submakes_eval' must be expanded by explicit $(call cb_submakes_eval) without arguments
# note: call 'cb_def_tail' with argument @ - for the checks in 'cb_check_at_tail' macro (defined in $(cb_dir)/core/protection.mk)
# note: process result of 'cb_def_tail' with separate $(eval) - for the checks performed while expanding $(eval argument)
cb_submakes_eval = $(eval $(value cb_submakes_code))$(eval $(call cb_def_tail,@))

# generate code 'cb_submakes_code' for including and processing given list of sub-makefiles $1,
#  then evaluate it via call without parameters - to hide $1 argument from sub-makefiles
# at end, check if it's needed to include $(cb_dir)/core/all.mk
# note: make absolute paths to sub-makefiles
process_submakes = $(eval define cb_submakes_code$(newline)$(call \
  cb_include_submakes,$(cb_norm_makefiles),$(is_tool_mode))$(newline)endef)$(call cb_submakes_eval)

# set 'cb_need_submakes' to non-empty value before including sub-makefiles - to check if a sub-makefile calls 'process_submakes',
#  it _must_ evaluate 'cb_submakes_prepare' prior calling 'process_submakes' - by including appropriate makefile of project build
#  system, e.g. 'make/submakes.mk'
# note: protect 'cb_need_submakes' to not reset it as a local variable, do not trace calls to it
ifdef cb_checking
cb_submakes_prepare = $(eval cb_need_submakes:=)
$(eval process_submakes = $$(if $$(cb_need_submakes),$$(error submakes.mk was not included at head of makefile!))$(subst \
  eval ,eval cb_need_submakes:=1$$(newline)$$(call set_global1,cb_need_submakes)$$(newline),$(value process_submakes)))
else
cb_submakes_prepare:=
endif

# makefile parsing first phase variables
cb_first_phase_vars += cb_include_template cb_include_submakes \
  add_mdeps1 add_mdeps2 add_mdeps3 cb_submakes_eval process_submakes cb_submakes_prepare

# protect 'cb_first_phase_vars' from modification in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars CBLD_MAKEFILE_NAME CBLD_MAKEFILE_PATTERNS)

# protect variables from modifications in target makefiles
# note: do not complain about redefined 'add_mdeps', re-protect it again with a new value
# note: trace namespace: submakes
$(call set_global,cb_norm_makefiles cb_include_template=order_deps;m \
  cb_include_submakes add_mdeps1 add_mdeps2 add_mdeps3 add_mdeps=order_deps=order_deps \
  cb_submakes_eval=cb_submakes_code process_submakes cb_submakes_prepare,submakes)
