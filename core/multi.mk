#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# support for rules generating multiple files at once (e.g. by calling bison tool)

ifndef TOCLEAN

# list of processed multi-target rules
# note: MULTI_TARGETS is never cleared, only appended (in rule execution second phase)
MULTI_TARGETS:=

# used to count each call of $(MULTI_TARGET)
# note: MULTI_TARGET_NUM is never cleared, only appended (in makefile parsing first phase)
MULTI_TARGET_NUM:=

# make a chain of dependencies of multi-targets on each other: 1 2 3 4 -> 2:| 1; 3:| 2; 4:| 3;
# $1 - list of generated files (absolute paths without spaces)
# note: because all multi-target files are generated at once - when need to update one of them
#  and target file timestamp is updated only after executing a rule, rule execution must be
#  delayed until files are really generated.
MULTI_TARGET_SEQ = $(subst |,:| ,$(subst $(space),$(newline),$(filter-out \
  ||%,$(join $(addsuffix |,$(wordlist 2,999999,$1) |),$1))))

# when some tool (e.g. bison) generates many files, call the tool only once:
#  assign to each generated multi-target rule an unique number
#  and remember if rule with this number was already executed for one of multi-targets
#
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# $4 - $(words $(MULTI_TARGET_NUM))
#
# note: all generated files must depend on prerequisites, making a chain of
#  order-only dependencies between generated files is not enough - a target
#  that depends on existing generated file will be rebuilt as result of changes
#  in prerequisites only if generated file also depends on prerequisites, e.g.
#
#     [good]                     [bad]
#   gen1:| gen2                gen1:| gen2
#   gen1 gen2: prereq     vs   gen2: prereq
#       touch gen1 gen2            touch gen1 gen2
#   trg1: gen1                 trg1: gen1
#   trg2: gen2                 trg2: gen2
#
# note: do not delete some of generated files manually, do 'make clean' to delete them all,
#  otherwise, missing files will be generated correctly, but as side effect up-to-date files are
#  also will be re-generated, this may lead to unexpected rebuilds on second make invocation.
#
define MULTI_TARGET_RULE
$(MULTI_TARGET_SEQ)
$(STD_TARGET_VARS)
$1: $(call fixpath,$2)
	$$(if $$(filter $4,$$(MULTI_TARGETS)),,$$(eval MULTI_TARGETS+=$4)$$(call SUP,MGEN,$1)$3)
MULTI_TARGET_NUM+=1
endef

# remember new value of MULTI_TARGET_NUM, without tracing calls to it because it is incremented
ifdef MCHECK
$(call define_append,MULTI_TARGET_RULE,$(newline)$$(call SET_GLOBAL1,MULTI_TARGET_NUM,0))
endif

# if some tool generates multiple files at one call, it is needed to call
#  the tool only once if any of generated files needs to be updated
# $1 - list of generated files (absolute paths)
# $2 - prerequisites (either absolute or makefile-related)
# $3 - rule
# note: directories for generated files will be auto-created
# note: rule must update all targets
MULTI_TARGET = $(eval $(call MULTI_TARGET_RULE,$1,$2,$3,$(words $(MULTI_TARGET_NUM))))

ifdef MCHECK

# must not use $@ in multi-target rule because it may have different values
#  (any target from multi-targets list), and rule must update all targets at once.
# $1 - list of generated files (absolute paths)
# $3 - rule
CHECK_MULTI_RULE = $(CHECK_GENERATED)$(if $(findstring $$@,$(subst \
  $$$$,,$3)),$(error $$@ cannot be used in multi-target rule:$(newline)$3))

$(eval MULTI_TARGET = $$(CHECK_MULTI_RULE)$(value MULTI_TARGET))

endif # MCHECK

else # clean

# just delete files on 'clean'
MULTI_TARGET = $(eval $(STD_TARGET_VARS))

endif # clean

# makefile parsing first phase variables
CLEAN_BUILD_FIRST_PHASE_VARS += MULTI_TARGET_NUM MULTI_TARGET_SEQ MULTI_TARGET_RULE MULTI_TARGET CHECK_MULTI_RULE

# protect macros from modifications in target makefiles,
# do not trace calls to macros used in ifdefs, passed to environment of called tools or modified via operator +=
$(call SET_GLOBAL,CLEAN_BUILD_FIRST_PHASE_VARS MULTI_TARGETS MULTI_TARGET_NUM,0)

# protect macros from modifications in target makefiles, allow tracing calls to them
$(call SET_GLOBAL,MULTI_TARGET_SEQ MULTI_TARGET_RULE=MULTI_TARGET_NUM=MULTI_TARGET_NUM MULTI_TARGET CHECK_MULTI_RULE)
