#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for rules that generate multiple files at once (e.g. bison)

ifndef cleaning

# used to count each call of $(multi_target)
# note: 'cb_multi_target_num' is never cleared, it's only appended (in makefile parsing first phase)
cb_multi_target_num:=

# list of processed multi-target rules
# note: 'cb_multi_targets' is never cleared, it's only appended (in rule execution second phase)
cb_multi_targets:=

# make a dependency chain of target files of a multi-target rule on each other: 1 2 3 4 -> 2:| 1; 3:| 2; 4:| 3; 1 2 3 4
# $1 - list of generated files (absolute paths without spaces)
# note: without dependency chain, a rule that generates some intermediate target, say 2, may return before the target 2 is really created
cb_multi_target_dep_r = $(subst |,:| ,$(subst $(space),$(newline),$(filter-out \
  ||%,$(join $(addsuffix |,$(wordlist 2,999999,$1) |),$1))))$(newline)$1

# when some tool (e.g. bison) generates many files, call the tool only once:
#  assign to each multi-target rule an unique number and check if a rule with this
#  number was already executed to generate one of its targets
#
# $1 - absolute paths to generated files (in the namespace directory of the first generated file)
# $2 - static prerequisites - either absolute or makefile-related file names
# $3 - rule, which generates all files in the namespace of the first generated file
# $4 - $(words $(cb_multi_target_num))
#
# note: each generated file must depend on all prerequisites in list $2, making a chain of
#  order-only dependencies between generated files is not enough - a target that depends
#  on existing generated file will be rebuilt as result of changes in the prerequisites
#  only if generated file also depends on the prerequisites, e.g.:
#
#     [good]                     [bad]
#   gen1:| gen2                gen1:| gen2
#   gen1 gen2: prereq     vs   gen2: prereq
#       touch gen1 gen2            touch gen1 gen2
#   trg1: gen1                 trg1: gen1  <----------- may be rebuilt on second make invocation
#   trg2: gen2                 trg2: gen2
#
# note: do not delete some of generated files manually, always do 'make clean' to delete them all,
#  otherwise, missing files will be generated correctly, but as side effect up-to-date files are
#  also will be re-generated, this may lead to unexpected rebuilds on second make invocation.
#
define cb_multi_target_rule
$(cb_target_vars_a)
$(cb_multi_target_dep_r): $(call fixpath,$2)
	$$(if $$(filter $4,$$(cb_multi_targets)),,$$(eval cb_multi_targets+=$4)$$(call suppress,GEN,$1)$3)
cb_multi_target_num+=1
endef

# remember new value of 'cb_multi_target_num', without tracing calls to it because it is incremented
ifdef cb_checking
$(call define_append,cb_multi_target_rule,$(newline)$$(call set_global1,cb_multi_target_num))
endif

# if some tool generates multiple files at one call, it is needed to call the tool only once - if any of generated files need to be updated
# $1 - generated files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen/file1.txt gen/file2.txt
# $2 - static prerequisites - either absolute or makefile-related file names
# $3 - rule, which generates all files in the namespace of the first generated file
# note: directories for generated files will be auto-created
# note: rule must update _all_ targets at once - in the namespace directory of the first generated file
multi_target = $(eval $(call cb_multi_target_rule,$(addprefix $(call o_ns,$(firstword $1))/,$1),$2,$3,$(words $(cb_multi_target_num))))

ifdef cb_checking

# must _not_ use $@ in multi-target rule because it may have different values (any file from a list of generated files)
#  - rule must update all targets at once
# $1 - generated files, simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen/file1.txt gen/file2.txt
# $3 - rule, which generates all files in the namespace of the first generated file
cb_check_multi_rule = $(if $(findstring $$@,$(subst $$$$,,$3)),$(error $$@ cannot be used in multi-target rule:$(newline)$3))

$(eval multi_target = $$(cb_check_multi_rule)$(value multi_target))

endif # cb_checking

else # cleaning

# just delete generated files on 'clean'
# $1 - generated files, must be simple paths relative to virtual $(out_dir), e.g.: gen/file.txt gen/file1.txt gen/file2.txt
multi_target = $(eval $(call cb_target_vars_a,$(addprefix $(call o_ns,$(firstword $1))/,$1)))

endif # cleaning

# same as 'multi_target', but return absolute paths to generated files $1 (in namespace directory of the first generated file)
multi_target_o = $(multi_target)$(addprefix $(call o_ns,$(firstword $1))/,$1)

# makefile parsing first phase variables
cb_first_phase_vars += cb_multi_target_num cb_multi_target_dep_r cb_multi_target_rule multi_target cb_check_multi_rule multi_target_o

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, exported to the environment of called tools or modified via operator +=
$(call set_global,cb_first_phase_vars cb_multi_target_num cb_multi_targets)

# protect macros from modifications in target makefiles, allow tracing calls to them
# note: trace namespace: multi
$(call set_global,cb_multi_target_dep_r cb_multi_target_rule=cb_multi_target_num=cb_multi_target_num \
  multi_target cb_check_multi_rule multi_target_o,multi)
