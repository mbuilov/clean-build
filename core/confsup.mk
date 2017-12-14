#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG is set, define 'config' goal

# note: CONFIG may be specified either in command line or in project configuration
#  makefile before including this file, e.g.: CONFIG=$(BUILD)/conf.mk
CONFIG:=

# helper to remember autoconfigured variables in generated configuration file
config_remember_vars:=

ifdef CONFIG

# CONFIG variable should be simple
override CONFIG := $(abspath $(CONFIG))

ifneq (,$(filter config,$(MAKECMDGOALS)))

# save $(CONFIG) in target-specific variable cf - to be safe if CONFIG variable will be overridden
config: cf := $(CONFIG)

# config - is not a file, it's a goal
.PHONY: config

# generate text of $(CONFIG) file so that by including it:
# 1) define and export old environment variables
# 2) undefine/unexport new environment variables
# 3) restore old command-line variables, if they do not conflict with a new ones
# $v - variable name
define config_override_var_template

ifneq (command line,$$(origin $v))
$(keyword_define) $v
$(value $v)
$(keyword_endef)$(if $(findstring simple,$(flavor $v)),$(newline)$v:=$$(value $v))
endif
endef

# generated $(CONFIG) file is likely already sourced,
# 1) override variables in $(CONFIG) file with new values specified in command line,
# 2) save new variables specified in command line to the $(CONFIG) file
# 3) always save values of PATH and SHELL to the $(CONFIG) file because they are taken from the environment
# note: save current values of variables to the target-specific variable config_text - variables may be overridden later
# note: never override GNUMAKEFLAGS, CLEAN_BUILD_VERSION, CONFIG and $(dump_max) variables by including $(CONFIG) file
conf: config_text := $(foreach v,PATH SHELL $(PASS_ENV_VARS) $(foreach v,$(filter-out \
  PATH SHELL $(PASS_ENV_VARS) GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG $(dump_max),$(.VARIABLES)),$(if \
  $(findstring command line,$(origin $v))$(findstring override,$(origin $v)),$v)),$(config_override_var_template))

# write by that number of lines at a time while generating config file
# note: with too many lines it is possible to exceed maximum command string length
CONFSUP_WRITE_BY_LINES := 10

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/core/_defs.mk
# note: WRITE_TEXT - defined in $(CLEAN_BUILD_DIR)/utils/$(UTILS).mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
# note: config_text was defined above as target-specific variable
conf: F.^ := $(abspath $(firstword $(MAKEFILE_LIST)))
conf: C.^ :=
conf:| $(patsubst %/,%,$(dir $(CONFIG)))
	$(call SUP,GEN,$(cf),,1)$(call WRITE_TEXT,$(config_text),$(cf),$(CONFSUP_WRITE_BY_LINES))

# if $(CONFIG) file is under $(BUILD), create config directory automatically
# else - $(CONFIG) file is outside of $(BUILD), config directory must be created manually
ifneq (,$(filter $(abspath $(BUILD))/%,$(CONFIG)))
CB_NEEDED_DIRS += $(patsubst %/,%,$(dir $(CONFIG)))
else
$(patsubst %/,%,$(dir $(CONFIG))):
	$(error config file directory '$@' does not exist, it is not under '$(BUILD)', so should be created manually)
endif

# helper to remember autoconfigured variables in generated config file
config_remember_vars = $(eval conf: config_text += $(foreach v,$1,$(config_override_var_template)))

endif # conf
endif # CONFIG

# protect variables from modification in target makefiles
# note: TARGET_MAKEFILE variable is used here temporary and will be redefined later
TARGET_MAKEFILE += $(call SET_GLOBAL,CONFIG config_remember_vars config_override_var_template CONFSUP_WRITE_BY_LINES)
