#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG is set, define conf/unconf goals

# do not inherit CONFIG from environment - if needed,
# CONFIG may be specified before including this file via:
# override CONFIG = $(BUILD)/conf.mk
CONFIG:=

ifdef CONFIG

# CONFIG variable should be simple
override CONFIG := $(abspath $(CONFIG))

# save $(CONFIG) in target-specific variable CF
# - to be safe if CONFIG get overridden
conf unconf: override CF := $(CONFIG)

ifneq (,$(filter conf,$(MAKECMDGOALS)))

ifneq (,$(filter unconf,$(MAKECMDGOALS)))
$(error conf and unconf goals cannot be specified at the same time)
endif

# use of environment variables is discouraged,
# override variable only if it's not specified in command-line
# $v - variable name
define OVERRIDE_VAR_TEMPLATE

ifneq (command line,$$(origin $v))
override define $v
$(value $v)
$(endef)
$(if $(filter simple,$(flavor $v)),override $v:=$$(value $v))
endif
endef

# generated $(CONFIG) file is likely already sourced,
# 1) override variables in $(CONFIG) file with values specified in command line,
# 2) save new variables specified in command line to $(CONFIG) file
# 3) always save PATH value to $(CONFIG) file
# note: save variables current values in target-specific variable CONFIG_TEXT - variables may be overridden later
# note: do not override GNUMAKEFLAGS, CLEAN_BUILD_VERSION, CONFIG and $(dump_max) variables by including $(CONFIG) file
conf: override CONFIG_TEXT := $(foreach v,$(filter-out \
  PATH GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG $(dump_max),$(.VARIABLES)),$(if \
  $(findstring "command line","$(origin $v)")$(findstring "override","$(origin \
  $v)"),$(OVERRIDE_VAR_TEMPLATE)))$(foreach v,PATH,$(OVERRIDE_VAR_TEMPLATE))

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/defs.mk
# note: WRITE - defined in $(OSDIR)/$(OS)/tools.mk
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
$(call CLEAN_BUILD_PROTECT_VARS,CONFIG)
