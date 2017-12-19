#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBLD_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the 'cb_config' and 'pr_overrides' variables,
#                check that the CBLD_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at end of the project configuration makefile (e.g. 'project.mk')

# cb_config - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
# Note: generated $(cb_config) makefile will remember values of the environment and command-line variables at the
#  moment of generation; by sourcing $(cb_config) makefile below, these variables will be restored, and only new
#  values specified in the command line may override restored ones.
# Note: by completing predefined 'distclean' goal, $(cb_build) directory will be deleted, possibly together with the
#  $(cb_config) makefile, which is by default generated under the $(cb_build)
# Note: define 'cb_config' as recursive variable - for the case if cb_build is redefined in the included next
#  $(pr_overrides) makefile
cb_config = $(cb_build)/config.mk

# process a file with the overrides of the project defaults set in the project configuration makefile -
#  override variables like 'cb_build', compiler flags, etc. by the definitions in the $(pr_overrides) makefile
# Note: by default, assume there is no $(pr_overrides) makefile
pr_overrides:=

# Note: 'pr_overrides' variable may be defined in the command-line, for example:
#  make -f my_project.mk pr_overrides=my_overrides.mk
ifdef pr_overrides
ifeq (,$(wildcard $(pr_overrides)))
$(error file does not exist: $(pr_overrides))
endif
# command-line variables are exported by default, do not pollute environment variables namespace of sub-processes
unexport pr_overrides
include $(pr_overrides)
endif

# source optional clean-build generated configuration makefile, if it exist
-include $(cb_config)

# CBLD_ROOT - path to the clean-build build system
# Note: normally CBLD_ROOT is defined in the command line, but may be taken from the environment or specified in
#  the optional $(pr_overrides) makefile
ifndef CBLD_ROOT
$(error CBLD_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBLD_ROOT=/usr/local/clean-build or CBLD_ROOT=C:\User\clean-build)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(CBLD_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBLD_ROOT=$(CBLD_ROOT))
endif
include $(CBLD_ROOT)/core/_defs.mk
