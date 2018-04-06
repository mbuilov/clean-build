#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

$(info ================ shell_escape =============)

# note: do not use full project infrastructure

# absolute path to the directory of this makefile
# note: 'a_dir' - "project" variable - will be registered as "global" variable in included next core/_defs.mk
a_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# the only variable required by the core clean-build files
CBLD_BUILD ?= $(a_dir)/build

# add core clean-build definitions
# note: all variables defined prior including this file are treated as "project" variables - they are will be registered
#  as "global" ones (protected from changes), so 'a_dir' does not need to be redefined as target-specific variable
include $(a_dir)/../../../core/_defs.mk

# this must be expanded at head of any target makefile
# note: $(define_targets) must be expanded at tail of target makefile
$(cb_prepare)

# directory where to generate files - must be simple path relative to virtual $(out_dir)
# note: here 'gen' - common directory for generated files
# note: here 'shell_escape' - arbitrary directory name, should be unique to avoid names collision in the common 'gen' directory
# note: 'g_dir' - "local" variable - will be reset just before second "rule execution" make phase
g_dir := gen/shell_escape

# output file - simple path relative to virtual $(out_dir)
# note: 'f' - "local" variable - it will be reset just before second "rule execution" make phase
f := $(g_dir)/out.txt

# register output file '$f' as generated one and store absolute path to it in variable 'r'
# note: needed directory for output file will be created automatically
# note: 'r' - "local" variable - it will be reset just before second "rule execution" make phase
r := $(call add_generated_o,$f)

# define target-specific recursive macro (function) 'test'
# $1 - string to pass to $(MAKE) via shell
# note: 'a_dir' - "project" variable, registered above as "global" one
$r: test = $(MAKE) --no-print-directory -f $(a_dir)/print_X.mk X=$(call shell_escape,$1)

# define target-specific variables for use in second "rule execution" phase
$r: t1  := 1
$r: t2  := 1 2
$r: t3  := 1 \2
$r: t4  := 1\ '2
$r: t5  := '1\# 2
$r: t6  := 1\\ 2
$r: t7  := 1\"2
$r: t8  := 1"2
$r: t9  := "2
$r: t10 := '2'
$r: t11 := \'2\'
$r: t12 := } '\#$$2' " (e) " {\\\\"+\*} \( \a ^$$%\#@?

# define a rule for generating file output file '$f' - call target-specific macro 'test' defined above
# note: "local" variable 'r' is not available in second "rule execution" make phase, so use instead automatic variable '@'
$r:
	$(call suppress,GEN,$@)$(call test,$(t1)) > $@
	$(quiet)$(call test,$(t2)) >> $@
	$(quiet)$(call test,$(t3)) >> $@
	$(quiet)$(call test,$(t4)) >> $@
	$(quiet)$(call test,$(t5)) >> $@
	$(quiet)$(call test,$(t6)) >> $@
	$(quiet)$(call test,$(t7)) >> $@
	$(quiet)$(call test,$(t8)) >> $@
	$(quiet)$(call test,$(t9)) >> $@
	$(quiet)$(call test,$(t10)) >> $@
	$(quiet)$(call test,$(t11)) >> $@
	$(quiet)$(call test,$(t12)) >> $@

# 1) add dependency of '$(g_dir)/cmp.txt' on generated file '$f' (both are virtual paths)
#  note: 'need_built_files_r' - imports needed built file '$f' to namespace directory of '$(g_dir)/cmp.txt'
# 2) register file '$(g_dir)/cmp.txt' as generated one (needed output directory will be created automatically)
# 3) add dependency of '$(g_dir)/cmp.txt' on static file '$(a_dir)/result.txt' (absolute path)
# 4) define a rule for generating '$(g_dir)/cmp.txt' - call one of shell utilities macros - 'sh_cmp_files'
# note: automatic variable '$<' - the name of the first prerequisite: $(a_dir)/result.txt
# note: automatic variable '$^' - names of all prerequisites:         $(a_dir)/result.txt $(call o_ns,$(g_dir)/cmp.txt)/$f
# note: automatic variable '$@' - target file:                        $(call o_path,$(g_dir)/cmp.txt)
# note: prerequisites specified before defining a rule are added to the end of '$^' list, so the first prerequisite ($<) will be
#  $(a_dir)/result.txt
$(call add_generated_o,$(call need_built_files_r,$(g_dir)/cmp.txt,$f)): $(a_dir)/result.txt
	$(call suppress,CMP,$@)$(call sh_cmp_files,$<,$(lastword $^)) > $@

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' macro expanded at head
$(define_targets)
