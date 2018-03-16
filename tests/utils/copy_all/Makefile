$(info ================ copy_all =================)

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
# note: here 'copied' - arbitrary directory name, should be unique to avoid names collision
# note: 'g_dir' variable will be reset just before second "rule execution" make phase
g_dir := $(gen_dir)/copied

# create target-specific variable 'src' - absolute path to the source files directory
$(g_dir)/stamp1.txt $(g_dir)/stamp2.txt: src := $(call fixpath,test_files)

# will copy files from 'src' directory to the generated one - it should be created by the clean-build
# here $| - automatic variable - list of order-only dependencies, dependency added in rule definition will be the first in list
$(call add_generated_r,$(g_dir)/stamp1.txt):| $(call need_gen_dirs_r,$(g_dir)/dst)
	$(call suppress,GEN,$@)$(call copy_all,$(src),$(firstword $|))
	$(quiet)$(call touch_files,$@)

# create target-specific variable 'dst' - absolute path to the directory with copied files
$(g_dir)/stamp2.txt: dst := $(g_dir)/dst

# stamp2.txt will be generated only after stamp1.txt, but stamp1.txt is generated after coping files
#  - check that files were copied properly
# note: define target-specific variable 'not_copied' for the target $(g_dir)/stamp2.txt just before executing its rule
$(call add_generated_r,$(g_dir)/stamp2.txt):| $(g_dir)/stamp1.txt
	$(eval $$@:not_copied := $$(filter-out $$(patsubst $$(dst)/%,%,$$(wildcard \
  $$(dst)/*) $$(wildcard \
  $$(dst)/*/*) $$(wildcard \
  $$(dst)/*/*/*) $$(wildcard \
  $$(dst)/*/*/*/*) $$(wildcard \
  $$(dst)/*/*/*/*/*) $$(wildcard \
  $$(dst)/*/*/*/*/*/*)),\
  1 y y2 \
  y/2 y/z y2/nn \
  y/z/3 y/z/k \
  y/z/k/4 y/z/k/m \
  y/z/k/m/5 y/z/k/m/n \
  y/z/k/m/n/6))$(if \
  $(not_copied),$(error these files were not copied: $(not_copied)))$(call suppress,GEN,$@)$(call touch_files,$@)

# just delete whole 'g_dir' directory with generated files on cleanup
$(call toclean,$(g_dir))

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
