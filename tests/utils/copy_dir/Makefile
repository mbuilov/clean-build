#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

$(info ================ sh_copy_dir ==============)

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
# note: here 'copied' - arbitrary directory name, should be unique to avoid names collision in the common 'gen' directory
# note: 'g_dir' - "local" variable - will be reset just before second "rule execution" make phase
g_dir := gen/copied

# function for searching files
# $1 - absolute path to the directory where to search
wildcard_fn = $(patsubst $1/%,%,$(wildcard \
  $1/*) $$(wildcard \
  $1/*/*) $$(wildcard \
  $1/*/*/*) $$(wildcard \
  $1/*/*/*/*) $$(wildcard \
  $1/*/*/*/*/*) $$(wildcard \
  $1/*/*/*/*/*/*) $$(wildcard \
  $1/*/*/*/*/*/*/*))

# absolute path to the source files directory 'test_files'
src := $(call fixpath,test_files)

# create target-specific variable 'src' - absolute path to the source files directory
$(call o_path,$(g_dir)/stamp1.txt $(g_dir)/stamp2.txt $(g_dir)/stamp3.txt): src := $(src)

# ------- copy1

# will copy files from 'src' directory to the generated one - it should be created by the clean-build
# here $| - automatic variable - list of order-only dependencies, notes:
#  - dependencies that are specified prior definition of a rule are added to the end of $| list
#  - dependencies specified in a rule definition - are added to the head of $| list
# so, get absolute path to '$(g_dir)/dst' from the end of $| list
$(call add_generated_o,$(call create_dirs_r,$(g_dir)/stamp1.txt,$(g_dir)/dst)):
	$(call suppress,GEN,$@)$(call sh_copy_all,$(src),$(lastword $|)/tmp)
	$(quiet)$(call sh_touch,$@)

# associate generated directory '$(g_dir)/dst' with timestamp file '$(g_dir)/stamp1.txt'
$(call assoc_dirs,$(g_dir)/stamp1.txt,$(g_dir)/dst)

# remember files that should be copied in the target-specific variable
$(call o_path,$(g_dir)/stamp2.txt $(g_dir)/stamp3.txt $(g_dir)/stamp4.txt): files := $(call wildcard_fn,$(src))

# to be able to use 'wildcard_fn' in a rule, define it as target-specific
$(call o_path,$(g_dir)/stamp2.txt $(g_dir)/stamp3.txt $(g_dir)/stamp4.txt): $(call define_target_specific,wildcard_fn)

# ------- check1 & copy2

# to build target '$(g_dir)/stamp2.txt', directory '$(g_dir)/dst' must be generated prior the target
# create target-specific variable 'tmp' - absolute path to generated directory with copied files
$(call o_path,$(g_dir)/stamp2.txt): tmp := $(call need_built_dirs_d,$(g_dir)/stamp2.txt,$(g_dir)/dst)/tmp

# check that files were copied properly
# note: define target-specific variable 'not_copied' for the target just before executing its rule
$(call add_generated_o,$(g_dir)/stamp2.txt):
	$(eval $$@:not_copied := $$(filter-out $$(call wildcard_fn,$$(tmp)),$$(files)))$(if \
  $(not_copied),$(error these files were not copied: $(not_copied)))$(call suppress,GEN,$@)$(call sh_copy_all,$(src),$(tmp))
	$(quiet)$(call sh_touch,$@)

# re-associate generated directory '$(g_dir)/dst' with timestamp file '$(g_dir)/stamp2.txt'
$(call reassoc_dirs,$(g_dir)/stamp2.txt,$(g_dir)/dst)

# ------- check2 & copy3

# to build target '$(g_dir)/stamp3.txt', directory '$(g_dir)/dst' must be generated prior the target
# create target-specific variable 'tmp' - absolute path to generated directory with copied files
$(call o_path,$(g_dir)/stamp3.txt): tmp := $(call need_built_dirs_d,$(g_dir)/stamp3.txt,$(g_dir)/dst)/tmp

# check that files were copied properly over
# note: define target-specific variable 'not_copied' for the target just before executing its rule
$(call add_generated_o,$(g_dir)/stamp3.txt):
	$(eval $$@:not_copied := $$(filter-out $$(call wildcard_fn,$$(tmp)),$$(files) test_files $$(addprefix test_files/,$$(files))))$(if \
  $(not_copied),$(error these files were not copied: $(not_copied)))$(call suppress,GEN,$@)$(call sh_copy_all,$(src),$(tmp))
	$(quiet)$(call sh_touch,$@)

# re-associate generated directory '$(g_dir)/dst' with timestamp file '$(g_dir)/stamp3.txt'
$(call reassoc_dirs,$(g_dir)/stamp3.txt,$(g_dir)/dst)

# ------- check3

# to build target '$(g_dir)/stamp4.txt', directory '$(g_dir)/dst' must be generated prior the target
# create target-specific variable 'tmp' - absolute path to generated directory with copied files
$(call o_path,$(g_dir)/stamp4.txt): tmp := $(call need_built_dirs_d,$(g_dir)/stamp4.txt,$(g_dir)/dst)/tmp

# check that files were copied properly over
# note: define target-specific variable 'more_copied' for the target just before executing its rule
$(call add_generated_o,$(g_dir)/stamp4.txt):
	$(eval $$@:more_copied := $$(filter-out $$(files) test_files $$(addprefix test_files/,$$(files)),$$(call wildcard_fn,$$(tmp))))$(if \
  $(more_copied),$(error these files should not be copied: $(more_copied)))$(call suppress,GEN,$@)$(call sh_touch,$@)

# just delete whole 'g_dir' directory with generated files on cleanup
$(foreach t,$(g_dir)/stamp1.txt $(g_dir)/stamp2.txt $(g_dir)/stamp3.txt $(g_dir)/stamp4.txt,$(call toclean,$t,$(g_dir)))

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
