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
# note: here 'touch_files' - arbitrary directory name, should be unique to avoid names collision
# note: 'g_dir' - "local" variable - will be reset just before second "rule execution" make phase
g_dir := gen/touch_files

# define 'files' variable
include $(a_dir)/files.mk

# tag file - simple path relative to virtual $(out_dir)
# note: 't' - "local" variable - it will be reset just before second "rule execution" make phase
t := $(g_dir)/touched1.txt

# 'r' - real tag file - absolute paths
# 'f' - real generated files - absolute paths
# note: 'r' and 'f' - "local" variables - they will be reset just before second "rule execution" make phase
r := $(call o_path,$t)
f := $(addprefix $(call o_dir,$t)/,$(files))

# 'all' goal will fail if any of $r or $f files were not created by the touch.mk
all: $r $f

# check that creation date of files $f is not older than tag file $r
ifeq (2,$(test_phase))
$f: $r
	$(error file $@ must not be older than $<)
endif

# this macro must be expanded at end of target makefile, as required by 'cb_prepare' expanded at head
$(define_targets)
