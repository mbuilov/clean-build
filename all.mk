#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# really define 'all' target only at end of top-level makefile

# define rules to create needed directories
# note: to avoid races when creating directories, create parent directories before child sub-directories,
# for example, if needed to create a/b/c1 and a/b/c2 - create a/b before creating a/b/c1 and a/b/c2 in parallel
NEEDED_DIRS := $(call split_dirs,$(NEEDED_DIRS:$(BUILD)/%=%))

# define order-only dependencies for directories
$(eval $(call mk_dir_deps,$(NEEDED_DIRS),$(BUILD)/))

# define rules to create $(BUILD)-related needed directories
$(addprefix $(BUILD)/,$(NEEDED_DIRS)):
	$(call SUP1,MKDIR,$@,1,)$(call MKDIR,$@)

# default target
# note: $(PROCESSED_MAKEFILES) - $(TOP)-related names of all processed target makefiles with '-' suffix
# (otherwise, if real makefile names are used - make always wants to recreate makefiles, even before clean target)
ifdef REM_SHOWN_MAKEFILE
# TARGET_MAKEFILES_COUNT - number of target makefiles - used to compute percents of executed makefiles
# substract $(INTERMEDIATE_MAKEFILES) from $(PROCESSED_MAKEFILES)
TARGET_MAKEFILES_COUNT := $(wordlist $(words 1 $(INTERMEDIATE_MAKEFILES)),999999,$(PROCESSED_MAKEFILES))
TARGET_MAKEFILES_COUNT1 := $(words 1 $(TARGET_MAKEFILES_COUNT))
TARGET_MAKEFILES_COUNT := $(words $(TARGET_MAKEFILES_COUNT))
endif

ifdef MCHECK

# check that target rules are defined and completed
$(PROCESSED_MAKEFILES):
	$(foreach f,$(filter-out $(wildcard $^),$^),$(info $(@:-=): cannot build $f))

endif # MCHECK

all: $(PROCESSED_MAKEFILES)
	@:

# note: also evaluate and execute $(CLEAN_COMMANDS) to cleanup things
clean:
	$(call RM,$(CLEAN))$(eval CLEAN_CODE := $(CLEAN_COMMANDS))$(CLEAN_CODE)

# build all to build or run tests
check tests: all

# define install/uninstall targets by default
NO_CLEAN_BUILD_INSTALL_UNINSTALL:=

ifndef NO_CLEAN_BUILD_INSTALL_UNINSTALL

install:
	@$(call ECHO,Successfully installed to $(DESTDIR)$(PREFIX))

uninstall:
	@$(call ECHO,Uninstalled from $(DESTDIR)$(PREFIX))

endif

# note: don't try to update makefiles in $(MAKEFILE_LIST) - mark them as .PHONY targets
# note: $(PROCESSED_MAKEFILES) - names of processed makefiles with '-' suffix
.PHONY: all clean check tests install uninstall $(MAKEFILE_LIST) $(PROCESSED_MAKEFILES)

# specify default target
.DEFAULT_GOAL := all
