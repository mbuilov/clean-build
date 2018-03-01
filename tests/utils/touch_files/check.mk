# first test phase:  check that touch.mk has created files
# second test phase: check that touch.mk has updated files creation date - they are not older than touched1.txt created on first phase
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

# 'all' goal will fail if any of $(files) or $(g_dir)/touched1.txt files was not created by the touch.mk
all: $(files) $(g_dir)/touched1.txt

# check that creation date of $(files) is not older than $(g_dir)/touched1.txt
ifeq (2,$(test_phase))
$(files): $(g_dir)/touched1.txt
	$(error file $@ must not be older than $<)
endif

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
