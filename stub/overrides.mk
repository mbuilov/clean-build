#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# original file: $(CBBS_ROOT)/stub/overrides.mk
# description:   core clean-build definitions,
#                processing of the CBBS_CONFIG and OVERRIDES variables,
#                check that the CBBS_ROOT variable is defined

# Note: This file should be copied AS IS to the directory of the project build system
# Note: This file should be included at the end of project configuration makefile (e.g. 'project.mk')

# CBBS_CONFIG - path to the clean-build generated configuration makefile (while completing predefined 'config' goal)
#
# Note: generated $(CBBS_CONFIG) makefile will remember values of the command-line and environment variables at the
#  moment of generation; by sourcing $(CBBS_CONFIG) makefile below, these variables will be restored, and only new
#  variables defined in the command-line may override restored ones.
#
# Note: by completing predefined 'distclean' goal, $(CBBS_BUILD) directory will be deleted possibly together with the
#  $(CBBS_CONFIG) file, which is by default generated under the $(CBBS_BUILD)
#
# Note: define CBBS_CONFIG as recursive variable - for the case if CBBS_BUILD is redefined in the included next
#  $(OVERRIDES) makefile
CBBS_CONFIG ?= $(CBBS_BUILD)/config.mk

# process a file with the overrides of the project defaults set in the project configuration makefile
OVERRIDES ?=

# redefine OVERRIDES as a simple (i.e. non-recursive) variable
OVERRIDES := $(OVERRIDES)

# override variables (e.g. CBBS_BUILD, PRODUCT_VERSION, etc.) defined in the project configuration makefile by the
#  definitions in the $(OVERRIDES) makefile
ifdef OVERRIDES
ifeq (,$(wildcard $(OVERRIDES)))
$(error file does not exist: $(OVERRIDES))
endif
include $(OVERRIDES)
endif

# source optional clean-build generated configuration makefile, if it exist
-include $(CBBS_CONFIG)

# CBBS_ROOT - path to the clean-build build system
# Note: normally CBBS_ROOT is defined in the command line, but may be taken from the environment or specified in
#  the optional $(OVERRIDES) makefile
CBBS_ROOT ?=

# redefine CBBS_ROOT as a simple (i.e. non-recursive) variable
CBBS_ROOT := $(CBBS_ROOT)

# path to the clean-build must be defined
ifndef CBBS_ROOT
$(error CBBS_ROOT - path to clean-build (https://github.com/mbuilov/clean-build) is not defined,\
 example: CBBS_ROOT=/usr/local/clean-build or CBBS_ROOT=C:\User\clean-build)
endif

# source clean-build base definitions
ifeq (,$(wildcard $(CBBS_ROOT)/core/_defs.mk))
$(error clean-build files are not found under CBBS_ROOT=$(CBBS_ROOT))
endif
include $(CBBS_ROOT)/core/_defs.mk
