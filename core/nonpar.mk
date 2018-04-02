#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for creating groups of targets that should not be executed in parallel
#  (e.g. one linker may consume all available memory and put server to continuous swapping)

ifndef cleaning

# create a chain of order-only dependent targets, so their rules will be executed one after each other
# $1 - cb_$(group_name)_non_par_group
# $2 - target file (absolute path)
define cb_non_par_rule
ifneq (undefined,$(origin $1))
$2:| $$($1)
endif
$1:=$2
endef

# reset 'cb_$(group_name)_non_par_group' variable before the rule execution second phase
ifdef cb_checking
$(eval define cb_non_par_rule$(newline)$(subst \
  endif,else$(newline)cb_first_phase_vars+=$$1$(newline)endif,$(value cb_non_par_rule))$(newline)endef)
endif

# remember new value of 'cb_$(group_name)_non_par_group'
# note: trace namespace: nonpar
ifdef set_global1
$(call define_append,cb_non_par_rule,$(newline)$$(call set_global1,$$1,nonpar))
endif

# create a chain of order-only dependent targets, so their rules will be executed one after each other
# for example:
# $(call non_parallel_execute,my_group,target1)
# $(call non_parallel_execute,my_group,target2)
# $(call non_parallel_execute,my_group,target3)
# ...
# $1 - group name
# $2 - target file, must be simple path relative to virtual $(out_dir), e.g.: gen/file.txt
# note: standard .NOTPARALLEL target, if defined, globally disables parallel execution of all rules, but
#  'non_parallel_execute' macro allows to define a group of targets only those rules must not be executed in parallel
non_parallel_execute = $(eval $(call cb_non_par_rule,cb_$1_non_par_group,$(call o_path,$2)))

else # cleaning

# do nothing on 'clean'
non_parallel_execute:=

endif # cleaning

# makefile parsing first phase variables
cb_first_phase_vars += cb_non_par_rule non_parallel_execute

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: nonpar
$(call set_global,cb_non_par_rule non_parallel_execute,nonpar)
