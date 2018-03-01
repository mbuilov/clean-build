$(info ================ shell_escape =============)

# note: do not use full project infrastructure

# absolute path to the directory of this makefile
a_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# the only variable required by the core clean-build files
CBLD_BUILD ?= $(a_dir)/build

# add core clean-build definitions
# note: all variables defined prior including this file are treated as 'project' variables - they are will be 'global'
#  (protected from changes), so 'a_dir' does not need to be redefined as target-specific variable
include $(a_dir)/../../../core/_defs.mk

# this must be expanded at head of any target makefile
# note: $(define_targets) must be expanded at tail of target makefile
$(cb_prepare)

# directory where to generate files
# note: 'gen_dir' - defined in included above core/_defs.mk
# note: here 'shell_escape' - arbitrary directory name, should be unique to avoid names collision
# note: 'g_dir' variable will be reset just before second "rule execution" make phase
g_dir := $(gen_dir)/shell_escape

# define target-specific recursive macro (function) 'test'
# $1 - string to pass to $(MAKE) via shell
$(g_dir)/out.txt: test = $(MAKE) --no-print-directory -f $(a_dir)/print_X.mk X=$(call shell_escape,$1)

# define variables for use in second "rule execution" phase
$(g_dir)/out.txt: t1  := 1
$(g_dir)/out.txt: t2  := 1 2
$(g_dir)/out.txt: t3  := 1 \2
$(g_dir)/out.txt: t4  := 1\ '2
$(g_dir)/out.txt: t5  := '1\# 2
$(g_dir)/out.txt: t6  := 1\\ 2
$(g_dir)/out.txt: t7  := 1\"2
$(g_dir)/out.txt: t8  := 1"2
$(g_dir)/out.txt: t9  := "2
$(g_dir)/out.txt: t10 := '2'
$(g_dir)/out.txt: t11 := \'2\'
$(g_dir)/out.txt: t12 := } '\#$$2' " (e) " {\\\\"+\*} \( \a ^$$%\#@?

# register generated file '$(g_dir)/out.txt', define a rule for generating it - call target-specific macro 'test' defined above
# note: variable 'g_dir' is not available in the "rule execution" phase, so use instead automatic variable $@
$(call add_generated_ret,$(g_dir)/out.txt):
	$(call test,$(t1)) >> $@
	$(call test,$(t2)) >> $@
	$(call test,$(t3)) >> $@
	$(call test,$(t4)) >> $@
	$(call test,$(t5)) >> $@
	$(call test,$(t6)) >> $@
	$(call test,$(t7)) >> $@
	$(call test,$(t8)) >> $@
	$(call test,$(t9)) >> $@
	$(call test,$(t10)) >> $@
	$(call test,$(t11)) >> $@
	$(call test,$(t12)) >> $@

# register generated file '$(g_dir)/cmp.txt', define a rule for generating it - call one of shell utilities macros 'compare_files'
# note: automatic variable $< - the name of the first prerequisite: $(a_dir)/result.txt
# note: automatic variable $^ - names of all prerequisites:         $(a_dir)/result.txt $(g_dir)/out.txt
# note: automatic variable $@ - target file:                        $(g_dir)/cmp.txt
$(call add_generated_ret,$(g_dir)/cmp.txt): $(a_dir)/result.txt $(g_dir)/out.txt
	$(call compare_files,$<,$(lastword $^)) > $@

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
