#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG is set, define conf goal

# note: CONFIG may be specified either in command line
#  or in project configuration makefile before including this file, for example:
# CONFIG = $(BUILD)/conf.mk
CONFIG:=

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
define OVERRIDE_VAR_TEMPLATE

ifneq (command line,$$(origin $v))
$(keyword_define) $v
$(value $v)
$(keyword_endef)$(if $(findstring simple,$(flavor $v)),$(newline)$v:=$$(value $v))
endif
endef

# generated $(CONFIG) file is likely already sourced,
# 1) override variables in $(CONFIG) file with new values specified in command line,
# 2) save new variables specified in command line to $(CONFIG) file
# 3) always save PATH, SHELL and variables named in $(PASS_ENV_VARS) values to $(CONFIG) file because they are exported
# note: save current values of variables in target-specific variable CONFIG_TEXT - variables may be overridden later
# note: never override GNUMAKEFLAGS, CLEAN_BUILD_VERSION, CONFIG and $(dump_max) variables by including $(CONFIG) file
conf: override CONFIG_TEXT := $(foreach v,$(filter-out \
  PATH SHELL $(PASS_ENV_VARS) GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG $(dump_max),$(.VARIABLES)),$(if \
  $(findstring command line,$(origin $v))$(findstring override,$(origin \
  $v)),$(OVERRIDE_VAR_TEMPLATE)))$(foreach v,PATH SHELL $(PASS_ENV_VARS),$(OVERRIDE_VAR_TEMPLATE))

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/impl/_defs.mk
# note: WRITE - defined in $(TOOLCHAINS_DIR)/utils/$(UTILS).mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
# note: CONFIG_TEXT was defined above as target-specific variable
conf:| $(patsubst %/,%,$(dir $(CONFIG)))
	$(call SUP,GEN,$(CF),,1)$(call WRITE,$(CONFIG_TEXT),$(CF),10)

# if $(CONFIG) file is under $(BUILD), create config directory automatically
# else - $(CONFIG) file is outside of $(BUILD), config directory must be created manually
ifneq (,$(filter $(abspath $(BUILD))/%,$(CONFIG)))
NEEDED_DIRS += $(patsubst %/,%,$(dir $(CONFIG)))
else
$(patsubst %/,%,$(dir $(CONFIG))):
	$(error config file directory '$@' does not exist, it is not under '$(BUILD)', so should be created manually)
endif

endif # conf
endif # CONFIG

# protect variables from modification in target makefiles
$(call SET_GLOBAL,CONFIG)
