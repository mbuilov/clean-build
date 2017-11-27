#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# core clean-build definitions, processing of CONFIG and OVERRIDES variables, MTOP variable definition
# Note: should be included at end of project configuration makefile, just before optional autoconfigure includes

# if CONFIG variable is not defined in project configuration makefile, provide default definition
ifeq (,$(filter-out undefined environment,$(origin CONFIG)))

# CONFIG - name of clean-build generated config file (while completing predefined 'conf' goal)
#
# Note: generated $(CONFIG) file will remember values of command-line or overridden variables;
#  by sourcing $(CONFIG) file below, these variables are will be restored,
#  and only new command-line defined values may override restored ones
#
# Note: by completing predefined 'distclean' goal, $(BUILD) directory will be deleted
#  - together with $(CONFIG) file, if it was generated under the $(BUILD)
#
# Note: define CONFIG as recursive variable
#  - for the case when BUILD is redefined in included next $(OVERRIDES) makefile
CONFIG = $(BUILD)/conf.mk

endif # !CONFIG

# process a file with overrides of project defaults (set in project.mk - project configuration makefile)
# Note: OVERRIDES variable may be specified in command line - to override this empty definition
# Note: OVERRIDES variable may also be defined in project configuration makefile,
#  e.g. by taking it from the environment: OVERRIDES := $(OVERRIDES)
ifeq (,$(filter-out undefined environment,$(origin OVERRIDES)))
OVERRIDES:=
endif

ifdef OVERRIDES
ifeq (,$(wildcard $(OVERRIDES)))
$(error file does not exist: $(OVERRIDES))
endif
include $(OVERRIDES)
endif

# source optional clean-build generated config file, if it exist
-include $(CONFIG)

# MTOP - path to the clean-build build system
# Note: normally MTOP is defined in command line, but may be taken from the environment
# ensure MTOP is a simple (i.e. non-recursive) variable
MTOP := $(MTOP)

# path to clean-build root directory must be defined
ifndef MTOP
$(error MTOP - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: MTOP=/usr/local/clean-build or MTOP=C:\User\clean-build)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(MTOP)/core/defs.mk))
$(error clean-build files are not found under MTOP=$(MTOP))
endif
include $(MTOP)/defs.mk
