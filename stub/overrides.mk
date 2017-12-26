#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the CBLD_CONFIG and CBLD_OVERRIDES variables,
#                checking that the CBLD_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at end of the project configuration makefile (e.g. 'project.mk')

# CBLD_CONFIG - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
# Note: generated $(CBLD_CONFIG) makefile will remember values of vital environment and command-line variables at the
#  moment of generation; by sourcing this makefile below, these variables will be restored, and only new values
#  specified in the command line may override restored ones.
# Note: CBLD_CONFIG may be defined as a macro, for example:
#  CBLD_CONFIG=/tmp/configs/$(notdir $(top)).mk
CBLD_CONFIG ?= $(CBLD_BUILD)/config.mk

# source optional clean-build generated configuration makefile, if it exist
ifneq (,$(wildcard $(CBLD_CONFIG)))
include $(CBLD_CONFIG)
else # !CBLD_CONFIG

# else process optional makefile with the overrides of the project defaults set in the project configuration makefile
#  - override variables like compiler flags, etc. by the definitions in the $(CBLD_OVERRIDES) makefile
# Note: CBLD_OVERRIDES may be defined as a macro, for example:
#  CBLD_OVERRIDES=/overrides/$(notdir $(top)).mk
# Note: variable 'CBLD_OVERRIDES' is not used by the core clean-build makefiles
CBLD_OVERRIDES ?=

ifneq (,$(CBLD_OVERRIDES))
ifeq (,$(wildcard $(CBLD_OVERRIDES)))
$(error file does not exist: $(CBLD_OVERRIDES))
endif
include $(CBLD_OVERRIDES)
endif

endif # !CBLD_CONFIG

# CBLD_ROOT - path to the clean-build build system
# Note: normally CBLD_ROOT is defined in the command line, but may be taken from the environment or specified in the
#  optional $(CBLD_OVERRIDES) makefile
# Note: variable 'CBLD_ROOT' is not used by the core clean-build makefiles
ifndef CBLD_ROOT
$(error CBLD_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBLD_ROOT=/usr/local/clean-build or CBLD_ROOT=C:\User\clean-build)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(CBLD_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBLD_ROOT=$(CBLD_ROOT))
endif
include $(CBLD_ROOT)/core/_defs.mk

# save CBLD_ROOT value in the generated configuration makefile $(CBLD_CONFIG) - for the case if CBLD_ROOT is defined
#  in the environment (command-line and file-defined variables are saved automatically)
$(call config_remember_vars,CBLD_ROOT)
