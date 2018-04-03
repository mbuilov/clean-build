#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# first test phase:  check that touch.mk had created files
# second test phase: check that touch.mk had updated files creation date - they are not older than touched1.txt created on first phase
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
# note: here 'gen' - common directory for generated files
# note: here 'touch_files' - arbitrary directory name, should be unique to avoid names collision in the common 'gen' directory
# note: 'g_dir' - "local" variable - will be reset just before second "rule execution" make phase
g_dir := gen/touch_files

# define 'files' "local" variable
include $(a_dir)/files.mk

# get absolute path to tag file of current test phase
r := $(call o_path,$(g_dir)/touched$(test_phase).txt)

# get absolute path to tag file of the first test phase
r1 := $(call o_path,$(g_dir)/touched1.txt)

# form absolute paths to generates files - in the directory of tag file of the first test phase
f := $(addprefix $(dir $(r1)),$(files))

# 'all' goal will fail if any of '$r' or '$f' files were not created by the touch.mk
all: $r $f

# in the second test phase: check that creation date of files $f is not older than tag file of the first test phase $(r1)
# note: 'r1', 'f' - are "local" variables, they will be reset before second "rule execution" make phase, so in next rule use
#  automatic variables:
# $@ - the target - one of files $f
# $< - first prerequisite - $(r1)
ifeq (2,$(test_phase))
$f: $(r1)
	$(error file $@ must not be older than $<)
endif

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
