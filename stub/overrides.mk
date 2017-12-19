#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the CONFIG and OVERRIDES variables,
#                check that the CBLD_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at end of the project configuration makefile (e.g. 'project.mk')

# CONFIG - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
# Note: generated $(CONFIG) makefile will remember values of the environment and command-line variables at the
#  moment of generation; by sourcing $(CONFIG) makefile below, these variables will be restored, and only new
#  variables defined in the command line may override restored ones.
# Note: by completing predefined 'distclean' goal, $(BUILD) directory will be deleted, possibly together with the
#  $(CONFIG) makefile, which is by default generated under the $(BUILD)
# Note: define CONFIG as recursive variable - for the case if BUILD is redefined in the included next $(OVERRIDES)
#  makefile
CONFIG = $(BUILD)/config.mk

# process a file with the overrides of the project defaults set in the project configuration makefile -
#  override variables like BUILD, compiler flags, etc. by the definitions in the $(OVERRIDES) makefile
# Note: by default, assume there is no $(OVERRIDES) makefile
OVERRIDES:=

# Note: OVERRIDES variable may be defined in the command-line, for example:
#  make -f my_project.mk OVERRIDES=my_overrides.mk
ifdef OVERRIDES
ifeq (,$(wildcard $(OVERRIDES)))
$(error file does not exist: $(OVERRIDES))
endif
include $(OVERRIDES)
endif

# source optional clean-build generated configuration makefile, if it exist
-include $(CONFIG)

# CBLD_ROOT - path to the clean-build build system
# Note: normally CBLD_ROOT is defined in the command line, but may be taken from the environment or specified in
#  the optional $(OVERRIDES) makefile
ifndef CBLD_ROOT
$(error CBLD_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBLD_ROOT=/usr/local/clean-build or CBLD_ROOT=C:\User\clean-build)
endif

# optimization: redefine CBLD_ROOT as a simple (i.e. non-recursive) variable
ifeq (,$(findstring $$,$(value CBLD_ROOT)))
override CBLD_ROOT := $(CBLD_ROOT)
else
CBLD_ROOT := $(CBLD_ROOT)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(CBLD_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBLD_ROOT=$(CBLD_ROOT))
endif
include $(CBLD_ROOT)/core/_defs.mk
