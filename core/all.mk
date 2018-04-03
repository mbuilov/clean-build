#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make v3.81
# Copyright (C) 2015-2018 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 3 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define rule for the 'all' goal only at end of top-level makefile

# note: because of the use of target-specific variables, cannot allow building arbitrary goals - only the top ones,
#  like "all", "clean", "check" - see https://ciaranm.wordpress.com/2008/07/22/gnu-make-target-specific-variables-are-dumb
ifneq (,$(filter-out $(build_system_goals),$(MAKECMDGOALS)))
$(error Unsupported goal(s): $(filter-out $(build_system_goals),$(MAKECMDGOALS))$(newline)$(if \
,)Please select goal(s) from the list of supported ones: $(build_system_goals))
endif

# 'cb_needed_dirs' list is likely contains duplicates - remove them by sorting the list
# note: 'cb_needed_dirs' list contains $(cb_build)-relative simple paths
cb_needed_dirs := $(sort $(cb_needed_dirs))

ifdef cb_checking

# check that 'cb_needed_dirs' list does not contain any of $(cb_assoc_dirs) or $(cb_assoc_dirs_t) or their child sub-directories,
#  except directories built in private namespaces of associated tag files
# note: 'cb_assoc_dirs' and 'cb_assoc_dirs_t' lists contain simple relative paths like 1/2/3 without duplicates

ifdef cb_namespaces

# example of built files layout when using private targets namespaces:
#
# (built)    p/tt/a/b/c@-/tt/1/2/3
# (deployed) tt/1/2"/3"            -> p/tt/a/b/c@-/tt/1/2/3
# (linked)   p/tt/z/x@-/tt/1/2"/3" -> p/tt/a/b/c@-/tt/1/2/3
# (built)    p/ts/d/e/@-/ts/4/5
# (deployed) ts/4"/5"              -> p/ts/d/e/@-/ts/4/5
# (linked)   p/ts/a/s/d@-/ts/4"/5" -> p/ts/d/e/@-/ts/4/5
# (linked)   p/tt/7/8/9@-/ts/4"/5" -> ts/4"/5"
#
# where:
#  'p'  - $(cb_ns_dir)
#  'tt' - $(target_triplet)
#  'ts' - $(cb_tools_subdir)
#  '@-' - $(cb_ns_suffix)

# list of associated directories that _must_ be created - in private namespaces of associated tag files
# e.g.: 1/2/3 4/5 -> a/b/c@- d/e/@- -> p/tt/a/b/c@-/tt/ p/ts/d/e/@-/ts/ ->  p/tt/a/b/c@-/tt/1/2/3 p/ts/d/e/@-/ts/4/5
cb_needed_accoc_dirs := \
  $(join $(patsubst %,$(cb_ns_dir)/$(target_triplet)/%/$(target_triplet)/,$(call \
    cb_trg_priv,$(foreach d,$(cb_assoc_dirs),$($d.^d)))),$(cb_assoc_dirs)) \
  $(join $(patsubst %,$(cb_ns_dir)/$(cb_tools_subdir)/%/$(cb_tools_subdir)/,$(call \
    cb_trg_priv,$(foreach d,$(cb_assoc_dirs_t),$($d/.^d)))),$(cb_assoc_dirs_t))

# all associated directories must be in 'cb_needed_dirs' list
ifneq (,$(filter-out $(cb_needed_dirs),$(cb_needed_accoc_dirs)))
$(error these associated directories were not added to the list of auto-created ones: $(filter-out \
  $(cb_needed_dirs),$(cb_needed_accoc_dirs)))
endif

# next check that there are no requests to create conflicting directories, for example, for
#
# (built)    p/tt/a/b/c@-/tt/1/2/3
#
# there must be no requests to create directories such as:
#
# (built)    p/tt/n/m/q@-/tt/1/2/3
# (built)    p/tt/n/m/q@-/tt/1/2/3/4
# (deployed) tt/1/2/3
# (deployed) tt/1/2/3/4
#
cb_needed_non_assoc_dirs := $(filter-out $(cb_needed_accoc_dirs),$(cb_needed_dirs))

# check for conflicts, e.g.:
# tt/1/2/3
# tt/1/2/3/4
cb_needed_dirs_conflicts := $(filter \
  $(addprefix $(target_triplet)/,$(cb_assoc_dirs) $(cb_assoc_dirs:=/%)) \
  $(addprefix $(cb_tools_subdir)/,$(cb_assoc_dirs_t) $(cb_assoc_dirs_t:=/%)),$(sort \
  $(call cb_trg_unpriv,$(cb_needed_non_assoc_dirs))))

ifneq (,$(cb_needed_dirs_conflicts))
$(error conflict: creating directories with the same path or child sub-directories of generated directories:$(newline)$(filter \
  $(cb_needed_dirs_conflicts) $(addprefix %$(cb_ns_suffix)/,$(cb_needed_dirs_conflicts)),$(cb_needed_non_assoc_dirs))$(newline)generated \
  directories:$(newline)$(addprefix $(target_triplet)/,$(cb_assoc_dirs)) $(addprefix $(cb_tools_subdir)/,$(cb_assoc_dirs_t)))
endif

else # !cb_namespaces

