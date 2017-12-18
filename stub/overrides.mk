#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBBS_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the 'cb_config' and 'overrides' variables,
#                check that the CBBS_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at the end of project configuration makefile (e.g. 'project.mk')

# cb_config - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
#
# Note: generated $(cb_config) makefile will remember values of the environment and command-line variables at the
#  moment of generation; by sourcing $(cb_config) makefile below, these variables will be restored, and only new
#  variables defined in the command-line may override restored ones.
#
# Note: by completing predefined 'distclean' goal, $(cb_build) directory will be deleted, possibly together with the
#  $(cb_config) file, which is by default generated under the $(cb_build)
#
# Note: define cb_config as recursive variable - for the case if cb_build is redefined in the included next
#  $(overrides) makefile
cb_config = $(cb_build)/config.mk

# process a file with the overrides of the project defaults set in the project configuration makefile -
#  override variables like cb_build, product_version, etc. by the definitions in the $(overrides) makefile
# byte default, assume there is no $(overrides) makefile, 'overrides' variable may be defined in the command-line,
#  for example: make -f my_project.mk overrides=my_overrides.mk
overrides:=

ifdef overrides
ifeq (,$(wildcard $(overrides)))
$(error file does not exist: $(overrides))
endif
unexport overrides
include $(overrides)
endif

# source optional clean-build generated configuration makefile, if it exist
-include $(cb_config)

# CBBS_ROOT - path to the clean-build build system
# Note: normally CBBS_ROOT is defined in the command line, but may be taken from the environment or specified in
#  the optional $(overrides) makefile
ifndef CBBS_ROOT
$(error CBBS_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBBS_ROOT=/usr/local/clean-build or CBBS_ROOT=C:\User\clean-build)
endif

# optimization: redefine CBBS_ROOT as a simple (i.e. non-recursive) variable
CBBS_ROOT := $(CBBS_ROOT)

# source clean-build base definitions
ifeq (,$(wildcard $(CBBS_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBBS_ROOT=$(CBBS_ROOT))
endif
include $(CBBS_ROOT)/core/_defs.mk
