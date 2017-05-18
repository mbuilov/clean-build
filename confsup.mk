#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# configuration file generation:
# if CONFIG_FILE is set, define conf/unconf goals

# do not inherit CONFIG_FILE from environment - if needed,
# CONFIG_FILE may be specified before including this file via:
# override CONFIG_FILE := $(TOP)/conf.mk
CONFIG_FILE:=

ifdef CONFIG_FILE

# CONFIG_FILE variable should be simple
override CONFIG_FILE := $(CONFIG_FILE)

# source old definitions, if $(CONFIG_FILE) does exist
-include $(CONFIG_FILE)

# use of environment variables is discouraged,
# override variable only if it's not specified in command-line
# $v - variable name
keyword_endef := endef
define OVERRIDE_VAR_TEMPLATE

ifneq ("command line","$$(origin $v)")
override define $v
$(value $v)
$(keyword_endef)
endif
$(if $(filter simple,$(flavor $v)),override $v:=$$(value $v))

endef

# save $(CONFIG_FILE) in target-specific variable CF
# - to be safe if CONFIG_FILE get overridden
conf unconf: override CF := $(CONFIG_FILE)

# generated $(CONFIG_FILE) may be already sourced,
# 1) override variables in $(CONFIG_FILE) with values specified in command line,
# 2) save new variables specified in command line to $(CONFIG_FILE)
# note: save variables current values in target-specific variable CONFIG_FILE_TEXT - variables may be overridden later
# note: don't override GNUMAKEFLAGS, CLEAN_BUILD_VERSION and CONFIG_FILE variables by including $(CONFIG_FILE)
conf: override CONFIG_FILE_TEXT := $(foreach v,$(filter-out GNUMAKEFLAGS CLEAN_BUILD_VERSION CONFIG_FILE,$(.VARIABLES)),$(if \
  $(findstring "command line","$(origin $v)")$(findstring "override","$(origin $v)"),$(OVERRIDE_VAR_TEMPLATE)))

# generate configuration file
# note: SUP - defined in $(CLEAN_BUILD_DIR)/defs.mk
# note: ECHO - defined in $(OSDIR)/$(OS)/tools.mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
conf:
	$(call SUP,GEN,$(CF),,1)$(call ECHO,$(CONFIG_FILE_TEXT)) > $(CF)

# delete configuration file
# note: RM - defined in $(OSDIR)/$(OS)/tools.mk
# note: pass 1 as 4-th argument of SUP function to not update percents of executed target makefiles
unconf:
	$(call SUP,RM,$(CF),,1)$(call DEL,$(CF))

# conf/unconf - not a files
.PHONY: conf unconf

endif
