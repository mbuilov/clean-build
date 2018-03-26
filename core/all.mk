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
# note: 'cb_needed_dirs' list contains $(cb_build)-relative simple paths, like:
#  $(target_triplet)/m $(target_triplet)/$(priv_prefix)/a $(cb_tools_subdir)/n $(cb_tools_subdir)/$(priv_prefix)/b and so on
cb_needed_dirs := $(sort $(cb_needed_dirs))

ifdef cb_checking

# check that 'cb_needed_dirs' list do not contains any of $(cb_assoc_dirs) or $(cb_assoc_dirs_t) or their child sub-directories,
#  except directories built in private namespaces of associated tag files
# note: 'cb_assoc_dirs' and 'cb_assoc_dirs_t' lists contain simple relative paths like 1/2/3 without duplicates

ifdef priv_prefix

# example:
# (built)    pp/tt/a/b/c@-/tt/1/2/3
# (deployed) tt/1/2"/3"             -> pp/tt/a/b/c@-/tt/1/2/3
# (linked)   pp/tt/z/x@-/tt/1/2"/3" -> pp/tt/a/b/c@-/tt/1/2/3
# (built)    pp/ts/d/e/@-/ts/4/5
# (deployed) ts/4"/5"               -> pp/ts/d/e/@-/ts/4/5
# (linked)   pp/ts/a/s/d@-/ts/4"/5" -> pp/ts/d/e/@-/ts/4/5
# (linked)   pp/tt/7/8/9@-/ts/4"/5" -> ts/4"/5"

# list of associated directories that _must_ be created - in private namespaces of associated tag files
# note: this list contains no duplicates, e.g.: tt/pp/a/b/c@-/1/2/3 ts/pp/d/e/@-/4/5
cb_needed_accoc_dirs = $(join \
  $(patsubst %,$(target_triplet)/$(priv_prefix)/%/,$(call cb_trg_priv,$(foreach d,$(cb_assoc_dirs),$($d.^d)))),$(cb_assoc_dirs)) $(join \
  $(patsubst %,$(cb_tools_subdir)/$(priv_prefix)/%/,$(call cb_trg_priv,$(foreach d,$(cb_assoc_dirs_t),$($d/.^d)))),$(cb_assoc_dirs_t))

# all associated directories must be in 'cb_needed_dirs' list
ifneq ($(cb_needed_accoc_dirs),$(filter $(cb_needed_dirs),$(cb_needed_accoc_dirs)))
$(error these associated directories were not added to the list of auto-created ones: $(filter-out \
  $(filter $(cb_needed_dirs),$(cb_needed_accoc_dirs)),$(cb_needed_accoc_dirs)))
endif

# next will check that $(cb_needed_dirs_ck) list of directories do not conflicts with $(cb_needed_accoc_dirs)
# filter-out: (built) tt/pp/a/b/c@-/1/2/3 ts/pp/d/e/@-/4/5
cb_needed_dirs_ck := $(filter-out $(cb_needed_accoc_dirs),$(cb_needed_dirs))

# check non-tool directories
# (deployed) tt/1/2"/3"          -> tt/pp/a/b/c@-/1/2/3
# (linked)   tt/pp/z/x@-/1/2"/3" -> tt/pp/a/b/c@-/1/2/3
# (linked)   tt/pp/7/8/9@-/4"/5" -> ts/4"/5"
cb_needed_dirs_ck1 := $(patsubst $(target_triplet)/%,%,$(filter $(target_triplet)/%,$(cb_needed_dirs_ck)))

# 1/2"/3" pp/z/x@-/1/2"/3" pp/7/8/9@-/4"/5" -> 1/2"/3" 1/2"/3" 4"/5"
cb_needed_dirs_ck1 := $(filter-out $(priv_prefix)/%,$(cb_needed_dirs_ck1)) $(call \
  cb_trg_unpriv,$(patsubst $(priv_prefix)/%,%,$(filter $(priv_prefix)/%,$(cb_needed_dirs_ck1))))




cb_needed_dirs_ck1 = $(call cb_trg_unpriv,$(patsubst $(priv_prefix)/%,%,$(patsubst \
  $(target_triplet)/%,%,$(filter $(target_triplet)/%,$(cb_needed_dirs_ck)))))

