#----------------------------------------------------------------------------------
# clean-build - non-recursive build system based on GNU Make
# Copyright (C) 2015-2017 Michael M. Builov, https://github.com/mbuilov/clean-build
# Licensed under GPL version 2 or any later version, see COPYING
#----------------------------------------------------------------------------------

# this file included by $(MTOP)/defs.mk

# check values of $(TOP) and $(BUILD) variables
# $1 (TOP or BUILD) must contain unix-style path to directory without spaces, like C:/opt/project or /home/oper/project
CHECK_TOP = $(if \
  $($1),,$(error \
 $1=$($1), must have non-empty value))$(if \
  $(word 2,x$($1)x),$(error \
 $1=$($1), path with spaces is not allowed))$(if \
  $(word 2,$(subst \, ,x$($1)x)),$(error \
 $1=$($1), path must use unix-style slashes: /))$(if \
  $(word 2,$(subst //, ,x$($1)/x)),$(error \
 $1=$($1), path must not end with slash: / or contain double-slash: //))

ifndef TOP
$(error TOP undefined, example: C:/opt/project,/home/oper/project)
endif

# to allow building multiple projects in the same environment,
# TOP should be defined in command line or project configuration file, rather than in environment
ifeq ("environment","$(origin TOP)")
$(error TOP should not be taken from environment)
endif

$(call CHECK_TOP,TOP)

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), $(GEN_DIR)
ifndef BUILD
BUILD := $(TOP)/build
else

# to allow building multiple projects in the same environment,
# BUILD should be defined in command line or project configuration file, rather than in environment
ifeq ("environment","$(origin BUILD)")
$(error BUILD should not be taken from environment)
endif

$(call CHECK_TOP,BUILD)

ifneq ($(filter $(BUILD)/%,$(TOP)/),)
$(error BUILD=$(BUILD) cannot be a base for TOP=$(TOP))
endif

endif # BUILD

# protect variables from modification in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CHECK_TOP TOP BUILD)
