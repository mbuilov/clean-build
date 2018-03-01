# first test phase:  touch non-existing files -> create them, touched1.txt should be created the last
# second test phase: touch existing files     -> update their creation date, create touched2.txt
ifneq (command line,$(origin test_phase))
test_phase := 1
endif

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
# note: here 'touch_files' - arbitrary directory name, should be unique to avoid names collision
# note: 'g_dir' variable will be reset just before second "rule execution" make phase
g_dir := $(gen_dir)/touch_files

# define 'files' variable
include $(a_dir)/files.mk

# define target-specific variable 'files' for use in next rule
$(g_dir)/touched$(test_phase).txt: files := $(files)

# note: create 'touched$(test_phase).txt' file _after_ $(files) - next we will update them and check that they are not
#  older than 'touched$(test_phase).txt'
$(call add_generated_ret,$(g_dir)/touched$(test_phase).txt):
	$(call suppress,TOUCH,$@)$(call touch_files,$(files))
	$(quiet)$(call touch_files,$@)

# just delete whole 'g_dir' directory on cleanup
$(call toclean,$(g_dir))

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
