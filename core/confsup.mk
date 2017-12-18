#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# by default, assume configuration makefile is not specified
# note: if project configuration makefile defines 'cb_config' variable - that definition will override this one
cb_config:=

# helper macro to remember autoconfigured variables in the generated configuration makefile
cb_config_remember_vars:=

ifneq (,$(filter config,$(MAKECMDGOALS)))

# 'cb_config' variable should be simple
override cb_config := $(abspath $(cb_config))

ifndef cb_config
$(error cb_config - name of generated configuration makefile - is not defined)
endif

# save $(cb_config) in target-specific variable cf - to be safe if cb_config variable will be overridden
config: cf := $(cb_config)

# config - is not a file, it's a goal
.PHONY: config

# generate text of $(cb_config) file so that by including it:
# 1) define and export old environment variables
# 2) undefine/unexport new environment variables
# 3) restore old command-line variables that do not conflict with a new ones
# $v - variable name

cb_env_vars:= aa bb cc

define aaa
c:$(backslash)
endef
aaa:=$(value aaa)

define eee
c:$(backslash)
endef
export eee





define cb_config_override_var_template

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
