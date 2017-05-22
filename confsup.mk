#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG_FILE is set, define conf/unconf goals

# do not inherit CONFIG_FILE from environment - if needed,
# CONFIG_FILE may be specified before including this file via:
# override CONFIG_FILE = $(BUILD)/conf.mk
CONFIG_FILE:=

ifdef CONFIG_FILE

# CONFIG_FILE variable should be simple
override CONFIG_FILE := $(abspath $(CONFIG_FILE))

# save $(CONFIG_FILE) in target-specific variable CF
# - to be safe if CONFIG_FILE get overridden
conf unconf: override CF := $(CONFIG_FILE)

ifneq (,$(filter conf,$(MAKECMDGOALS)))

ifneq (,$(filter unconf,$(MAKECMDGOALS)))
$(error conf and unconf goals cannot be specified at the same time)
endif

# use of environment variables is discouraged,
# override variable only if it's not specified in command-line
# $v - variable name
define OVERRIDE_VAR_TEMPLATE

ifneq ("command line","$$(origin $v)")
override define $v
$(value $v)
$(endef)
$(if $(filter simple,$(flavor $v)),override $v:=$$(value $v))
endif
endef

# generated $(CONFIG_FILE) is likely already sourced,
# 1) override variables in $(CONFIG_FILE) with values specified in command line,
# 2) save new variables specified in command line to $(CONFIG_FILE)
# note: save variables current values in target-specific variable CONFIG_FILE_TEXT - variables may be overridden later
# note: don't override GNUMAKEFLAGS, CLEAN_BUILD_VERSION, CONFIG_FILE and $(dump_max) variables by including $(CONFIG_FILE)
conf: override CONFIG_FILE_TEXT := $(foreach v,$(filter-out \
  GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG_FILE $(dump_max),$(.VARIABLES)),$(if \
  $(findstring "command line","$(origin $v)")$(findstring "override","$(origin $v)"),$(OVERRIDE_VAR_TEMPLATE)))

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/defs.mk
# note: WRITE - defined in $(OSDIR)/$(OS)/tools.mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
# note: CONFIG_FILE_TEXT is defined below
conf:| $(patsubst %/,%,$(dir $(CONFIG_FILE)))
	$(call SUP,GEN,$(CF),,1)$(call WRITE,$(CONFIG_FILE_TEXT),$(CF),10)

# if $(CONFIG_FILE) is under $(BUILD), create config directory automatically
# else - $(CONFIG_FILE) is outside of $(BUILD), config directory must be created manually
ifneq (,$(filter $(abspath $(BUILD))/%,$(CONFIG_FILE)))
NEEDED_DIRS += $(patsubst %/,%,$(dir $(CONFIG_FILE)))
else
$(patsubst %/,%,$(dir $(CONFIG_FILE))):
	$(error config file directory '$@' does not exist, it is not under '$(BUILD)', so should be created manually)
endif

else ifneq (,$(filter unconf,$(MAKECMDGOALS)))

# delete configuration file
# note: DEL - defined in $(OSDIR)/$(OS)/tools.mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
unconf:
	$(call SUP,RM,$(CF),,1)$(call DEL,$(CF))

endif # unconf

# conf/unconf - not a files
.PHONY: conf unconf

endif

# protect variables from modification in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CONFIG_FILE)
