#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the CBLD_CONFIG and PROJ_OVERRIDES variables,
#                check that the CBLD_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at end of the project configuration makefile (e.g. 'project.mk')

# CBLD_CONFIG - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
# Note: generated $(CBLD_CONFIG) makefile will remember values of vital environment and command-line variables at the
#  moment of generation; by sourcing this makefile below, these variables will be restored, and only new values
#  specified in the command line may override restored ones.
# Note: CBLD_CONFIG may be defined in the command line, e.g.:
#  make -f my_project.mk CBLD_CONFIG=/tmp/conf.mk
# Note: CBLD_CONFIG may also be defined in the environment, for example, as a macro, in bash:
#  export CBLD_CONFIG='/tmp/configs/$(notdir $(top)).mk'
CBLD_CONFIG ?= $(CBLD_BUILD)/config.mk

# process a makefile with the overrides of the project defaults set in the project configuration makefile -
#  override variables like CBLD_BUILD, CBLD_CONFIG, compiler flags, etc. by the definitions in the $(PROJ_OVERRIDES) makefile
# Note: PROJ_OVERRIDES may be defined in the command line only, e.g.:
#  make -f my_project.mk PROJ_OVERRIDES=/project_overrides.mk
# Note: PROJ_OVERRIDES may also be defined in the environment, for example, as a macro, in bash:
#  export PROJ_OVERRIDES='/overrides/$(notdir $(top)).mk'
PROJ_OVERRIDES:=

ifneq (,$(PROJ_OVERRIDES))
ifeq (,$(wildcard $(PROJ_OVERRIDES)))
$(error file does not exist: $(PROJ_OVERRIDES))
endif
include $(PROJ_OVERRIDES)
endif

# source optional clean-build generated configuration makefile, if it exist
-include $(CBLD_CONFIG)

# CBLD_ROOT - path to the clean-build build system
# Note: normally CBLD_ROOT is defined in the command line, but may be taken from the environment or specified in
#  the optional $(PROJ_OVERRIDES) makefile
ifndef CBLD_ROOT
$(error CBLD_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBLD_ROOT=/usr/local/clean-build or CBLD_ROOT=C:\User\clean-build)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(CBLD_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBLD_ROOT=$(CBLD_ROOT))
endif
include $(CBLD_ROOT)/core/_defs.mk
