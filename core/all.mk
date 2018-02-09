#----------------------------------------------------------------------------------
# clean-build - non-recursive cross-platform build system based on GNU Make
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

# define rules for creating needed directories
# note: to avoid races when creating directories, create parent directories before child sub-directories,
#  for example, if need to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel
# note: assume all directories are created under the $(cb_build) directory
cb_needed_dirs := $(call split_dirs,$(cb_needed_dirs:$(dir $(cb_build))%=%))

# define order-only dependencies for the directories
$(eval $(call mk_dir_deps,$(cb_needed_dirs),$(dir $(cb_build))))

# define rules for creating $(cb_build)-relative directories
# note: 'create_dir' macro is defined in the included before $(utils_mk) makefile
$(addprefix $(dir $(cb_build)),$(cb_needed_dirs)):
	$(call suppress,MKDIR,$@)$(call create_dir,$@)

# note: $(cb_target_makefiles) - absolute paths of all processed target makefiles
#  (without suffix, if real makefile names are used - make always wants to recreate makefiles, even for the 'clean' goal)
# note: <TARGET_MAKEFILES_COUNT> - number of target makefiles - used to compute percent of executed makefiles
ifdef cb_add_shown_percents
$(eval cb_add_shown_percents = $(subst \
  <TARGET_MAKEFILES_COUNT>,$(words $(cb_target_makefiles)),$(subst \
  <TARGET_MAKEFILES_COUNT1>,$(words $(cb_target_makefiles) 1),$(value cb_add_shown_percents))))
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
