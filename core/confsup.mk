#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG is set, define 'conf' goal

# note: CONFIG may be specified either in command line
#  or in project configuration makefile before including this file, for example:
# CONFIG = $(BUILD)/conf.mk
CONFIG:=

# helper to remember autoconfigured variables in generated config file
CONFIG_REMEMBER_VARS:=

ifdef CONFIG

# CONFIG variable should be simple
override CONFIG := $(abspath $(CONFIG))

ifneq (,$(filter conf,$(MAKECMDGOALS)))

# save $(CONFIG) in target-specific variable CF
# - to be safe if CONFIG variable get overridden
conf: override CF := $(CONFIG)

# conf - is not a file
.PHONY: conf

# generate text of $(CONFIG) file so that by including it any variable specified there
# will be restored with saved value, except for variables specified in command line
# $v - variable name
define CONFIG_OVERRIDE_VAR_TEMPLATE

ifneq (command line,$$(origin $v))
$(keyword_define) $v
$(value $v)
$(keyword_endef)$(if $(findstring simple,$(flavor $v)),$(newline)$v:=$$(value $v))
endif
endef

# generated $(CONFIG) file is likely already sourced,
# 1) override variables in $(CONFIG) file with new values specified in command line,
# 2) save new variables specified in command line to $(CONFIG) file
# 3) always save values of PATH, SHELL and variables from $(PASS_ENV_VARS) to $(CONFIG) file because they are taken from the environment
# note: save current values of variables to the target-specific variable CONFIG_TEXT - variables may be overridden later
# note: never override GNUMAKEFLAGS, CLEAN_BUILD_VERSION, CONFIG and $(dump_max) variables by including $(CONFIG) file
conf: override CONFIG_TEXT := $(foreach v,PATH SHELL $(PASS_ENV_VARS) $(foreach v,$(filter-out \
  PATH SHELL $(PASS_ENV_VARS) GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG $(dump_max),$(.VARIABLES)),$(if \
  $(findstring command line,$(origin $v))$(findstring override,$(origin $v)),$v)),$(CONFIG_OVERRIDE_VAR_TEMPLATE))

# write by that number of lines at a time while generating config file
# note: with too many lines it is possible to exceed maximum command string length
CONFSUP_WRITE_BY_LINES := 10

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/core/_defs.mk
# note: WRITE_TEXT - defined in $(CLEAN_BUILD_DIR)/utils/$(UTILS).mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
# note: CONFIG_TEXT was defined above as target-specific variable
conf:| $(patsubst %/,%,$(dir $(CONFIG)))
	$(call SUP,GEN,$(CF),,1)$(call WRITE_TEXT,$(CONFIG_TEXT),$(CF),$(CONFSUP_WRITE_BY_LINES))

# if $(CONFIG) file is under $(BUILD), create config directory automatically
# else - $(CONFIG) file is outside of $(BUILD), config directory must be created manually
ifneq (,$(filter $(abspath $(BUILD))/%,$(CONFIG)))
CB_NEEDED_DIRS += $(patsubst %/,%,$(dir $(CONFIG)))
else
$(patsubst %/,%,$(dir $(CONFIG))):
	$(error config file directory '$@' does not exist, it is not under '$(BUILD)', so should be created manually)
endif

# helper to remember autoconfigured variables in generated config file
CONFIG_REMEMBER_VARS = $(eval conf: override CONFIG_TEXT += $(foreach v,$1,$(CONFIG_OVERRIDE_VAR_TEMPLATE)))

endif # conf
endif # CONFIG

# protect variables from modification in target makefiles
# note: TARGET_MAKEFILE variable is used here temporary and will be redefined later
TARGET_MAKEFILE += $(call SET_GLOBAL,CONFIG CONFIG_REMEMBER_VARS CONFIG_OVERRIDE_VAR_TEMPLATE CONFSUP_WRITE_BY_LINES)
