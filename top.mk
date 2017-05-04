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

# project root directory, must be defined either in command line or5
TOP:=

ifndef TOP
$(error TOP undefined, example: C:/opt/project,/home/oper/project)
endif

# make TOP non-recursive (simple)
TOP := $(TOP)

$(call CHECK_TOP,TOP)

# directory for built files - base for $(BIN_DIR), $(LIB_DIR), $(OBJ_DIR), $(GEN_DIR)
BUILD := $(TOP)/build

$(call CHECK_TOP,BUILD)

ifneq ($(filter $(BUILD)/%,$(TOP)/),)
$(error BUILD=$(BUILD) cannot be a base for TOP=$(TOP))
endif

# protect variables from modification in target makefiles
$(call CLEAN_BUILD_PROTECT_VARS,CHECK_TOP TOP BUILD)