$(filter $(cb_assoc_dirs) $(cb_assoc_dirs:=/%),$(call cb_trg_unpriv,$(patsubst $(target_triplet)/$(priv_prefix)/%,%,$(filter $(target_triplet)/$(priv_prefix)/%,$(cb_needed_dirs_ck))))

$(filter-out \
  $(join $(addprefix $(target_triplet)/$(priv_prefix)/,$(foreach \
    d,$(cb_assoc_dirs),$(call cb_trg_priv,$($d.^d))/)),$(cb_assoc_dirs)) \
  $(join $(addprefix $(cb_tools_subdir)/$(priv_prefix)/,$(foreach \
    d,$(cb_assoc_dirs_t),$(call cb_trg_priv,$($d/.^d))/)),$(cb_assoc_dirs_t)),$(cb_needed_dirs))



cb_needed_dirs_ck := $(patsubst $(target_triplet)/%,%,$(filter $(target_triplet)/%,$(cb_needed_dirs)))
ifneq (,$(foreach d,$(cb_assoc_dirs),$(foreach c,$(filter %/$d,$(cb_needed_dirs_ck)),

/build/tt/pp/1-2-3/1/2/3
/build/tt/1/2"/3"          -> /build/tt/pp/1-2-3/1/2/3
/build/tt/pp/4-5-6/1/2"/3" -> /build/tt/pp/1-2-3/1/2/3

/build/ts/pp/q-w-e/q/w/e
/build/ts/q/w"/e"          -> /build/ts/pp/q-w-e/q/w/e
/build/ts/pp/a-s-d/q/w"/e" -> /build/ts/pp/q-w-e/q/w/e
/build/tt/pp/7-8-9/q/w"/e" -> /build/ts/q/w"/e"


ifneq (,$(filter $(cb_assoc_dirs:=/%),$(patsubst $(target_triplet)/%,%,$(filter $(target_triplet)/%,$(cb_needed_dirs)))))
$(error conflict: creating deployed or linked directories or their child sub-directories: $(filter \
  $(cb_assoc_dirs) $(cb_assoc_dirs:=/%),$(patsubst $(target_triplet)/%,%,$(filter $(target_triplet)/%,$(cb_needed_dirs)))))

cb_needed_dirs1 := $(patsubst $(target_triplet)/%,%,$(patsubst $(cb_tools_subdir)/%,%,$(filter-out \
  $(target_triplet) $(cb_tools_subdir),$(cb_needed_dirs))))

ifneq (,$(filter $(cb_assoc_dirs) $(cb_assoc_dirs_t) $(cb_assoc_dirs:=/%) $(cb_assoc_dirs_t:=/%),$(patsubst $(target_triplet)$(cb_needed_dirs)

cb_needed_dirs := $(notdir $(cb_build)) $(addprefix $(notdir $(cb_build))/,$(filter-out $(cb_build)/,$(sort $(cb_needed_dirs))))

cb_needed_dirs := $(call split_dirs,$(cb_needed_dirs:$(dir $(cb_build))%=%))

# define rules for creating needed directories (absolute paths)
# note: to avoid races when creating directories, create parent directories before child sub-directories,
#  for example, if need to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel
# note: assume all directories are created under the $(cb_build) base directory

# define order-only dependencies for the directories
$(eval $(call mk_dir_deps,$(cb_needed_dirs),$(dir $(cb_build))))

# define rules for creating $(cb_build)-relative directories
# note: 'suppress_targets_r' - defined in $(cb_dir)/core/suppress.mk
# note: 'create_dir' - defined in the included before $(utils_mk) makefile
$(call suppress_targets_r,$(addprefix $(dir $(cb_build)),$(cb_needed_dirs))):
	$(call suppress,MKDIR,$@)$(call create_dir,$@)

# fix 'cb_add_shown_percents' macro from $(cb_dir)/core/suppress.mk
# note: 'suppress_targets' - defined in $(cb_dir)/core/suppress.mk
# note: 'cb_seq' - defined in $(cb_dir)/code/seq.mk included by $(cb_dir)/core/suppress.mk
# note: <TRG_COUNT> - number of targets - used to compute build completion percent
ifdef suppress_targets
$(eval cb_add_shown_percents = $(subst <TRG_COUNT>,$(cb_seq),$(subst <TRG_COUNT1>,$(cb_seq),$(value cb_add_shown_percents))))
endif

# define rule for default goal 'all'
# note: 'all' depends on $(cb_target_makefile)- PHONY target, which is defined in $(cb_dir)/core/_defs.mk
# note: suppress the message "Nothing to be done for 'all'"
all:
	@:

# cleanup built files
# note: 'del_files_or_dirs' macro is defined in the included before $(utils_mk) makefile
clean:
	$(quiet)$(call del_files_or_dirs,$(sort $(cb_to_clean)))

# build 'all' goal to build or run tests
# note: assume rules for the 'check' and 'tests' goals are defined elsewhere
check tests: all

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
.PHONY: $(build_system_goals) $(MAKEFILE_LIST)

# at end of first phase - after all makefiles are parsed - print prepared environment variables for the rules
ifdef verbose
# note: strip-off last newline
prepared_env := $(subst $(newline)|,,$(subst $(newline)| ,$(newline),$(print_env)))
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
