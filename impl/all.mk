#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# define rule for 'all' target only at end of top-level makefile

# define rules to create needed directories
# note: to avoid races when creating directories, create parent directories before child sub-directories,
# for example, if needed to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel
# note: assume all directories are created in $(BUILD) directory
NEEDED_DIRS := $(call split_dirs,$(NEEDED_DIRS:$(dir $(BUILD))%=%))

# define order-only dependencies for directories
$(eval $(call mk_dir_deps,$(NEEDED_DIRS),$(dir $(BUILD))))

# define rules to create $(BUILD)-relative needed directories
# note: do not update percents of executed makefiles, so pass 1 as 4-th argument of SUP function
$(addprefix $(dir $(BUILD)),$(NEEDED_DIRS)):
	$(call SUP,MKDIR,$@,,1)$(call MKDIR,$@)

# note: $(PROCESSED_MAKEFILES) - absolute paths of all processed target makefiles with '-' suffix
#  (without suffix, if real makefile names are used - make always wants to recreate makefiles, even for the clean target)
# note: TARGET_MAKEFILES_COUNT - number of target makefiles - used to compute percents of executed makefiles
ifdef ADD_SHOWN_PERCENTS
$(eval ADD_SHOWN_PERCENTS = $(subst \
  $$(TARGET_MAKEFILES_COUNT),$(words $(PROCESSED_MAKEFILES)),$(subst \
  $$(TARGET_MAKEFILES_COUNT1),$(words $(PROCESSED_MAKEFILES) 1),$(value ADD_SHOWN_PERCENTS))))
endif

# check that target rules are defined and completed
ifdef MCHECK
$(PROCESSED_MAKEFILES):
	$(foreach f,$(filter-out $(wildcard $^),$^),$(info $(@:-=): cannot build $f))
endif

# define rule for default goal 'all'
# note: all depends on $(TARGET_MAKEFILE)- defined in $(CLEAN_BUILD_DIR)/impl/defs.mk
# note: suppress "Nothing to be done for 'all'"
all:
	@:

# cleanup built files
clean:
	$(call RM,$(CLEAN))

# build all to build or run tests
# note: assume rules for 'check' and 'tests' goals are defined elsewhere
check tests: all

# define install/uninstall targets by default
NO_CLEAN_BUILD_INSTALL_UNINSTALL_TARGETS:=

ifndef NO_CLEAN_BUILD_INSTALL_UNINSTALL_TARGETS

install:
	@$(info Successfully installed to '$(DESTDIR)$(PREFIX)')

uninstall:
	@$(info Uninstalled from '$(DESTDIR)$(PREFIX)')

endif

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
.PHONY: all clean check tests install uninstall $(MAKEFILE_LIST)
