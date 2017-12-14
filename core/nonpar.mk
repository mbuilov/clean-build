#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for creating groups of targets that should not be executed in parallel
#  (e.g. one linker may consume all available resources)

ifndef TOCLEAN

# create a chain of order-only dependent targets, so their rules will be executed one after each other
# $1 - $(group_name)_NON_PARALEL_GROUP
# $2 - target
define NON_PARALLEL_EXECUTE_RULE
ifneq (undefined,$(origin $1))
$2:| $($1)
endif
$1:=$2
endef

# reset $(group_name)_NON_PARALEL_GROUP variable before the rule execution second phase
ifdef CB_CHECKING
$(eval define NON_PARALLEL_EXECUTE_RULE$(newline)$(subst \
  endif,else$(newline)CB_FIRST_PHASE_VARS+=$$1$(newline)endif,$(value NON_PARALLEL_EXECUTE_RULE))$(newline)endef)
endif

# remember new value of $(group_name)_NON_PARALEL_GROUP
ifdef SET_GLOBAL1
$(call define_append,NON_PARALLEL_EXECUTE_RULE,$(newline)$$(call SET_GLOBAL1,$$1))
endif

# create a chain of order-only dependent targets, so their rules will be executed one after each other
# for example:
# $(call NON_PARALLEL_EXECUTE,my_group,target1)
# $(call NON_PARALLEL_EXECUTE,my_group,target2)
# $(call NON_PARALLEL_EXECUTE,my_group,target3)
# ...
# $1 - group name
# $2 - target
# note: standard .NOTPARALLEL target, if defined, globally disables parallel execution of all rules,
#  NON_PARALLEL_EXECUTE macro allows to define a group of targets those rules must not be executed in parallel
NON_PARALLEL_EXECUTE = $(eval $(call NON_PARALLEL_EXECUTE_RULE,$1_NON_PARALEL_GROUP,$2))

else # clean

# just delete files on 'clean'
NON_PARALLEL_EXECUTE:=

endif # clean

# makefile parsing first phase variables
CB_FIRST_PHASE_VARS += NON_PARALLEL_EXECUTE_RULE NON_PARALLEL_EXECUTE

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call SET_GLOBAL,CB_FIRST_PHASE_VARS,0)

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,NON_PARALLEL_EXECUTE_RULE NON_PARALLEL_EXECUTE)
