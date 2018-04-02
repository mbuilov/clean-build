#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# first test phase:  touch non-existing files -> create them, touched1.txt should be created the last
# second test phase: touch existing files     -> update their creation date, create touched2.txt
ifneq (command line,$(origin test_phase))
test_phase := 1
endif

# note: do not use full project infrastructure

# absolute path to the directory of this makefile
# note: 'a_dir' - "project" variable - will be registered as "global" variable in included next core/_defs.mk
a_dir := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# the only variable required by the core clean-build files
CBLD_BUILD ?= $(a_dir)/build

# add core clean-build definitions
# note: all variables defined prior including this file are treated as "project" variables - they are will be registered
#  as global" ones (protected from changes), so 'a_dir' does not need to be redefined as target-specific variable
include $(a_dir)/../../../core/_defs.mk

# this must be expanded at head of any target makefile
# note: $(define_targets) must be expanded at tail of target makefile
$(cb_prepare)

# directory where to generate files - must be simple path relative to virtual $(out_dir)
# note: here 'touch_files' - arbitrary directory name, should be unique to avoid names collision
# note: 'g_dir' - "local" variable - will be reset just before second "rule execution" make phase
g_dir := $(gen_dir)/touch_files

# define 'files' variable
include $(a_dir)/files.mk

# tag file - simple path relative to virtual $(out_dir)
# note: 't' - "local" variable - it will be reset just before second "rule execution" make phase
t := $(g_dir)/touched$(test_phase).txt

# tag file of the first test phase
# note: 't1' - "local" variable - it will be reset just before second "rule execution" make phase
t1 := $(g_dir)/touched1.txt

# files will be touched in namespace directory of $(t1) tag file
f := $(addprefix $(call o_dir,$(t1))/,$(files))

# register output file '$t' as generated one and return absolute path to it
# note: 'r' - "local" variable - it will be reset just before second "rule execution" make phase
r := $(call add_generated_o,$t)

# define target-specific variable 'f' for use in next rule
$r: f := $f

# note: touch file 'r' _after_ files 'f' - on second phase we will update them and check that they are not older than 'r'
$(call add_generated_r,$t):
	$(call suppress,TOUCH,$@)$(call sh_touch,$f)
	$(quiet)$(call sh_touch,$@)


# 'r' - real tag file - absolute paths
# 'f' - real generated files - absolute paths
# note: 'r' and 'f' - "local" variables - they will be reset just before second "rule execution" make phase
# note: files are generated on the first phase and then touched on the second phase in the same directory of $(t1) target
r := $(call o_path,$t)
f := $(addprefix $(call o_dir,$(t1)/,$(files)))

# define target-specific variable 'f' for use in next rule
$r: f := $f

# just delete whole 'g_dir' directory with generated files on cleanup
$(call toclean,$(t1),$(g_dir))

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