# list of associated directories that _must_ be created - in private namespaces of associated tag files
# e.g.: 1/2/3 4/5 -> tt/1/2/3 ts/4/5
cb_needed_accoc_dirs := \
  $(addprefix $(target_triplet)/,$(cb_assoc_dirs)) \
  $(addprefix $(cb_tools_subdir)/,$(cb_assoc_dirs_t))

# all associated directories must be in 'cb_needed_dirs' list
ifneq (,$(filter-out $(cb_needed_dirs),$(cb_needed_accoc_dirs)))
$(error these associated directories were not added to the list of auto-created ones: $(filter-out \
  $(cb_needed_dirs),$(cb_needed_accoc_dirs)))
endif

# next check that there are no requests to create conflicting directories
cb_needed_non_assoc_dirs := $(filter-out $(cb_needed_accoc_dirs),$(cb_needed_dirs))

# check for conflicts
cb_needed_dirs_conflicts := $(filter \
  $(patsubst %,$(target_triplet)/%/%,$(cb_assoc_dirs)) \
  $(patsubst %,$(cb_tools_subdir)/%/%,$(cb_assoc_dirs_t)),$(cb_needed_non_assoc_dirs))

ifneq (,$(cb_needed_dirs_conflicts))
$(error conflict: creating child sub-directories of generated directories:$(newline)$(cb_needed_dirs_conflicts)$(newline)generated \
  directories:$(newline)$(addprefix $(target_triplet)/,$(cb_assoc_dirs)) $(addprefix $(cb_tools_subdir)/,$(cb_assoc_dirs_t)))
endif

endif # !cb_namespaces

endif # cb_checking

ifndef cleaning

# define rules for creating needed directories (absolute paths)
# note: to avoid races when creating directories, create parent directories before child sub-directories,
#  for example, if need to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel
# note: assume all directories are created under the $(cb_build) base directory

ifndef cb_needed_dirs

cb_needed_dirs := $(notdir $(cb_build))

else # !cb_needed_dirs

# note: will create at least $(cb_build) directory as it may be required by 'config' goal - see $(cb_dir)/confsup.mk
# 1/2/3 -> build build/1 build/1/2 build/1/2/3
cb_needed_dirs := $(notdir $(cb_build)) $(addprefix $(notdir $(cb_build))/,$(call split_dirs,$(cb_needed_dirs)))

# define order-only dependencies for the directories:
# build build/1 build/1/2 build/1/2/3 ->
#  /path/build/1:| /path/build
#  /path/build/1/2:| /path/build/1
#  /path/build/1/2/3:| /path/build/1/2
$(eval $(call mk_dir_deps,$(cb_needed_dirs),$(dir $(cb_build))))

endif # !cb_needed_dirs

# define rules for creating $(cb_build)-relative directories
# note: 'suppress_targets_r' - defined in $(cb_dir)/core/suppress.mk
# note: 'sh_mkdir' - defined in the included before $(utils_mk) makefile
$(call suppress_targets_r,$(addprefix $(dir $(cb_build)),$(cb_needed_dirs))):
	$(call suppress,MKDIR,$@)$(call sh_mkdir,$@)

# fix 'cb_add_shown_percents' macro from $(cb_dir)/core/suppress.mk
# note: 'cb_seq' - defined in $(cb_dir)/code/seq.mk included by $(cb_dir)/core/suppress.mk
# note: <TRG_COUNT> - number of targets - used to compute build completion percent
# note: each call to $(cb_seq) increments a counter
ifdef quiet
$(eval cb_add_shown_percents = $(subst <TRG_COUNT>,$(cb_seq),$(subst <TRG_COUNT1>,$(cb_seq),$(value cb_add_shown_percents))))
endif

# define rule for default goal 'all'
# note: 'all' depends on $(cb_target_makefile)- PHONY target, which is defined in $(cb_dir)/core/_defs.mk
# note: suppress the message "Nothing to be done for 'all'"
all:
	@:

# build 'all' goal to build or run tests
# note: assume rules for the 'check' and 'tests' goals are defined elsewhere
check tests: all

else # cleaning

# cleanup built files: 'cb_to_clean' list contains $(cb_build)-relative paths
# note: 'sh_rm_recursive' macro is defined in the included before $(utils_mk) makefile
clean:
	$(quiet)$(call sh_rm_recursive,$(addprefix $(cb_build)/,$(sort $(cb_to_clean))))

endif # cleaning

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
.PHONY: $(build_system_goals) $(MAKEFILE_LIST)

# at end of first phase - after all makefiles are parsed - print prepared environment variables for the rules
ifdef verbose
# note: strip-off last newline
prepared_env := $(subst $(newline)|,,$(subst $(newline)| ,$(newline),$(sh_print_env)))
ifdef prepared_env
$(info $(prepared_env))
endif
endif # verbose

ifndef cb_checking

# check that environment variables were not accidentally overwritten
# note: 'cb_check_env_vars' - defined in $(cb_dir)/core/protection.mk
# note: if cb_checking is defined, environment variables were already checked in 'cb_check_at_tail'
$(cb_check_env_vars)

else # cb_checking

# reset at end of makefiles parsing (the first phase):
# 1) non-protected ("local") variables defined in the last parsed target makefile
# 2) protected variables from $(cb_first_phase_vars) list
# note: 'cb_reset_first_phase' - defined in $(cb_dir)/core/protection.mk
$(cb_reset_first_phase)

endif # cb_checking
